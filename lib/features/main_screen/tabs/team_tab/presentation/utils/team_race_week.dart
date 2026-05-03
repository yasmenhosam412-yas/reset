/// UTC calendar Monday used as the weekly bucket for lineup races (same key for all users).
String lineupRaceMondayIdUtc([DateTime? clock]) {
  final n = (clock ?? DateTime.now()).toUtc();
  final d = DateTime.utc(n.year, n.month, n.day);
  final monday = d.subtract(Duration(days: d.weekday - 1));
  final y = monday.year.toString().padLeft(4, '0');
  final m = monday.month.toString().padLeft(2, '0');
  final day = monday.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Race keys stored in [team_lineup_race_entries.race_key].
String lineupRaceKeyPower(String mondayId) => 'r_power_$mondayId';

String lineupRaceKeySpeed(String mondayId) => 'r_speed_$mondayId';

String lineupRaceKeyBalance(String mondayId) => 'r_balance_$mondayId';
