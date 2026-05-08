import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_post_author_actions_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/pages/author_posts_screen.dart';

/// Pushes [AuthorPostsScreen] without switching main tabs.
void openAuthorPostsScreen({
  required BuildContext context,
  required String authorId,
  required String authorName,
  required TextEditingController commentController,
  String? focusPostId,
  bool openCommentsAfterScroll = false,
}) {
  final id = authorId.trim();
  if (id.isEmpty) return;
  final hostContext = context;
  final focus = focusPostId?.trim() ?? '';

  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (routeContext) => BlocProvider.value(
        value: hostContext.read<HomeBloc>(),
        child: AuthorPostsScreen(
          authorId: id,
          authorName: authorName.trim().isEmpty
              ? hostContext.l10n.posts
              : authorName.trim(),
          focusPostId: focus.isEmpty ? null : focus,
          commentController: commentController,
          openCommentsAfterScroll: openCommentsAfterScroll,
          onAuthorTapFromFeed: (PostModel p) {
            showHomePostAuthorActionsSheet(hostContext, p);
          },
        ),
      ),
    ),
  );
}
