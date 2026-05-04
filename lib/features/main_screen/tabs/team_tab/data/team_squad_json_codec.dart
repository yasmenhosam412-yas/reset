import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_formation.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_roster_player.dart';

class StoredTeamSquad {
  const StoredTeamSquad({
    required this.teamName,
    required this.formationIndex,
    required this.players,
  });

  final String teamName;
  final int formationIndex;
  final List<TeamRosterPlayer> players;
}

StoredTeamSquad? parseStoredTeamSquad(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  final name = raw['team_name']?.toString().trim() ?? '';
  if (name.isEmpty) return null;
  final fiRaw = raw['formation_index'];
  final fi = fiRaw is int
      ? fiRaw
      : fiRaw is num
      ? fiRaw.toInt()
      : int.tryParse('$fiRaw') ?? 0;
  final clampedFi = fi.clamp(0, kTeamFormations.length - 1).toInt();
  final pl = raw['players'];
  if (pl is! List || pl.length != 6) return null;
  final players = <TeamRosterPlayer>[];
  for (final e in pl) {
    if (e is! Map) return null;
    final m = Map<String, dynamic>.from(e);
    final n = m['name']?.toString().trim() ?? 'Player';
    final avatarRaw = m['avatar_base64']?.toString().trim();
    final avatar = avatarRaw != null && avatarRaw.isNotEmpty ? avatarRaw : null;
    int stat(String k) {
      final v = m[k];
      if (v is int) return v.clamp(40, 99);
      if (v is num) return v.toInt().clamp(40, 99);
      return int.tryParse('$v')?.clamp(40, 99) ?? 70;
    }

    players.add(
      TeamRosterPlayer(
        name: n,
        attack: stat('attack'),
        defense: stat('defense'),
        speed: stat('speed'),
        stamina: stat('stamina'),
        avatarBase64: avatar,
      ),
    );
  }
  return StoredTeamSquad(
    teamName: name,
    formationIndex: clampedFi,
    players: players,
  );
}

Map<String, dynamic> encodeTeamSquadJson({
  required String teamName,
  required int formationIndex,
  required List<TeamRosterPlayer> players,
}) {
  final fi = formationIndex.clamp(0, kTeamFormations.length - 1);
  return {
    'team_name': teamName,
    'formation_index': fi,
    'players': players
        .map(
          (p) => {
            'name': p.name,
            'attack': p.attack.clamp(40, 99),
            'defense': p.defense.clamp(40, 99),
            'speed': p.speed.clamp(40, 99),
            'stamina': p.stamina.clamp(40, 99),
            if (p.avatarBase64 != null && p.avatarBase64!.isNotEmpty)
              'avatar_base64': p.avatarBase64,
          },
        )
        .toList(growable: false),
  };
}
