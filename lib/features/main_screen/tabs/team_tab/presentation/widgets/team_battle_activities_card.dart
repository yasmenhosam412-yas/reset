import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_challenge_results.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_state.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/claim_team_academy_scrim_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/claim_team_squad_spar_usecase.dart';

Color _battleAvatarColor(String name) {
  final i = name.hashCode.abs() % Colors.primaries.length;
  return Colors.primaries[i];
}

String _prettyStatKey(String k, BuildContext context) {
  final l10n = context.l10n;
  switch (k) {
    case 'attack':
      return l10n.teamAttackShort;
    case 'defense':
      return l10n.teamDefenseShort;
    case 'speed':
      return 'SPD';
    case 'stamina':
      return 'STM';
    default:
      return k.toUpperCase();
  }
}

String _statDeltaLine(
  TeamSquadSparStatDelta d, {
  required bool gain,
  required BuildContext context,
}) {
  final l10n = context.l10n;
  final arrow = gain ? '↑' : '↓';
  return l10n.teamBattleStatDelta(
    d.slotIndex + 1,
    _prettyStatKey(d.statKey, context),
    arrow,
    d.before,
    d.after,
  );
}

/// Skill-point battles: async squad spar vs friends + pointer to realtime Online duels.
class TeamBattleActivitiesCard extends StatefulWidget {
  const TeamBattleActivitiesCard({
    super.key,
    required this.hasSquad,
    this.ensureSquadSynced,
    required this.onSparBalanceUpdated,
    this.onSparSquadUpdated,
  });

  final bool hasSquad;

  /// Ensures the server reads your latest squad before spar scoring.
  final Future<void> Function()? ensureSquadSynced;

  final ValueChanged<int> onSparBalanceUpdated;

  /// Called when spar updates roster stats on the server (win/loss swings).
  final ValueChanged<Map<String, dynamic>>? onSparSquadUpdated;

  @override
  State<TeamBattleActivitiesCard> createState() =>
      _TeamBattleActivitiesCardState();
}

class _TeamBattleActivitiesCardState extends State<TeamBattleActivitiesCard> {
  String? _busyFriendId;
  bool _academyScrimBusy = false;

  Future<void> _playAcademyScrim(BuildContext context) async {
    final l10n = context.l10n;
    if (!widget.hasSquad || widget.ensureSquadSynced == null) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teamBattleAcademyFriendly),
        content: SingleChildScrollView(
          child: Text(l10n.teamBattleAcademyDialogBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.teamBattleNotNow),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.teamBattleKickOff),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;

    setState(() => _academyScrimBusy = true);
    await widget.ensureSquadSynced!();
    if (!context.mounted) return;

    final r = await getIt<ClaimTeamAcademyScrimUsecase>()();
    if (!mounted) return;
    setState(() => _academyScrimBusy = false);

    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (ok) {
        widget.onSparBalanceUpdated(ok.balanceAfter);
        unawaited(HapticFeedback.mediumImpact());
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _AcademyScrimRevealDialog(result: ok),
        );
      },
    );
  }

  Future<void> _sparWithFriend(BuildContext context, UserModel friend) async {
    final l10n = context.l10n;
    if (!widget.hasSquad || widget.ensureSquadSynced == null) return;
    final name = friend.username.trim().isEmpty
        ? l10n.teamBattleThisFriend
        : friend.username;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teamBattleSquadSpar),
        content: SingleChildScrollView(
          child: Text(l10n.teamBattleSquadSparDialogBody(name)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.battle),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;

    setState(() => _busyFriendId = friend.id);
    await widget.ensureSquadSynced!();
    if (!context.mounted) return;

    final r = await getIt<ClaimTeamSquadSparUsecase>()(friend.id);
    if (!mounted) return;
    setState(() => _busyFriendId = null);

    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (ok) {
        widget.onSparBalanceUpdated(ok.balanceAfter);
        if (ok.squadJson != null) {
          widget.onSparSquadUpdated?.call(ok.squadJson!);
        }

        final lines = <String>[];
        switch (ok.outcome) {
          case 'win':
            lines.add(
              l10n.teamBattleVictory(
                ok.myScore,
                ok.opponentScore,
                ok.pointsAwarded,
              ),
            );
            if (ok.statBonus != null) {
              lines.add(
                _statDeltaLine(ok.statBonus!, gain: true, context: context),
              );
            }
          case 'lose':
            lines.add(l10n.teamBattleDefeat(ok.myScore, ok.opponentScore));
            if (ok.statPenalty != null) {
              lines.add(
                _statDeltaLine(ok.statPenalty!, gain: false, context: context),
              );
            }
          case 'tie':
            lines.add(
              l10n.teamBattleDraw(
                ok.myScore,
                ok.opponentScore,
                ok.pointsAwarded,
              ),
            );
          default:
            lines.add(l10n.teamBattleSparSettled(ok.balanceAfter));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lines.join('\n')),
            duration: const Duration(seconds: 5),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.errorContainer.withValues(alpha: 0.28),
              scheme.primaryContainer.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_moon_outlined, color: scheme.error, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.teamBattleBattlesForSkillPoints,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.teamBattleHeaderSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.teamRefreshFriends,
                    onPressed: () => context.read<OnlineBloc>().add(
                          OnlineLoadRequested(),
                        ),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StakesChip(
                    scheme: scheme,
                    theme: theme,
                    icon: Icons.trending_up_rounded,
                    label: l10n.teamBattleChipWin,
                    color: scheme.primary,
                  ),
                  _StakesChip(
                    scheme: scheme,
                    theme: theme,
                    icon: Icons.balance_rounded,
                    label: l10n.teamBattleChipTie,
                    color: scheme.tertiary,
                  ),
                  _StakesChip(
                    scheme: scheme,
                    theme: theme,
                    icon: Icons.trending_down_rounded,
                    label: l10n.teamBattleChipLoss,
                    color: scheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    color: scheme.tertiary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.teamBattleAcademyFriendly,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.teamBattleAcademySubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StakesChip(
                    scheme: scheme,
                    theme: theme,
                    icon: Icons.sentiment_satisfied_rounded,
                    label: l10n.teamBattleChipNoStatRisk,
                    color: scheme.tertiary,
                  ),
                  _StakesChip(
                    scheme: scheme,
                    theme: theme,
                    icon: Icons.today_rounded,
                    label: l10n.teamBattleChipDailyOnce,
                    color: scheme.primary,
                  ),
                  _StakesChip(
                    scheme: scheme,
                    theme: theme,
                    icon: Icons.stars_rounded,
                    label: l10n.teamBattleChipAlwaysPts,
                    color: scheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      scheme.tertiaryContainer.withValues(alpha: 0.85),
                      scheme.primaryContainer.withValues(alpha: 0.65),
                    ],
                  ),
                  border: Border.all(
                    color: scheme.tertiary.withValues(alpha: 0.35),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: widget.hasSquad &&
                            widget.ensureSquadSynced != null &&
                            !_academyScrimBusy
                        ? () => unawaited(_playAcademyScrim(context))
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_soccer_rounded,
                            color: scheme.onTertiaryContainer,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.teamBattleKickOffAcademy,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: scheme.onTertiaryContainer,
                                  ),
                                ),
                                Text(
                                  l10n.teamBattleTapAnimatedScoreboard,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onTertiaryContainer
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_academyScrimBusy)
                            const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.play_circle_fill_rounded,
                              color: scheme.onTertiaryContainer,
                              size: 36,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.teamBattleSquadSparFriends,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              BlocBuilder<OnlineBloc, OnlineState>(
                buildWhen: (prev, curr) =>
                    prev.friends != curr.friends || prev.status != curr.status,
                builder: (context, state) {
                  final loading = state.status == OnlineStatus.loading &&
                      state.friends.isEmpty;
                  if (loading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  if (state.friends.isEmpty) {
                    return Text(
                      l10n.teamBattleAddFriendsHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    );
                  }
                  return SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.friends.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final f = state.friends[index];
                        final busy = _busyFriendId == f.id;
                        final canTap = widget.hasSquad &&
                            widget.ensureSquadSynced != null &&
                            !busy;
                        return _SparFriendChip(
                          friend: f,
                          scheme: scheme,
                          theme: theme,
                          enabled: canTap,
                          busy: busy,
                          onTap: canTap
                              ? () => unawaited(_sparWithFriend(context, f))
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: scheme.outline.withValues(alpha: 0.15)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.videogame_asset_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.teamBattleLiveDuels,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.teamBattleLiveDuelsSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StakesChip extends StatelessWidget {
  const _StakesChip({
    required this.scheme,
    required this.theme,
    required this.icon,
    required this.label,
    required this.color,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: scheme.surface.withValues(alpha: 0.75),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _SparFriendChip extends StatelessWidget {
  const _SparFriendChip({
    required this.friend,
    required this.scheme,
    required this.theme,
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final UserModel friend;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool enabled;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = friend.username.trim().isEmpty ? l10n.player : friend.username;
    final avatarUrl = friend.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return SizedBox(
      width: 92,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _battleAvatarColor(label),
                      foregroundColor: Colors.white,
                      backgroundImage:
                          hasAvatar ? NetworkImage(avatarUrl) : null,
                      child: hasAvatar
                          ? null
                          : Text(
                              label.isNotEmpty ? label[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                    ),
                    if (busy)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.battle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: enabled ? scheme.error : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AcademyScrimRevealDialog extends StatefulWidget {
  const _AcademyScrimRevealDialog({required this.result});

  final TeamAcademyScrimResult result;

  @override
  State<_AcademyScrimRevealDialog> createState() =>
      _AcademyScrimRevealDialogState();
}

class _AcademyScrimRevealDialogState extends State<_AcademyScrimRevealDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _you;
  late final Animation<double> _them;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    final r = widget.result;
    _you = Tween<double>(begin: 0, end: r.myScore.toDouble()).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.52, curve: Curves.easeOutCubic),
      ),
    );
    _them = Tween<double>(begin: 0, end: r.opponentScore.toDouble()).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 1, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _outcomeLine(BuildContext context) {
    final l10n = context.l10n;
    final r = widget.result;
    switch (r.outcome) {
      case 'win':
        return l10n.teamBattleOutcomeWin;
      case 'lose':
        return l10n.teamBattleOutcomeLose;
      case 'tie':
        return l10n.teamBattleOutcomeTie;
      default:
        return l10n.teamBattleOutcomeComplete;
    }
  }

  Color _outcomeColor(ColorScheme scheme) {
    switch (widget.result.outcome) {
      case 'win':
        return scheme.primary;
      case 'tie':
        return scheme.tertiary;
      default:
        return scheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = widget.result;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final showOutcome = _controller.value >= 0.92;
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.teamBattleAcademyFriendly,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.teamBattleYouVs(r.opponentName),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l10n.teamBattleYourSquad,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _you.value.round().toString(),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Text(
                        '–',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w200,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l10n.teamBattleTheirPower,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _them.value.round().toString(),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.tertiary,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AnimatedOpacity(
                  opacity: showOutcome ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    children: [
                      Text(
                        _outcomeLine(context),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _outcomeColor(scheme),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.teamBattlePointsBalance(
                          r.pointsAwarded,
                          r.balanceAfter,
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.nice),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
