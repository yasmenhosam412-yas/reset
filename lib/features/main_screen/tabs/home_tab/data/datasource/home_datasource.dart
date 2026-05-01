import 'dart:typed_data';

import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';

abstract class HomeDatasource {
  Future<void> addPost({
    required String postContent,
    String postImage,
    Uint8List? imageBytes,
    String? imageContentType,
  });

  Future<void> addComment({
    required String postId,
    required String comment,
  });

  Future<void> togglePostLike({required String postId});

  Future<List<PostModel>> getPosts();
}
