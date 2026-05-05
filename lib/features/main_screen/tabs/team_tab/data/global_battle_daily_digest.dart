import 'package:new_project/features/main_screen/tabs/team_tab/data/global_battles_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cached for the daily 12:00 PM local notification body.
abstract final class GlobalBattleDigestPrefs {
  static const summaryKey = 'gb_digest_summary_v1';
  static const periodKey = 'gb_digest_period_v1';
}

/// One row for the in-app “champions” card and notification text.
class GlobalBattleDigestRow {
  const GlobalBattleDigestRow({
    required this.battleId,
    required this.title,
    required this.champion,
  });

  final int battleId;
  final String title;
  final GlobalBattleStanding? champion;
}

abstract final class GlobalBattleDailyDigest {
  static const _titles = {
    1: 'Cosmic dice',
    2: 'Green-light reflex',
    3: 'Oracle digit',
    4: 'Five-second blitz',
    5: 'Parity prophet',
  };

  static String _scoreLine(int battleId, GlobalBattleStanding s) {
    switch (battleId) {
      case 1:
        return '${s.score}';
      case 2:
        final ms = s.extras['ms'];
        return ms != null ? '$ms ms' : '${s.score}';
      case 3:
        final g = s.extras['g'];
        return g != null ? 'picked $g' : '${s.score}';
      case 4:
        final t = s.extras['taps'];
        return t != null ? '$t taps' : '${s.score} taps';
      case 5:
        final p = s.extras['pick']?.toString() ?? '';
        return p.isEmpty ? '${s.score}' : p;
      default:
        return '${s.score}';
    }
  }

  /// Fetches top player per battle for [periodKey] (usually [GlobalBattlesRepository.utcYesterdayPeriodKey]).
  static Future<List<GlobalBattleDigestRow>> fetchRows({
    required GlobalBattlesRepository repo,
    required String periodKey,
  }) async {
    final out = <GlobalBattleDigestRow>[];
    for (var id = 1; id <= 5; id++) {
      final top = await repo.fetchTopPlayer(battleId: id, periodKey: periodKey);
      out.add(
        GlobalBattleDigestRow(
          battleId: id,
          title: _titles[id] ?? 'Battle $id',
          champion: top,
        ),
      );
    }
    return out;
  }

  /// Loads yesterday’s UTC digest, persists summary for the noon notification, returns rows for UI.
  static Future<({String period, List<GlobalBattleDigestRow> rows})>
      loadYesterdayDigest(GlobalBattlesRepository repo) async {
    final period = GlobalBattlesRepository.utcYesterdayPeriodKey();
    final rows = await fetchRows(repo: repo, periodKey: period);
    final parts = <String>[];
    for (final r in rows) {
      final c = r.champion;
      if (c == null) {
        parts.add('${r.title}: no entries');
      } else {
        parts.add('${r.title}: ${c.username} (${_scoreLine(r.battleId, c)})');
      }
    }
    var summary = parts.join(' · ');
    if (summary.length > 380) {
      summary = '${summary.substring(0, 377)}…';
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GlobalBattleDigestPrefs.summaryKey, summary);
    await prefs.setString(GlobalBattleDigestPrefs.periodKey, period);
    return (period: period, rows: rows);
  }
}
