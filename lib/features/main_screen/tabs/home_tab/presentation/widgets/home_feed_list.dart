import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/post_reactions.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_post_card.dart';

class HomeFeedList extends StatelessWidget {
  const HomeFeedList({
    super.key,
    required this.posts,
    required this.onOpenComments,
    required this.onAuthorTap,
    this.scrollController,
    this.feedHeader,
    this.postKeyBuilder,
  });

  final List<PostModel> posts;
  final void Function(PostModel post) onOpenComments;
  final void Function(PostModel post) onAuthorTap;
  final ScrollController? scrollController;
  /// Keys for scrolling to a post (e.g. from Alerts deep link).
  final Key Function(PostModel post)? postKeyBuilder;
  /// When set, pinned above the feed inside the same scroll view as the posts.
  final Widget? feedHeader;

  Future<void> _onRefresh(BuildContext context) async {
    final bloc = context.read<HomeBloc>();
    if (bloc.state.status == HomeStatus.loading) return;
    bloc.add(HomePostsRequested());
    await bloc.stream.firstWhere((s) => s.status != HomeStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    final listChildCount = posts.isEmpty ? 0 : posts.length * 2 - 1;

    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (feedHeader != null) SliverToBoxAdapter(child: feedHeader!),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: 12);
                  }
                  final postIndex = index ~/ 2;
                  final post = posts[postIndex];
                  return HomePostCard(
                    key: postKeyBuilder?.call(post),
                    post: post,
                    myReaction: homePostMyReaction(post),
                    onOpenComments: () => onOpenComments(post),
                    onAuthorTap: homePostAuthorActionsAvailable(post)
                        ? () => onAuthorTap(post)
                        : null,
                  );
                },
                childCount: listChildCount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
