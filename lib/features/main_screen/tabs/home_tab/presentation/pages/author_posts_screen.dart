import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/utils/pagination_consts.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_posts_for_author_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_comments_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/post_reactions.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_post_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<PostModel> _posts = const [];
  bool _loading = true;
  String? _error;

  String get _authorId => widget.authorId.trim();
  String get _focusId => widget.focusPostId?.trim() ?? '';

  bool get _viewingSelf {
    final myId =
        Supabase.instance.client.auth.currentUser?.id.trim().toLowerCase() ??
        '';
    return myId.isNotEmpty && myId == _authorId.toLowerCase();
  }

  bool _shouldReloadAfterSuccess(HomeState curr) {
    switch (curr.successType) {
      case HomeSuccessType.postDeleted:
      case HomeSuccessType.postUpdated:
        return true;
      case HomeSuccessType.postCreated:
        return _viewingSelf;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPosts());
  }

  Future<void> _loadPosts() async {
    final id = _authorId;
    if (id.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<GetHomePostsForAuthorUsecase>()(
      authorUserId: id,
      limit: 60,
      offset: PaginationConsts.offsetPosts,
    );
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
        _posts = const [];
      }),
      (list) {
        setState(() {
          _loading = false;
          _error = null;
          _posts = list;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _tryScrollToFocus(_posts);
        });
      },
    );
  }

  PostModel _liveFromBloc(HomeState s, PostModel p) {
    final pid = p.id.trim();
    for (final x in s.posts) {
      if (x.id.trim() == pid) return x;
    }
    return p;
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
          PostModel? live;
          for (final p in _posts) {
            if (p.id.trim() == _focusId) {
              live = p;
              break;
            }
          }
          if (live == null) {
            for (final x in context.read<HomeBloc>().state.posts) {
              if (x.id.trim() == _focusId) {
                live = x;
                break;
              }
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
    final l10n = context.l10n;
    final name = widget.authorName.trim().isEmpty
        ? l10n.posts
        : widget.authorName.trim();

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (prev, curr) =>
          prev.successType != curr.successType &&
          _shouldReloadAfterSuccess(curr),
      listener: (context, state) {
        _loadPosts();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(name),
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: scheme.surfaceTint,
          scrolledUnderElevation: 0.5,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadPosts,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              )
            : BlocBuilder<HomeBloc, HomeState>(
                buildWhen: (p, c) => p.posts != c.posts,
                builder: (context, blocState) {
                  final posts =
                      _posts.map((p) => _liveFromBloc(blocState, p)).toList();

                  if (posts.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  l10n.noPostsFromProfileYet,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadPosts,
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
                          myReaction: homePostMyReaction(post),
                          onOpenComments: () => showHomeCommentsSheet(
                            context,
                            post: post,
                            commentController: widget.commentController,
                          ),
                          onAuthorTap: () =>
                              widget.onAuthorTapFromFeed(post),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
