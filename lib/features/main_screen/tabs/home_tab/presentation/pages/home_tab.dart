import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_comments_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/home_new_post_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_feed_empty_placeholder.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_feed_list.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _newPostController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeBloc>().add(HomePostsRequested());
    });
  }

  @override
  void dispose() {
    _newPostController.dispose();
    _commentController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage != null && curr.errorMessage != prev.errorMessage,
      listener: (context, state) {
        final msg = state.errorMessage;
        if (msg != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      builder: (context, state) {
        final posts = state.posts;
        final loading = state.status == HomeStatus.loading;
        final empty = posts.isEmpty;

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
                ? const HomeFeedEmptyPlaceholder()
                : HomeFeedList(posts: posts, onOpenComments: _openComments),
          ),
        );
      },
    );
  }
}
