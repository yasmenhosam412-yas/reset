import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_types.dart';

/// Constants and pure rules for the penalty shootout mini-game.
abstract final class PenaltyShootoutRules {
  static const int secondsPerRound = 11;
  static const int totalRounds = 10;

  /// Drag norm outside ±this maps to side lanes in **classic 3** mode.
  static const double aimSideThreshold = 0.32;

  /// Local AI keeper: chance to read the shot and dive the same way.
  static const double aiKeeperReadShotChance = 0.36;

  /// Wide mode: boundaries on normalized drag [-1, 1] for five lanes.
  static const double fiveLaneOuter = 0.56;
  static const double fiveLaneInner = 0.2;

  /// Kick animation length (no shot-power variation).
  static const int kickAnimationDurationMs = 760;

  static bool uidEq(String? a, String? b) {
    if (a == null || b == null) return false;
    return a.toLowerCase().trim() == b.toLowerCase().trim();
  }

  static int dirToInt(PenaltyShootoutDir d) => switch (d) {
        PenaltyShootoutDir.farLeft => -2,
        PenaltyShootoutDir.left => -1,
        PenaltyShootoutDir.center => 0,
        PenaltyShootoutDir.right => 1,
        PenaltyShootoutDir.farRight => 2,
      };

  static PenaltyShootoutDir intToDir(int i) {
    if (i <= -2) return PenaltyShootoutDir.farLeft;
    if (i == -1) return PenaltyShootoutDir.left;
    if (i == 0) return PenaltyShootoutDir.center;
    if (i == 1) return PenaltyShootoutDir.right;
    return PenaltyShootoutDir.farRight;
  }

  /// Goal only when the keeper does **not** dive the shot lane (same lane = save).
  static bool computeScored(
    PenaltyShootoutDir shot,
    PenaltyShootoutDir dive,
  ) {
    return shot != dive;
  }

  static PenaltyShootoutDir normToDir(double n, {required PenaltyAimLanes lanes}) {
    if (lanes == PenaltyAimLanes.classic3) {
      if (n < -aimSideThreshold) return PenaltyShootoutDir.left;
      if (n > aimSideThreshold) return PenaltyShootoutDir.right;
      return PenaltyShootoutDir.center;
    }
    if (n < -fiveLaneOuter) return PenaltyShootoutDir.farLeft;
    if (n < -fiveLaneInner) return PenaltyShootoutDir.left;
    if (n <= fiveLaneInner) return PenaltyShootoutDir.center;
    if (n < fiveLaneOuter) return PenaltyShootoutDir.right;
    return PenaltyShootoutDir.farRight;
  }

  static String dirLabel(PenaltyShootoutDir d) => switch (d) {
        PenaltyShootoutDir.farLeft => 'Far left',
        PenaltyShootoutDir.left => 'Left',
        PenaltyShootoutDir.center => 'Center',
        PenaltyShootoutDir.right => 'Right',
        PenaltyShootoutDir.farRight => 'Far right',
      };
}
