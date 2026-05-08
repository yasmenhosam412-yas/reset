import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase table [public.global_battle_entries] — daily UTC [periodKey], all users.
abstract final class GlobalBattleTable {
  static const name = 'global_battle_entries';
  static const battleId = 'battle_id';
  static const periodKey = 'period_key';
  static const userId = 'user_id';
  static const score = 'score';
  static const extras = 'extras';
  static const createdAt = 'created_at';
}

class GlobalBattleStanding {
  const GlobalBattleStanding({
    required this.userId,
    required this.username,
    required this.score,
    required this.extras,
    required this.createdAt,
  });

  final String userId;
  final String username;
  final int score;
  final Map<String, dynamic> extras;
  final DateTime? createdAt;
}

class GlobalBattleMyEntry {
  const GlobalBattleMyEntry({
    required this.score,
    required this.extras,
    required this.createdAt,
  });

  final int score;
  final Map<String, dynamic> extras;
  final DateTime? createdAt;
}

/// Deterministic daily values (same for every device).
int globalBattleDayMagic(String periodKey, String salt) {
  var h = 5381;
  for (final u in '$salt|$periodKey'.codeUnits) {
    h = ((h << 5) + h) + u;
    h &= 0x7fffffff;
  }
  return h;
}

int oracleWinningDigit(String periodKey) =>
    globalBattleDayMagic(periodKey, 'oracle_digit_v1').abs() % 10;

int parityDailyNumber(String periodKey) =>
    globalBattleDayMagic(periodKey, 'parity_n99_v1').abs() % 100;

class GlobalBattlesRepository {
  GlobalBattlesRepository({required SupabaseClient client}) : _c = client;

  final SupabaseClient _c;

  bool get isSignedIn => _c.auth.currentUser != null;

  static String utcPeriodKey() {
    return utcPeriodKeyForUtc(DateTime.now().toUtc());
  }

  /// Calendar day in UTC (matches [period_key] in Supabase).
  static String utcPeriodKeyForUtc(DateTime utc) {
    final n = DateTime.utc(utc.year, utc.month, utc.day);
    final y = n.year.toString().padLeft(4, '0');
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String utcYesterdayPeriodKey() {
    final y = DateTime.now().toUtc().subtract(const Duration(days: 1));
    return utcPeriodKeyForUtc(y);
  }

  String? get _uid => _c.auth.currentUser?.id;

  Future<List<GlobalBattleStanding>> fetchLeaderboard({
    required int battleId,
    required String periodKey,
    int limit = 25,
  }) async {
    final rows = await _c
        .from(GlobalBattleTable.name)
        .select(
          '${GlobalBattleTable.userId}, ${GlobalBattleTable.score}, '
          '${GlobalBattleTable.extras}, ${GlobalBattleTable.createdAt}, '
          'profiles!inner(username)',
        )
        .eq(GlobalBattleTable.battleId, battleId)
        .eq(GlobalBattleTable.periodKey, periodKey)
        .order(GlobalBattleTable.score, ascending: false)
        .order(GlobalBattleTable.createdAt, ascending: true)
        .limit(limit);

    final list = rows as List<dynamic>;
    return list.map((raw) {
      final e = Map<String, dynamic>.from(raw as Map);
      final prof = e['profiles'];
      var name = '';
      if (prof is Map) {
        name = (prof['username'] as String?)?.trim() ?? '';
      }
      if (name.isEmpty) name = 'Player';
      final ex = e[GlobalBattleTable.extras];
      return GlobalBattleStanding(
        userId: e[GlobalBattleTable.userId]?.toString() ?? '',
        username: name,
        score: _asInt(e[GlobalBattleTable.score]),
        extras: ex is Map ? Map<String, dynamic>.from(ex) : const {},
        createdAt: DateTime.tryParse(
          e[GlobalBattleTable.createdAt]?.toString() ?? '',
        )?.toUtc(),
      );
    }).toList(growable: false);
  }

  Future<GlobalBattleStanding?> fetchTopPlayer({
    required int battleId,
    required String periodKey,
  }) async {
    final list = await fetchLeaderboard(
      battleId: battleId,
      periodKey: periodKey,
      limit: 1,
    );
    if (list.isEmpty) return null;
    return list.first;
  }

  Future<GlobalBattleMyEntry?> fetchMyEntry({
    required int battleId,
    required String periodKey,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _c
        .from(GlobalBattleTable.name)
        .select(
          '${GlobalBattleTable.score}, ${GlobalBattleTable.extras}, '
          '${GlobalBattleTable.createdAt}',
        )
        .eq(GlobalBattleTable.battleId, battleId)
        .eq(GlobalBattleTable.periodKey, periodKey)
        .eq(GlobalBattleTable.userId, uid)
        .maybeSingle();
    if (row == null) return null;
    final e = Map<String, dynamic>.from(row);
    final ex = e[GlobalBattleTable.extras];
    return GlobalBattleMyEntry(
      score: _asInt(e[GlobalBattleTable.score]),
      extras: ex is Map ? Map<String, dynamic>.from(ex) : const {},
      createdAt: DateTime.tryParse(
        e[GlobalBattleTable.createdAt]?.toString() ?? '',
      )?.toUtc(),
    );
  }

  Future<String?> submitCosmicDice({
    required String periodKey,
    required int roll,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Sign in to play.';
    final r = roll.clamp(1, 999);
    try {
      await _c.from(GlobalBattleTable.name).insert({
        GlobalBattleTable.battleId: 1,
        GlobalBattleTable.periodKey: periodKey,
        GlobalBattleTable.userId: uid,
        GlobalBattleTable.score: r,
        GlobalBattleTable.extras: {'r': r},
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return 'You already rolled today.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  int reflexRankScore(int reactionMs) {
    final ms = reactionMs.clamp(0, 9999);
    return 10000 - ms;
  }

  Future<String?> submitReflex({
    required String periodKey,
    required int reactionMs,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Sign in to play.';
    final ms = reactionMs.clamp(1, 9999);
    final sc = reflexRankScore(ms);
    final row = {
      GlobalBattleTable.battleId: 2,
      GlobalBattleTable.periodKey: periodKey,
      GlobalBattleTable.userId: uid,
      GlobalBattleTable.score: sc,
      GlobalBattleTable.extras: {'ms': ms},
    };
    try {
      final prev = await fetchMyEntry(battleId: 2, periodKey: periodKey);
      if (prev != null) {
        final prevMs = _asInt(prev.extras['ms']);
        if (prevMs > 0 && ms >= prevMs) {
          return 'Not faster than your best today.';
        }
        await _c
            .from(GlobalBattleTable.name)
            .update({
              GlobalBattleTable.score: sc,
              GlobalBattleTable.extras: {'ms': ms},
              'updated_at': _nowIso(),
            })
            .eq(GlobalBattleTable.battleId, 2)
            .eq(GlobalBattleTable.periodKey, periodKey)
            .eq(GlobalBattleTable.userId, uid);
        return null;
      }
      await _c.from(GlobalBattleTable.name).insert(row);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> submitOracleDigit({
    required String periodKey,
    required int guess,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Sign in to play.';
    final g = guess.clamp(0, 9);
    final win = oracleWinningDigit(periodKey);
    final sc = g == win ? GlobalBattlesRepository.earlyRankBonus() : 0;
    try {
      await _c.from(GlobalBattleTable.name).insert({
        GlobalBattleTable.battleId: 3,
        GlobalBattleTable.periodKey: periodKey,
        GlobalBattleTable.userId: uid,
        GlobalBattleTable.score: sc,
        GlobalBattleTable.extras: {'g': g},
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return 'You already picked today.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> submitBlitzTaps({
    required String periodKey,
    required int taps,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Sign in to play.';
    final t = taps.clamp(0, 500);
    if (t <= 0) return 'Tap at least once.';
    final row = {
      GlobalBattleTable.battleId: 4,
      GlobalBattleTable.periodKey: periodKey,
      GlobalBattleTable.userId: uid,
      GlobalBattleTable.score: t,
      GlobalBattleTable.extras: {'taps': t},
    };
    try {
      final prev = await fetchMyEntry(battleId: 4, periodKey: periodKey);
      if (prev != null) {
        if (t <= prev.score) {
          return 'Beat your tap record to update the board.';
        }
        await _c
            .from(GlobalBattleTable.name)
            .update({
              GlobalBattleTable.score: t,
              GlobalBattleTable.extras: {'taps': t},
              'updated_at': _nowIso(),
            })
            .eq(GlobalBattleTable.battleId, 4)
            .eq(GlobalBattleTable.periodKey, periodKey)
            .eq(GlobalBattleTable.userId, uid);
        return null;
      }
      await _c.from(GlobalBattleTable.name).insert(row);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> submitParityPick({
    required String periodKey,
    required bool pickOdd,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Sign in to play.';
    final n = parityDailyNumber(periodKey);
    final nIsOdd = n.isOdd;
    final match = pickOdd == nIsOdd;
    final sc = match ? GlobalBattlesRepository.earlyRankBonus() : 0;
    try {
      await _c.from(GlobalBattleTable.name).insert({
        GlobalBattleTable.battleId: 5,
        GlobalBattleTable.periodKey: periodKey,
        GlobalBattleTable.userId: uid,
        GlobalBattleTable.score: sc,
        GlobalBattleTable.extras: {
          'pick': pickOdd ? 'odd' : 'even',
        },
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return 'You already picked today.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> submitHighLowPick({
    required String periodKey,
    required bool pickHigh,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Sign in to play.';
    final n = parityDailyNumber(periodKey);
    final nIsHigh = n >= 50;
    final match = pickHigh == nIsHigh;
    final sc = match ? GlobalBattlesRepository.earlyRankBonus() : 0;
    try {
      await _c.from(GlobalBattleTable.name).insert({
        GlobalBattleTable.battleId: 5,
        GlobalBattleTable.periodKey: periodKey,
        GlobalBattleTable.userId: uid,
        GlobalBattleTable.score: sc,
        GlobalBattleTable.extras: {
          'pick': pickHigh ? 'high' : 'low',
        },
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return 'You already picked today.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Higher = earlier same-day submission (tiebreaker among equal outcomes).
  static int earlyRankBonus() {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day);
    final ms = now.difference(start).inMilliseconds.clamp(0, 86400000);
    return 100000000 - ms;
  }

  static String _nowIso() => DateTime.now().toUtc().toIso8601String();
}
