import 'package:new_project/features/main_screen/tabs/online_tab/domain/repositories/online_repository.dart';

/// Supabase session for game ID 2 (`rps_sessions`).
class RpsDuelOnlineConfig {
  const RpsDuelOnlineConfig({
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
