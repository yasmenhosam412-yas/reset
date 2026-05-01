import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_datasource.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDatasource homeDatasource;

  HomeRepositoryImpl({required this.homeDatasource});
  @override
  Future<Either<Failure, void>> addComment({
    required String postId,
    required String comment,
  }) async {
    try {
      await homeDatasource.addComment(postId: postId, comment: comment);
      return Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> togglePostLike({required String postId}) async {
    try {
      await homeDatasource.togglePostLike(postId: postId);
      return Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> addPost({
    required String postContent,
    String postImage = '',
    Uint8List? imageBytes,
    String? imageContentType,
  }) async {
    try {
      await homeDatasource.addPost(
        postContent: postContent,
        postImage: postImage,
        imageBytes: imageBytes,
        imageContentType: imageContentType,
      );
      return Right(null);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> getPosts() async {
    try {
      final result = await homeDatasource.getPosts();
      return Right(result);
    } catch (e) {
      return Left(failureFromException(e));
    }
  }
}
