import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class AddHomePostUsecase {
  AddHomePostUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, void>> call({
    required String postContent,
    String postImage = '',
    Uint8List? imageBytes,
    String? imageContentType,
  }) {
    return _homeRepository.addPost(
      postContent: postContent,
      postImage: postImage,
      imageBytes: imageBytes,
      imageContentType: imageContentType,
    );
  }
}
