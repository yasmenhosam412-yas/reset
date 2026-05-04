class TeamRosterPlayer {
  TeamRosterPlayer({
    required this.name,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.stamina,
    this.avatarBase64,
  });

  String name;
  int attack;
  int defense;
  int speed;
  int stamina;

  /// Optional JPEG/PNG bytes as base64 (synced in [team_squad] JSON).
  String? avatarBase64;
}
