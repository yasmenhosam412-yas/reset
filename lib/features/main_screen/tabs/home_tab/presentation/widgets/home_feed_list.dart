import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_post_card.dart';

class HomeFeedList extends StatelessWidget {
  const HomeFeedList({
    super.key,
    required this.posts,
    required this.onOpenComments,
    required this.onAuthorTap,
    this.scrollController,
  });

  final List<PostModel> posts;
  final void Function(PostModel post) onOpenComments;
  final void Function(PostModel post) onAuthorTap;
  final ScrollController? scrollController;

  Future<void> _onRefresh(BuildContext context) async {
    final bloc = context.read<HomeBloc>();
    if (bloc.state.status == HomeStatus.loading) return;
    bloc.add(HomePostsRequested());
    await bloc.stream.firstWhere((s) => s.status != HomeStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: posts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = posts[index];
          return HomePostCard(
            post: post,
            likedByMe: homePostLikedByCurrentUser(post),
            onOpenComments: () => onOpenComments(post),
            onAuthorTap: homePostAuthorActionsAvailable(post)
                ? () => onAuthorTap(post)
                : null,
          );
        },
      ),
    );
  }
}
