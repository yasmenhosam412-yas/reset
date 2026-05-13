import 'package:fpdart/fpdart.dart';
import 'package:new_project/core/errors/failure.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/repositories/home_repository.dart';

class ReportHomeUserUsecase {
  ReportHomeUserUsecase({required HomeRepository homeRepository})
      : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  Future<Either<Failure, void>> call({
    required String reportedUserId,
    String? reason,
    String? details,
    Map<String, dynamic>? context,
  }) {
    return _homeRepository.reportUser(
      reportedUserId: reportedUserId,
      reason: reason,
      details: details,
      context: context,
    );
  }
}
