import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_comments_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_new_post_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_feed_empty_placeholder.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_feed_list.dart';

class _ChallengeGame {
  const _ChallengeGame({
    required this.id,
    required this.title,
    required this.icon,
  });

  final int id;
  final String title;
  final IconData icon;
}

const List<_ChallengeGame> _kChallengeGames = [
  _ChallengeGame(id: 1, title: 'Chess', icon: Icons.grid_on_rounded),
  _ChallengeGame(id: 2, title: 'Quick duel', icon: Icons.flash_on_rounded),
  _ChallengeGame(id: 3, title: 'Trivia rush', icon: Icons.quiz_outlined),
];

enum _FeedSort { latest, mostLiked }

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _newPostController = TextEditingController();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  _FeedSort _feedSort = _FeedSort.latest;
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeBloc>().add(HomePostsRequested());
    });
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
    _scrollController.removeListener(_onScrollOffset);
    _scrollController.dispose();
    _searchController.dispose();
    _newPostController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  List<PostModel> _filteredAndSorted(List<PostModel> posts) {
    var list = List<PostModel>.from(posts);
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.postContent.toLowerCase().contains(q) ||
                p.userModel.username.toLowerCase().contains(q),
          )
          .toList();
    }
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
      'Search matches post text and display names.',
      'Switch to Top liked to see what’s trending.',
    ];
    final tip = tips[Random().nextInt(tips.length)];
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tip), behavior: SnackBarBehavior.floating),
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
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _onGreetingTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.waving_hand_rounded,
                            color: scheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Tap for a quick tip',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
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
                AnimatedOpacity(
                  opacity: _showScrollTop ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton.filledTonal(
                    onPressed: _showScrollTop
                        ? () {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 400),
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
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search posts or people…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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

  void _openComments(PostModel post) {
    showHomeCommentsSheet(
      context,
      post: post,
      commentController: _commentController,
    );
  }

  void _openPostAuthorActions(BuildContext context, PostModel post) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final author = post.userModel.username;
    final state = context.read<HomeBloc>().state;
    final authorIdNorm = post.userModel.id.trim().toLowerCase();
    final alreadyFriend = authorIdNorm.isNotEmpty &&
        state.acceptedFriendUserIds.contains(authorIdNorm);
    final myId =
        Supabase.instance.client.auth.currentUser?.id.trim().toLowerCase();
    final isSelf =
        myId != null && myId.isNotEmpty && myId == authorIdNorm;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  author,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                if (isSelf)
                  Text(
                    'This is your post.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else ...[
                  if (alreadyFriend)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          Icon(Icons.people_rounded, color: scheme.primary),
                      title: const Text('Friends'),
                      subtitle: Text(
                        'You are already connected — no new request needed.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.read<HomeBloc>().add(
                              HomeSendFriendRequest(
                                userModel: post.userModel,
                              ),
                            );
                      },
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Send friend request'),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _showChallengeGamePicker(context, post);
                    },
                    icon: const Icon(Icons.sports_esports_rounded),
                    label: const Text('Send challenge'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChallengeGamePicker(BuildContext context, PostModel post) {
    var selectedId = _kChallengeGames.first.id;
    final homeContext = context;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Choose a game'),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final game in _kChallengeGames)
                      FilterChip(
                        avatar: Icon(game.icon, size: 20),
                        label: Text(game.title),
                        selected: selectedId == game.id,
                        onSelected: (_) {
                          setDialogState(() => selectedId = game.id);
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    homeContext.read<HomeBloc>().add(
                      HomeSendChallenge(
                        userModel: post.userModel,
                        gameId: selectedId,
                      ),
                    );
                  },
                  child: const Text('Send challenge'),
                ),
              ],
            );
          },
        );
      },
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
                ? const Center(child: CircularProgressIndicator())
                : empty && state.status == HomeStatus.loaded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const Expanded(child: HomeFeedEmptyPlaceholder()),
                    ],
                  )
                : displayed.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshFeed,
                          child: ListView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts match your search.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try another keyword or clear the search box.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      Expanded(
                        child: HomeFeedList(
                          posts: displayed,
                          scrollController: _scrollController,
                          onOpenComments: _openComments,
                          onAuthorTap: (post) =>
                              _openPostAuthorActions(context, post),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
