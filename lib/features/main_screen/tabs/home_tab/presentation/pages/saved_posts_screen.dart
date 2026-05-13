import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_comments_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_post_author_actions_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/post_reactions.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_post_card.dart';

/// Bookmarks from [HomeBloc.savedPostsOverlay], ordered by most recently saved.
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key, required this.commentController});

  final TextEditingController commentController;

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeBloc>().add(HomeSavedPostsLoadRequested());
    });
  }

  Future<void> _onRefresh() async {
    context.read<HomeBloc>().add(HomeSavedPostsLoadRequested());
    await context.read<HomeBloc>().stream.firstWhere(
      (s) => !s.savedPostsLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.saves),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: scheme.surfaceTint,
        scrolledUnderElevation: 0.5,
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        buildWhen: (prev, curr) =>
            prev.savedPostsOverlay != curr.savedPostsOverlay ||
            prev.savedPostsLoading != curr.savedPostsLoading,
        builder: (context, state) {
          if (state.savedPostsLoading && state.savedPostsOverlay.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = state.savedPostsOverlay;
          if (posts.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.savedPostsEmpty,
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
            onRefresh: _onRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final post = posts[index];
                return HomePostCard(
                  post: post,
                  myReaction: homePostMyReaction(post),
                  onOpenComments: () => showHomeCommentsSheet(
                    context,
                    post: post,
                    commentController: widget.commentController,
                  ),
                  onAuthorTap: () => showHomePostAuthorActionsSheet(context, post),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
