import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/get_online_challenges_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/get_online_friends_usecase.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_titles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// All online challenges the signed-in user is part of, with status and outcome.
class ProfileOnlineChallengesScreen extends StatefulWidget {
  const ProfileOnlineChallengesScreen({super.key});

  @override
  State<ProfileOnlineChallengesScreen> createState() =>
      _ProfileOnlineChallengesScreenState();
}

class _ProfileOnlineChallengesScreenState
    extends State<ProfileOnlineChallengesScreen> {
  List<ChallengeRequestModel> _challenges = const [];
  List<UserModel> _friends = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final friendsResult = await getIt<GetOnlineFriendsUsecase>()();
    final challengesResult = await getIt<GetOnlineChallengesUsecase>()();

    if (!mounted) return;

    final friends = friendsResult.fold((_) => <UserModel>[], (l) => l);

    challengesResult.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
        _friends = friends;
        _challenges = const [];
      }),
      (challenges) => setState(() {
        _loading = false;
        _error = null;
        _friends = friends;
        _challenges = _sortChallengesForDisplay(challenges);
      }),
    );
  }

  /// Surface finished matches (win / loss / draw) first.
  static List<ChallengeRequestModel> _sortChallengesForDisplay(
    List<ChallengeRequestModel> raw,
  ) {
    int bucket(String status) {
      switch (status.toLowerCase()) {
        case 'completed':
          return 0;
        case 'accepted':
          return 1;
        case 'pending':
          return 2;
        default:
          return 3;
      }
    }

    final copy = List<ChallengeRequestModel>.from(raw);
    copy.sort((a, b) {
      final d = bucket(a.status).compareTo(bucket(b.status));
      if (d != 0) return d;
      final ta = a.completedAt ?? a.createdAt;
      final tb = b.completedAt ?? b.createdAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return copy;
  }

  static String _opponentName(
    ChallengeRequestModel c,
    String? uid,
    List<UserModel> friends,
    String unknownOpponentLabel,
    String fallbackPlayerLabel,
  ) {
    if (uid == null || uid.isEmpty) return unknownOpponentLabel;
    final oid = c.fromId == uid ? c.toId : c.fromId;
    for (final f in friends) {
      if (f.id == oid) {
        final n = f.username.trim();
        return n.isEmpty ? fallbackPlayerLabel : n;
      }
    }
    if (oid.length <= 12) return oid;
    return '${oid.substring(0, 10)}…';
  }



  static String? _resultSubtitle(
    String? uid,
    ChallengeRequestModel c, {
    required String drawLabel,
    required String youWonLabel,
    required String youLostLabel,
  }) {
    final st = c.status.toLowerCase();
    final w = c.winnerUserId?.trim();
    final winnerKnown = w != null && w.isNotEmpty;
    final finished = st == 'completed' || c.completedAt != null || winnerKnown;
    if (!finished) return null;
    if (w == null || w.isEmpty) {
      return drawLabel;
    }
    final me = uid?.trim().toLowerCase();
    final winner = w.toLowerCase();
    if (me != null && me.isNotEmpty && winner == me) {
      return youWonLabel;
    }
    if (me != null && me.isNotEmpty && winner != me) {
      return youLostLabel;
    }
    return drawLabel;
  }

  static IconData _gameIcon(int gameId) {
    switch (gameId) {
      case 1:
        return Icons.sports_soccer_rounded;
      case 2:
        return Icons.back_hand_rounded;
      case 3:
        return Icons.style_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  static Color _gameIconTint(ColorScheme scheme, int gameId) {
    switch (gameId) {
      case 1:
        return scheme.primary;
      case 2:
        return scheme.secondary;
      case 3:
        return scheme.tertiary;
      default:
        return scheme.primary;
    }
  }

  static _OutcomeStyle? _outcomeStyle(
    ColorScheme scheme,
    String? uid,
    ChallengeRequestModel c,
    BuildContext context,
  ) {
    final l10n = context.l10n;
    final label = _resultSubtitle(
      uid,
      c,
      drawLabel: l10n.draw,
      youWonLabel: l10n.youWon,
      youLostLabel: l10n.youLost,
    );
    if (label == null) return null;
    if (label == l10n.youWon) {
      return _OutcomeStyle(
        label: label,
        icon: Icons.emoji_events_rounded,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      );
    }
    if (label == l10n.youLost) {
      return _OutcomeStyle(
        label: label,
        icon: Icons.flag_rounded,
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      );
    }
    return _OutcomeStyle(
      label: label,
      icon: Icons.balance_rounded,
      background: scheme.surfaceContainerHighest,
      foreground: scheme.onSurfaceVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final uid = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.challenges,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              l10n.historyAndLiveInvites,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          edgeOffset: 8,
          child: _loading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.loadingYourMatches,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : _error != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 56,
                      color: scheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.couldNotLoadChallenges,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.error,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.tryAgain),
                    ),
                  ],
                )
              : _challenges.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 56, 28, 100),
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer.withValues(alpha: 0.35),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Icon(
                          Icons.sports_esports_rounded,
                          size: 40,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.noChallengesYet,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.challengesEmptyHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: _challenges.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final c = _challenges[index];
                    final gameTitle = onlineGameTitleL10n(l10n, c.gameId);
                    final opp = _opponentName(
                      c,
                      uid,
                      _friends,
                      l10n.opponent,
                      l10n.player,
                    );
                    // final st = c.status;
                    // final stColor = _statusColor(scheme, st);
                    final when = c.completedAt ?? c.createdAt;
                    final timeLabel = when != null ? homeFeedTimeAgo(when) : '';
                    final outcome = _outcomeStyle(scheme, uid, c, context);
                    final iconTint = _gameIconTint(scheme, c.gameId);

                    return Material(
                      color: scheme.surfaceContainerLow,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: iconTint.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  _gameIcon(c.gameId),
                                  size: 26,
                                  color: iconTint,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          gameTitle,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.2,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 18,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                  height: 1.25,
                                                ),
                                            children: [
                                              TextSpan(text: l10n.vsPrefix),
                                              TextSpan(
                                                text: opp,
                                                style: TextStyle(
                                                  color: scheme.onSurface,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (timeLabel.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 15,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeLabel,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (outcome != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: outcome.background,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            outcome.icon,
                                            size: 18,
                                            color: outcome.foreground,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              outcome.label,
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    color: outcome.foreground,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _OutcomeStyle {
  const _OutcomeStyle({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
}
