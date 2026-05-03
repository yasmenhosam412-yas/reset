import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';

class FantasyDuelOnlineConfig {
  const FantasyDuelOnlineConfig({
    required this.challengeId,
    required this.fromUserId,
    required this.toUserId,
    required this.repository,
  });

  final String challengeId;
  final String fromUserId;
  final String toUserId;
  final OnlineRepository repository;
}
