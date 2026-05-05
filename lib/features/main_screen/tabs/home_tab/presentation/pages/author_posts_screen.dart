import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_comments_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_post_card.dart';

class AuthorPostsScreen extends StatefulWidget {
  const AuthorPostsScreen({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.commentController,
    required this.onAuthorTapFromFeed,
    this.focusPostId,
    this.openCommentsAfterScroll = false,
  });

  final String authorId;
  final String authorName;
  final String? focusPostId;
  final TextEditingController commentController;
  final void Function(PostModel post) onAuthorTapFromFeed;
  final bool openCommentsAfterScroll;

  @override
  State<AuthorPostsScreen> createState() => _AuthorPostsScreenState();
}

class _AuthorPostsScreenState extends State<AuthorPostsScreen> {
  final _keys = <String, GlobalKey>{};
  bool _didScrollToFocus = false;

  String get _authorId => widget.authorId.trim();
  String get _focusId => widget.focusPostId?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<HomeBloc>().state;
      _tryScrollToFocus(_postsForAuthor(state));
    });
  }

  List<PostModel> _postsForAuthor(HomeState state) {
    final aid = _authorId.toLowerCase();
    if (aid.isEmpty) return const [];
    final list = state.posts
        .where((p) => p.userModel.id.trim().toLowerCase() == aid)
        .toList(growable: false);
    list.sort((a, b) {
      final ta = a.createdAt;
      final tb = b.createdAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return list;
  }

  void _tryScrollToFocus(List<PostModel> posts) {
    if (_didScrollToFocus || _focusId.isEmpty) return;
    final hasFocus = posts.any((p) => p.id.trim() == _focusId);
    if (!hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _keys[_focusId];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.12,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
      }
      _didScrollToFocus = true;

      if (widget.openCommentsAfterScroll && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final state = context.read<HomeBloc>().state;
          PostModel? live;
          for (final p in state.posts) {
            if (p.id.trim() == _focusId) {
              live = p;
              break;
            }
          }
          if (live != null) {
            showHomeCommentsSheet(
              context,
              post: live,
              commentController: widget.commentController,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = widget.authorName.trim().isEmpty
        ? 'Posts'
        : widget.authorName.trim();

    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (prev, curr) => prev.posts != curr.posts,
      listener: (context, state) {
        _tryScrollToFocus(_postsForAuthor(state));
      },
      builder: (context, state) {
        final posts = _postsForAuthor(state);

        return Scaffold(
          appBar: AppBar(
            title: Text(name),
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: scheme.surfaceTint,
            scrolledUnderElevation: 0.5,
          ),
          body: posts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No posts from this profile in your feed yet. Pull to refresh on Home.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<HomeBloc>().add(HomePostsRequested());
                    await context.read<HomeBloc>().stream.firstWhere(
                      (s) => s.status != HomeStatus.loading,
                    );
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: posts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final id = post.id.trim();
                      final key = _keys.putIfAbsent(id, GlobalKey.new);
                      return HomePostCard(
                        key: key,
                        post: post,
                        likedByMe: homePostLikedByCurrentUser(post),
                        onOpenComments: () => showHomeCommentsSheet(
                          context,
                          post: post,
                          commentController: widget.commentController,
                        ),
                        onAuthorTap: () => widget.onAuthorTapFromFeed(post),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}
