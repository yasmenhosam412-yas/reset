import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/lineup_race_board_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/get_lineup_race_leaderboard_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/submit_lineup_race_entry_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_race_week.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Weekly races between **saved** lineups (same `profiles.team_squad` used for training).
class TeamLineupRacePanel extends StatefulWidget {
  const TeamLineupRacePanel({
    super.key,
    required this.hasSquad,
    this.ensureSquadSynced,
  });

  final bool hasSquad;

  /// Call before submit so the server reads an up-to-date squad.
  final Future<void> Function()? ensureSquadSynced;

  @override
  State<TeamLineupRacePanel> createState() => _TeamLineupRacePanelState();
}

class _TeamLineupRacePanelState extends State<TeamLineupRacePanel> {
  List<({String label, String subtitle, String Function(String) builder})>
  _modes(BuildContext context) {
    final l10n = context.l10n;
    return [
      (
        label: l10n.teamPowerRace,
        subtitle: l10n.teamRaceSubtitlePower,
        builder: lineupRaceKeyPower,
      ),
      (
        label: l10n.teamSpeedDash,
        subtitle: l10n.teamRaceSubtitleSpeed,
        builder: lineupRaceKeySpeed,
      ),
      (
        label: l10n.teamBalance,
        subtitle: l10n.teamRaceSubtitleBalance,
        builder: lineupRaceKeyBalance,
      ),
    ];
  }

  int _modeIndex = 0;
  List<LineupRaceBoardRow> _rows = const [];
  bool _loading = true;
  bool _submitting = false;

  String get _mondayId => lineupRaceMondayIdUtc();

  String get _raceKey => _modes(context)[_modeIndex].builder(_mondayId);

  String? get _myId =>
      Supabase.instance.client.auth.currentUser?.id.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadBoard());
  }

  Future<void> _reloadBoard() async {
    setState(() => _loading = true);
    final r = await getIt<GetLineupRaceLeaderboardUsecase>()(raceKey: _raceKey);
    if (!mounted) return;
    r.fold(
      (f) {
        setState(() {
          _loading = false;
          _rows = const [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        );
      },
      (rows) {
        setState(() {
          _loading = false;
          _rows = rows;
        });
      },
    );
  }

  Future<void> _submit() async {
    if (!widget.hasSquad || widget.ensureSquadSynced == null) return;
    setState(() => _submitting = true);
    await widget.ensureSquadSynced!();
    if (!mounted) return;
    final r = await getIt<SubmitLineupRaceEntryUsecase>()(_raceKey);
    if (!mounted) return;
    setState(() => _submitting = false);
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (score) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.lineupScored(score))),
        );
        _reloadBoard();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final modes = _modes(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.lineupRaces,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.refreshBoard,
                    onPressed: _loading ? null : _reloadBoard,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              Text(
                l10n.teamRaceWeekUtc(_mondayId),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(modes.length, (i) {
                  final sel = i == _modeIndex;
                  return ChoiceChip(
                    label: Text(modes[i].label),
                    selected: sel,
                    onSelected: _loading
                        ? null
                        : (v) {
                            if (!v) return;
                            setState(() => _modeIndex = i);
                            _reloadBoard();
                          },
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                modes[_modeIndex].subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: (!widget.hasSquad ||
                        widget.ensureSquadSynced == null ||
                        _submitting)
                    ? null
                    : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_rounded),
                label: Text(
                  widget.hasSquad
                      ? l10n.submitLineupToRace
                      : l10n.createTeamToEnter,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.leaderboard,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_rows.isEmpty)
                Text(
                  l10n.teamNoEntriesYetBeFirstThisWeek,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _rows.length.clamp(0, 25),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    final rank = index + 1;
                    final name =
                        (row.username?.trim().isNotEmpty ?? false)
                        ? row.username!.trim()
                        : l10n.player;
                    final me = _myId != null &&
                        row.userId.trim().toLowerCase() == _myId;
                    final avatarUrl = row.avatarUrl?.trim();
                    final hasAvatar =
                        avatarUrl != null && avatarUrl.isNotEmpty;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: homeFeedAvatarColor(name),
                        foregroundColor: Colors.white,
                        backgroundImage:
                            hasAvatar ? NetworkImage(avatarUrl) : null,
                        child: hasAvatar
                            ? null
                            : Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                      title: Text(
                        row.teamName.isNotEmpty ? row.teamName : name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: me ? scheme.primary : null,
                        ),
                      ),
                      subtitle: Text(
                        '${name.split(' ').first} · #${rank.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        '${row.score}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
