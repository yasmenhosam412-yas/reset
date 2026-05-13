import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/entities/comment_entity.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_accepted_friends_profiles_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/post_text_with_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showHomeCommentsSheet(
  BuildContext context, {
  required PostModel post,
  required TextEditingController commentController,
}) {
  if (post.id.isEmpty) return Future.value();

  commentController.clear();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      final sheetHeight = MediaQuery.sizeOf(ctx).height * 0.52;

      return BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: sheetHeight,
            child: _HomeCommentsSheetBody(
              initialPost: post,
              commentController: commentController,
            ),
          ),
        ),
      );
    },
  );
}

PostModel _livePostFor(HomeState state, PostModel fallback) {
  final id = fallback.id.trim();
  if (id.isEmpty) return fallback;
  for (final p in state.posts) {
    if (p.id.trim() == id) return p;
  }
  for (final p in state.savedPostsOverlay) {
    if (p.id.trim() == id) return p;
  }
  return fallback;
}

void _confirmDeleteOwnComment(
  BuildContext context, {
  required PostModel post,
  required CommentEntity comment,
}) {
  final commentId = comment.id.trim();
  final postId = post.id.trim();
  if (commentId.isEmpty || postId.isEmpty) return;
  final scheme = Theme.of(context).colorScheme;
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(context.l10n.deleteCommentQuestion),
        content: Text(context.l10n.deleteCommentMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<HomeBloc>().add(
                    HomeCommentDeleteRequested(
                      postId: postId,
                      commentId: commentId,
                    ),
                  );
            },
            child: Text(context.l10n.delete),
          ),
        ],
      );
    },
  );
}

List<UserModel> _uniqueMentionUsers(PostModel post, List<UserModel> friends) {
  final byId = <String, UserModel>{};
  void add(UserModel u) {
    final id = u.id.trim().toLowerCase();
    if (id.isEmpty) return;
    byId[id] = u;
  }

  add(post.userModel);
  for (final c in post.comments) {
    add(c.userModel);
  }
  for (final f in friends) {
    add(f);
  }

  final list = byId.values.toList(growable: false);
  list.sort(
    (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
  );
  return list;
}

/// Avatar for comment / mention rows (matches feed card behavior).
Widget _userCircleAvatar(UserModel user, {required double radius}) {
  final name = user.username.trim();
  final avatarUrl = user.avatarUrl?.trim();
  final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
  return CircleAvatar(
    radius: radius,
    backgroundColor: homeFeedAvatarColor(name.isNotEmpty ? name : '?'),
    foregroundColor: Colors.white,
    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
    onBackgroundImageError: hasAvatar ? (_, _) {} : null,
    child: hasAvatar
        ? null
        : Text(
            initial,
            style: TextStyle(
              fontSize: (radius * 0.92).clamp(11, 18),
              fontWeight: FontWeight.w600,
            ),
          ),
  );
}

class _HomeCommentsSheetBody extends StatefulWidget {
  const _HomeCommentsSheetBody({
    required this.initialPost,
    required this.commentController,
  });

  final PostModel initialPost;
  final TextEditingController commentController;

  @override
  State<_HomeCommentsSheetBody> createState() => _HomeCommentsSheetBodyState();
}

class _HomeCommentsSheetBodyState extends State<_HomeCommentsSheetBody> {
  final _fieldFocus = FocusNode();
  int? _mentionAt;
  List<UserModel> _mentionChoices = const [];
  List<UserModel> _friendProfiles = const [];

  TextEditingController get _c => widget.commentController;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFriendProfiles());
  }

  Future<void> _loadFriendProfiles() async {
    final r = await getIt<GetHomeAcceptedFriendsProfilesUsecase>()();
    if (!mounted) return;
    r.fold((_) {}, (list) {
      setState(() => _friendProfiles = list);
    });
  }

  @override
  void dispose() {
    _c.removeListener(_onTextChanged);
    _fieldFocus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    final text = _c.text;
    final sel = _c.selection;

    if (!sel.isValid || sel.baseOffset != sel.extentOffset) {
      _clearMention();
      return;
    }

    final cursor = sel.start;
    if (cursor < 0 || cursor > text.length) {
      _clearMention();
      return;
    }

    final before = text.substring(0, cursor);
    final at = before.lastIndexOf('@');
    if (at < 0) {
      _clearMention();
      return;
    }

    final tail = before.substring(at + 1);
    if (tail.contains(' ') || tail.contains('\n')) {
      _clearMention();
      return;
    }

    final state = context.read<HomeBloc>().state;
    final live = _livePostFor(state, widget.initialPost);
    final all = _uniqueMentionUsers(live, _friendProfiles);
    final q = tail.toLowerCase();
    final filtered = q.isEmpty
        ? all.take(16).toList(growable: false)
        : all
              .where(
                (u) => u.username.toLowerCase().startsWith(q),
              )
              .take(16)
              .toList(growable: false);

    setState(() {
      _mentionAt = at;
      _mentionChoices = filtered;
    });
  }

  void _clearMention() {
    if (_mentionAt == null && _mentionChoices.isEmpty) return;
    setState(() {
      _mentionAt = null;
      _mentionChoices = const [];
    });
  }

  void _insertMention(UserModel user) {
    final at = _mentionAt;
    if (at == null) return;
    final text = _c.text;
    final sel = _c.selection;
    if (!sel.isValid) return;
    final end = sel.start;
    if (end < at || end > text.length) return;

    final uname = user.username.trim();
    if (uname.isEmpty) return;

    final before = text.substring(0, at);
    final after = text.substring(end);
    final insert = '@$uname ';
    final next = before + insert + after;
    final offset = (before + insert).length;

    _c.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: offset),
    );
    setState(() {
      _mentionAt = null;
      _mentionChoices = const [];
    });
    _fieldFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (prev, curr) =>
          prev.posts != curr.posts ||
          prev.savedPostsOverlay != curr.savedPostsOverlay,
      builder: (context, state) {
        final live = _livePostFor(state, widget.initialPost);
        final myUid =
            (Supabase.instance.client.auth.currentUser?.id ?? '').trim();

        void addComment() {
          final t = _c.text.trim();
          if (t.isEmpty) return;
          context.read<HomeBloc>().add(
                HomeCommentCreateRequested(
                  postId: live.id,
                  comment: t,
                ),
              );
          _c.clear();
          _clearMention();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Text(
                    l10n.comments,
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${live.comments.length}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: live.comments.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n.noCommentsYetBeFirst,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: live.comments.length,
                      separatorBuilder: (context, i) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = live.comments[i];
                        final name = c.userModel.username;
                        final canDelete = myUid.isNotEmpty &&
                            c.id.trim().isNotEmpty &&
                            c.userModel.id.trim() == myUid;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _userCircleAvatar(c.userModel, radius: 18),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: PostTextWithLinks(
                              text: c.comment,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          trailing: canDelete
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  tooltip: context.l10n.delete,
                                  onPressed: () => _confirmDeleteOwnComment(
                                    context,
                                    post: live,
                                    comment: c,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
            ),
            if (_mentionAt != null) ...[
              Material(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
                child: SizedBox(
                  height: min(140, 36.0 + _mentionChoices.length * 52.0),
                  child: _mentionChoices.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.noMentionMatches,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _mentionChoices.length,
                          itemBuilder: (context, i) {
                            final u = _mentionChoices[i];
                            final name = u.username.trim();
                            return ListTile(
                              dense: true,
                              leading: _userCircleAvatar(u, radius: 16),
                              title: Text(
                                name.isEmpty ? '…' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '@$name',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () => _insertMention(u),
                            );
                          },
                        ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      focusNode: _fieldFocus,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.writeAComment,
                        helperText: l10n.mentionUsersHint,
                        helperMaxLines: 2,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: addComment,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
