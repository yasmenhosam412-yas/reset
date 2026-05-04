import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class UpdateProfileUsecase {
  UpdateProfileUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, void>> call({
    required String username,
    Uint8List? avatarBytes,
    String? avatarContentType,
  }) {
    return _homeRepository.updateMyProfile(
      username: username,
      avatarBytes: avatarBytes,
      avatarContentType: avatarContentType,
    );
  }
}
