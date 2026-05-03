import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_types.dart';

/// Constants and pure rules for the penalty shootout mini-game.
abstract final class PenaltyShootoutRules {
  static const int secondsPerRound = 11;
  static const int totalRounds = 10;
  /// Min shot power [0–1] to score when keeper dives the same way.
  static const double powerBlastThreshold = 0.78;
  /// Drag norm outside ±this maps to left/right; tighter = trickier center aim.
  static const double aimSideThreshold = 0.32;
  /// Local AI keeper: chance to read the shot and dive the same way (low power still saves).
  static const double aiKeeperReadShotChance = 0.36;

  static int get powerBlastPercentRounded =>
      (powerBlastThreshold * 100).round();

  static bool uidEq(String? a, String? b) {
    if (a == null || b == null) return false;
    return a.toLowerCase().trim() == b.toLowerCase().trim();
  }

  static int dirToInt(PenaltyShootoutDir d) => switch (d) {
        PenaltyShootoutDir.left => -1,
        PenaltyShootoutDir.center => 0,
        PenaltyShootoutDir.right => 1,
      };

  static PenaltyShootoutDir intToDir(int i) {
    if (i < 0) return PenaltyShootoutDir.left;
    if (i > 0) return PenaltyShootoutDir.right;
    return PenaltyShootoutDir.center;
  }

  static bool computeScored(
    PenaltyShootoutDir shot,
    PenaltyShootoutDir dive,
    double power,
  ) {
    if (shot != dive) return true;
    return power >= powerBlastThreshold;
  }

  static int kickDurationMs(double power) {
    return (920 * (1.05 - 0.42 * power.clamp(0.0, 1.0)))
        .round()
        .clamp(420, 1040);
  }

  static PenaltyShootoutDir normToDir(double n) {
    if (n < -aimSideThreshold) return PenaltyShootoutDir.left;
    if (n > aimSideThreshold) return PenaltyShootoutDir.right;
    return PenaltyShootoutDir.center;
  }

  static String dirLabel(PenaltyShootoutDir d) => switch (d) {
        PenaltyShootoutDir.left => 'Left',
        PenaltyShootoutDir.center => 'Center',
        PenaltyShootoutDir.right => 'Right',
      };
}
