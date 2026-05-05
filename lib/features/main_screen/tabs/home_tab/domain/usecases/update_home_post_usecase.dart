import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class UpdateHomePostUsecase {
  UpdateHomePostUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, void>> call({
    required String postId,
    required String postContent,
    Uint8List? imageBytes,
    String? imageContentType,
    bool clearImage = false,
    required bool allowShare,
  }) {
    return _homeRepository.updatePost(
      postId: postId,
      postContent: postContent,
      imageBytes: imageBytes,
      imageContentType: imageContentType,
      clearImage: clearImage,
      allowShare: allowShare,
    );
  }
}
