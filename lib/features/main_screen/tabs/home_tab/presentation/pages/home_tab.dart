import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/navigation/main_shell_controller.dart';
import 'package:new_project/core/utils/pagination_consts.dart';
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
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_titles.dart';

enum _FeedSort { latest, mostLiked }

enum _PostTypeFilter { all, post, announcement, celebration, ads }

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
  _PostTypeFilter _postTypeFilter = _PostTypeFilter.all;
  bool _showScrollTop = false;
  int _currentLimit = PaginationConsts.limitPosts;
  bool _isFetchingMore = false;
  bool _hasMorePosts = true;
  int _lastRequestedLimit = PaginationConsts.limitPosts;
  DateTime? _lastLoadMoreAt;

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
      _requestFirstPage();
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
    final l10n = context.l10n;
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
      context.read<HomeBloc>().add(
        HomePostsRequested(
          limit: _currentLimit,
          offset: PaginationConsts.offsetPosts,
        ),
      );
      await context.read<HomeBloc>().stream.firstWhere(
        (s) => s.status != HomeStatus.loading,
      );
      if (!mounted) return;
      post = findInState(context.read<HomeBloc>().state);
    }

    if (post == null) {
      shell.clearHomePost();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.couldNotFindPostInFeed)));
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
    _maybeLoadMore();
  }

  void _requestFirstPage() {
    _currentLimit = PaginationConsts.limitPosts;
    _hasMorePosts = true;
    _isFetchingMore = false;
    _lastRequestedLimit = _currentLimit;
    _lastLoadMoreAt = null;
    context.read<HomeBloc>().add(
      HomePostsRequested(
        limit: _currentLimit,
        offset: PaginationConsts.offsetPosts,
      ),
    );
  }

  Future<void> _maybeLoadMore() async {
    if (!_scrollController.hasClients) return;
    if (_isFetchingMore || !_hasMorePosts) return;
    if (_feedSort != _FeedSort.latest) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    if (position.maxScrollExtent <= 0) return;
    if (position.extentAfter > 220) return;

    final now = DateTime.now();
    if (_lastLoadMoreAt != null &&
        now.difference(_lastLoadMoreAt!).inMilliseconds < 500) {
      return;
    }

    final bloc = context.read<HomeBloc>();
    if (bloc.state.status == HomeStatus.loading) return;

    final nextLimit = _currentLimit + PaginationConsts.limitPosts;
    if (nextLimit <= _lastRequestedLimit) return;

    _isFetchingMore = true;
    _lastRequestedLimit = nextLimit;
    _lastLoadMoreAt = now;
    final previousCount = bloc.state.posts.length;
    bloc.add(
      HomePostsRequested(
        limit: nextLimit,
        offset: PaginationConsts.offsetPosts,
      ),
    );
    await bloc.stream.firstWhere((s) => s.status != HomeStatus.loading);
    if (!mounted) return;
    final currentCount = bloc.state.posts.length;
    _hasMorePosts = currentCount > previousCount;
    if (_hasMorePosts) {
      _currentLimit = nextLimit;
    }
    _isFetchingMore = false;
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
    var list = posts
        .where((post) {
          switch (_postTypeFilter) {
            case _PostTypeFilter.all:
              return true;
            case _PostTypeFilter.post:
              return post.postType == 'post';
            case _PostTypeFilter.announcement:
              return post.postType == 'announcement';
            case _PostTypeFilter.celebration:
              return post.postType == 'celebration';
            case _PostTypeFilter.ads:
              return post.postType == 'ads';
          }
        })
        .toList(growable: false);
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
    _currentLimit = PaginationConsts.limitPosts;
    _hasMorePosts = true;
    _isFetchingMore = false;
    _lastRequestedLimit = _currentLimit;
    _lastLoadMoreAt = null;
    bloc.add(
      HomePostsRequested(
        limit: _currentLimit,
        offset: PaginationConsts.offsetPosts,
      ),
    );
    await bloc.stream.firstWhere((s) => s.status != HomeStatus.loading);
    if (!mounted) return;
    _hasMorePosts = bloc.state.posts.length >= _currentLimit;
  }

  void _onGreetingTap() {
    final l10n = context.l10n;
    final tips = [
      l10n.feedTipPullToRefresh,
      l10n.feedTipTapName,
      l10n.feedTipExplorePeople,
      l10n.feedTipTopLiked,
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorning
        : hour < 17
        ? l10n.goodAfternoon
        : l10n.goodEvening;

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
                                        l10n.tapForFeedTip,
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
                        tooltip: l10n.backToTop,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.jumpIn,
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
                  label: l10n.post,
                  tooltip: l10n.quickNewPostTooltip,
                  onTap: _openNewPostSheet,
                  iconColor: scheme.tertiary,
                ),
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.sports_esports_rounded,
                  label: l10n.online,
                  tooltip: l10n.quickOnlineTooltip,
                  onTap: () => _mainShell.goToMainTab(1),
                  iconColor: scheme.primary,
                ),
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.notifications_active_outlined,
                  label: l10n.alerts,
                  tooltip: l10n.quickAlertsTooltip,
                  onTap: () => _mainShell.goToMainTab(2),
                ),
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.groups_outlined,
                  label: l10n.battles,
                  tooltip: l10n.quickBattlesTooltip,
                  onTap: () => _mainShell.goToMainTab(3),
                  iconColor: scheme.secondary,
                ),
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.person_rounded,
                  label: l10n.profile,
                  tooltip: l10n.quickProfileTooltip,
                  onTap: () => _mainShell.goToMainTab(4),
                ),
                _buildQuickActivitySlot(
                  context: context,
                  icon: Icons.travel_explore_rounded,
                  label: l10n.people,
                  tooltip: l10n.quickPeopleTooltip,
                  onTap: _openExplorePeople,
                ),
              ],
            ),

            const SizedBox(height: 12),
            SegmentedButton<_FeedSort>(
              segments: [
                ButtonSegment(
                  value: _FeedSort.latest,
                  label: Text(l10n.latest),
                  icon: Icon(Icons.schedule_rounded, size: 18),
                ),
                ButtonSegment(
                  value: _FeedSort.mostLiked,
                  label: Text(l10n.topLiked),
                  icon: Icon(Icons.favorite_outline_rounded, size: 18),
                ),
              ],
              selected: {_feedSort},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                setState(() => _feedSort = s.first);
              },
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_PostTypeFilter>(
                multiSelectionEnabled: false,
                segments: [
                  ButtonSegment(
                    value: _PostTypeFilter.all,
                    label: Text(l10n.all),
                    icon: Icon(Icons.apps_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: _PostTypeFilter.post,
                    label: Text(l10n.post),
                    icon: Icon(Icons.edit_note_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: _PostTypeFilter.announcement,
                    label: Text(l10n.announce),
                    icon: Icon(Icons.campaign_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: _PostTypeFilter.celebration,
                    label: Text(l10n.celebrate),
                    icon: Icon(Icons.celebration_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: _PostTypeFilter.ads,
                    label: Text(l10n.postTypeAds),
                    icon: Icon(Icons.storefront_outlined, size: 18),
                  ),
                ],
                selected: {_postTypeFilter},
                onSelectionChanged: (s) {
                  if (s.isEmpty) return;
                  setState(() => _postTypeFilter = s.first);
                },
              ),
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
    String? mediaLocalPath,
    bool allowShare,
    String postVisibility,
    String postType,
    String? adLink,
  ) async {
    final trimmed = content.trim();
    final hasBytes = imageBytes != null && imageBytes.isNotEmpty;
    final hasPath = mediaLocalPath != null && mediaLocalPath.trim().isNotEmpty;
    if (trimmed.isEmpty && !hasBytes && !hasPath) {
      return;
    }
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final bloc = context.read<HomeBloc>();
    bloc.add(
      HomePostCreateRequested(
        postContent: trimmed,
        imageBytes: imageBytes,
        imageContentType: imageContentType,
        mediaLocalPath: mediaLocalPath,
        allowShare: allowShare,
        postVisibility: postVisibility,
        postType: postType,
        adLink: adLink,
      ),
    );
    try {
      await bloc.stream
          .firstWhere(
            (s) =>
                s.successType == HomeSuccessType.postCreated ||
                (s.status == HomeStatus.failure &&
                    (s.errorMessage?.trim().isNotEmpty ?? false)),
          )
          .timeout(const Duration(minutes: 2));
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.somethingWentWrong)),
        );
      }
      return;
    }
    if (!mounted) return;
    if (bloc.state.successType == HomeSuccessType.postCreated) {
      _newPostController.clear();
      navigator.pop();
    }
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
        builder: (_) =>
            BlocProvider.value(value: bloc, child: const ExplorePeopleScreen()),
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
              curr.successMessage != prev.successMessage) ||
          (curr.successType != prev.successType),
      listener: (context, state) {
        final l10n = context.l10n;
        final err = state.errorMessage;
        if (err != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
        final ok = switch (state.successType) {
          HomeSuccessType.postCreated => l10n.homePostPublished,
          HomeSuccessType.postDeleted => l10n.homePostDeleted,
          HomeSuccessType.postUpdated => l10n.homePostUpdated,
          HomeSuccessType.postSaved => l10n.postSavedToSaves,
          HomeSuccessType.postUnsaved => l10n.postRemovedFromSaves,
          HomeSuccessType.alreadyFriends => l10n.alreadyFriendsWith(
            (state.successName?.trim().isEmpty ?? true)
                ? l10n.player
                : state.successName!.trim(),
          ),
          HomeSuccessType.friendRequestSent => l10n.friendRequestSentTo(
            (state.successName?.trim().isEmpty ?? true)
                ? l10n.player
                : state.successName!.trim(),
          ),
          HomeSuccessType.friendRequestWithdrawn => l10n.friendRequestWithdrawn,
          HomeSuccessType.challengeSent => l10n.challengeSentTo(
            onlineGameTitleL10n(l10n, state.successGameId ?? 1),
            (state.successName?.trim().isEmpty ?? true)
                ? l10n.player
                : state.successName!.trim(),
          ),
          HomeSuccessType.userBlocked => l10n.userBlockedSnackbar,
          HomeSuccessType.userReported => l10n.reportSubmittedSnackbar,
          null => state.successMessage,
        };
        if (ok != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ok)));
        }
      },
      builder: (context, state) {
        final l10n = context.l10n;
        final posts = state.posts;
        final loading = state.status == HomeStatus.loading;
        final empty = posts.isEmpty;
        final displayed = _filteredAndSorted(posts);
        final filterShowsNoPosts =
            !empty && displayed.isEmpty && state.status == HomeStatus.loaded;
        final header = _buildInteractiveHeader(context);

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openNewPostSheet,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.newPost),
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
                : filterShowsNoPosts
                ? RefreshIndicator(
                    onRefresh: _refreshFeed,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: header),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: HomeFeedEmptyPlaceholder(
                            message: l10n.noPostsFoundForFilter,
                          ),
                        ),
                      ],
                    ),
                  )
                : HomeFeedList(
                    posts: displayed,
                    scrollController: _scrollController,
                    feedHeader: header,
                    onOpenComments: _openComments,
                    onAuthorTap: (post) => showHomePostAuthorActionsSheet(
                      context,
                      post,
                      commentController: _commentController,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
