import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/navigation/main_shell_controller.dart';
import 'package:new_project/core/widgets/tab_loading_skeletons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_comments_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_new_post_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_post_author_actions_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/navigation/open_author_posts_screen.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/pages/explore_people_screen.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_feed_empty_placeholder.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_feed_list.dart';


enum _FeedSort { latest, mostLiked }


class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  final _newPostController = TextEditingController();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  late final MainShellController _mainShell;
  late final AnimationController _headerAccentController;

  _FeedSort _feedSort = _FeedSort.latest;
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _headerAccentController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _scrollController.addListener(_onScrollOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeBloc>().add(HomePostsRequested());
    });
    _mainShell = getIt<MainShellController>();
    _mainShell.addListener(_onShellDeepLink);
  }

  void _onShellDeepLink() {
    final focus = _mainShell.peekHomePost();
    if (focus == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handlePostDeepLink(focus.postId, focus.openComments);
    });
  }

  Future<void> _handlePostDeepLink(String postId, bool openComments) async {
    final shell = getIt<MainShellController>();
    final id = postId.trim();
    if (id.isEmpty) {
      shell.clearHomePost();
      return;
    }
    if (!mounted) return;

    PostModel? findInState(HomeState s) {
      for (final p in s.posts) {
        if (p.id.trim() == id) return p;
      }
      return null;
    }

    var post = findInState(context.read<HomeBloc>().state);
    if (post == null) {
      context.read<HomeBloc>().add(HomePostsRequested());
      await context.read<HomeBloc>().stream.firstWhere(
            (s) => s.status != HomeStatus.loading,
          );
      if (!mounted) return;
      post = findInState(context.read<HomeBloc>().state);
    }

    if (post == null) {
      shell.clearHomePost();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t find that post on the feed.')),
        );
      }
      return;
    }
    if (!mounted) return;
    shell.clearHomePost();
    _openAuthorPostsFromNotification(post, openComments: openComments);
  }

  void _onScrollOffset() {
    if (!_scrollController.hasClients) return;
    final next = _scrollController.offset > 220;
    if (next != _showScrollTop && mounted) {
      setState(() => _showScrollTop = next);
    }
  }

  @override
  void dispose() {
    _headerAccentController.dispose();
    _scrollController.removeListener(_onScrollOffset);
    _scrollController.dispose();
    _newPostController.dispose();
    _commentController.dispose();
    _mainShell.removeListener(_onShellDeepLink);
    super.dispose();
  }

  List<PostModel> _filteredAndSorted(List<PostModel> posts) {
    var list = List<PostModel>.from(posts);
    switch (_feedSort) {
      case _FeedSort.latest:
        break;
      case _FeedSort.mostLiked:
        list.sort((a, b) => b.likes.length.compareTo(a.likes.length));
    }
    return list;
  }

  Future<void> _refreshFeed() async {
    final bloc = context.read<HomeBloc>();
    if (bloc.state.status == HomeStatus.loading) return;
    bloc.add(HomePostsRequested());
    await bloc.stream.firstWhere((s) => s.status != HomeStatus.loading);
  }

  void _onGreetingTap() {
    const tips = [
      'Pull down on the list to refresh posts.',
      'Tap someone’s name to add them or send a game challenge.',
      'Use Explore people under Jump in to search players by username.',
      'Switch to Top liked to see what’s trending.',
    ];
    final tip = tips[Random().nextInt(tips.length)];
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tip), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildQuickActivitySlot({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final accent = iconColor ?? scheme.primary;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Tooltip(
              message: tooltip,
              waitDuration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: accent),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Material(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedBuilder(
              animation: _headerAccentController,
              builder: (context, child) {
                final t = CurvedAnimation(
                  parent: _headerAccentController,
                  curve: Curves.easeInOut,
                ).value;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment(-0.8 + t * 0.15, -1),
                      end: Alignment(0.9 - t * 0.1, 1.1),
                      colors: [
                        Color.lerp(
                          scheme.primaryContainer,
                          scheme.tertiaryContainer,
                          t * 0.55,
                        )!,
                        Color.lerp(
                          scheme.secondaryContainer,
                          scheme.primaryContainer,
                          0.35 + t * 0.35,
                        )!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _onGreetingTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 2,
                            ),
                            child: Row(
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 650),
                                  curve: Curves.elasticOut,
                                  builder: (context, v, _) {
                                    return Transform.rotate(
                                      angle: (1 - v) * 0.35,
                                      child: Icon(
                                        Icons.waving_hand_rounded,
                                        color: scheme.primary,
                                        size: 32,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        greeting,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tap for a feed tip · your community hub',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.75),
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _showScrollTop ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                        onPressed: _showScrollTop
                            ? () {
                                _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.vertical_align_top_rounded),
                        tooltip: 'Back to top',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Jump in',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.edit_note_rounded,
                  label: 'Post',
                  tooltip: 'New post — share an update',
                  onTap: _openNewPostSheet,
                  iconColor: scheme.tertiary,
                ),
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.sports_esports_rounded,
                  label: 'Online',
                  tooltip: 'Play online — challenges & duels',
                  onTap: () => _mainShell.goToMainTab(1),
                  iconColor: scheme.primary,
                ),
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.notifications_active_outlined,
                  label: 'Alerts',
                  tooltip: 'Alerts — replies & invites',
                  onTap: () => _mainShell.goToMainTab(2),
                ),
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.groups_outlined,
                  label: 'Battles',
                  tooltip: 'Battles — team events',
                  onTap: () => _mainShell.goToMainTab(3),
                  iconColor: scheme.secondary,
                ),
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  tooltip: 'Profile — you & friends',
                  onTap: () => _mainShell.goToMainTab(4),
                ),
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.travel_explore_rounded,
                  label: 'People',
                  tooltip: 'Explore people — search & friend requests',
                  onTap: _openExplorePeople,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Material(
              color: scheme.primaryContainer.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _openExplorePeople,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.groups_2_rounded, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore people',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Search players, add friends, respond to requests on Profile',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_FeedSort>(
              segments: const [
                ButtonSegment(
                  value: _FeedSort.latest,
                  label: Text('Latest'),
                  icon: Icon(Icons.schedule_rounded, size: 18),
                ),
                ButtonSegment(
                  value: _FeedSort.mostLiked,
                  label: Text('Top liked'),
                  icon: Icon(Icons.favorite_outline_rounded, size: 18),
                ),
              ],
              selected: {_feedSort},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                setState(() => _feedSort = s.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishPost(
    String content,
    Uint8List? imageBytes,
    String? imageContentType,
    bool allowShare,
  ) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty && (imageBytes == null || imageBytes.isEmpty)) {
      return;
    }
    if (!mounted) return;
    context.read<HomeBloc>().add(
      HomePostCreateRequested(
        postContent: trimmed,
        imageBytes: imageBytes,
        imageContentType: imageContentType,
        allowShare: allowShare,
      ),
    );
    _newPostController.clear();
    if (mounted) Navigator.of(context).pop();
  }

  void _openNewPostSheet() {
    showHomeNewPostSheet(
      context,
      contentController: _newPostController,
      onPublish: _publishPost,
    );
  }

  void _openExplorePeople() {
    final bloc = context.read<HomeBloc>();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const ExplorePeopleScreen(),
        ),
      ),
    );
  }

  void _openComments(PostModel post) {
    showHomeCommentsSheet(
      context,
      post: post,
      commentController: _commentController,
    );
  }

  void _openAuthorPostsFromNotification(
    PostModel post, {
    required bool openComments,
  }) {
    openAuthorPostsScreen(
      context: context,
      authorId: post.userModel.id,
      authorName: post.userModel.username,
      commentController: _commentController,
      focusPostId: post.id,
      openCommentsAfterScroll: openComments,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (prev, curr) =>
          (curr.errorMessage != null &&
              curr.errorMessage != prev.errorMessage) ||
          (curr.successMessage != null &&
              curr.successMessage != prev.successMessage),
      listener: (context, state) {
        final err = state.errorMessage;
        if (err != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
        final ok = state.successMessage;
        if (ok != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ok)));
        }
      },
      builder: (context, state) {
        final posts = state.posts;
        final loading = state.status == HomeStatus.loading;
        final empty = posts.isEmpty;
        final displayed = _filteredAndSorted(posts);
        final header = _buildInteractiveHeader(context);

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openNewPostSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New post'),
          ),
          body: SafeArea(
            child: loading && empty
                ? TabLoadingSkeletons.homeFeed(context)
                : empty && state.status == HomeStatus.loaded
                ? RefreshIndicator(
                    onRefresh: _refreshFeed,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: header),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: HomeFeedEmptyPlaceholder(),
                        ),
                      ],
                    ),
                  )
                : HomeFeedList(
                    posts: displayed,
                    scrollController: _scrollController,
                    feedHeader: header,
                    onOpenComments: _openComments,
                    onAuthorTap: (post) =>
                        showHomePostAuthorActionsSheet(context, post),
                  ),
          ),
        );
      },
    );
  }
}
