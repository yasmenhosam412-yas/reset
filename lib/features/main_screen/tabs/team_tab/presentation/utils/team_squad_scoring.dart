import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_roster_player.dart';

/// Mirrors `public._lineup_race_score` in Supabase so on-device previews match leaderboards.

int _s(int v) => v.clamp(0, 99);

int squadPowerScore(List<TeamRosterPlayer> players) {
  if (players.length != 6) return 0;
  var total = 0;
  for (final p in players) {
    total += _s(p.attack) + _s(p.defense) + _s(p.speed) + _s(p.stamina);
  }
  return total;
}

int squadSpeedDashScore(List<TeamRosterPlayer> players) {
  if (players.length != 6) return 0;
  var total = 0;
  for (final p in players) {
    final sp = _s(p.speed);
    final st = _s(p.stamina);
    total += sp * 2 + st;
  }
  return total;
}

int squadBalanceScore(List<TeamRosterPlayer> players) {
  if (players.length != 6) return 0;
  var total = 0;
  for (final p in players) {
    final a = _s(p.attack);
    final d = _s(p.defense);
    final sp = _s(p.speed);
    final st = _s(p.stamina);
    final m = [a, d, sp, st].reduce((x, y) => x < y ? x : y);
    total += m * 15;
  }
  return total;
}

/// Theoretical maxima (all stats 99) for progress bars.
const int kSquadPowerScoreMax = 6 * 4 * 99;
const int kSquadSpeedDashScoreMax = 6 * (2 * 99 + 99);
const int kSquadBalanceScoreMax = 6 * 99 * 15;
