import 'package:new_project/features/authentication/data/models/user_model.dart';

enum PeopleDiscoveryLink {
  none,
  friend,
  pendingOutgoing,
  pendingIncoming,
}

class PeopleDiscoveryRow {
  const PeopleDiscoveryRow({
    required this.user,
    required this.link,
  });

  final UserModel user;
  final PeopleDiscoveryLink link;
}
