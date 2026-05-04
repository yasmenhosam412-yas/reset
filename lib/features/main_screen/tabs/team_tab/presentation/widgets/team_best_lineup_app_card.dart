import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/lineup_race_board_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/get_lineup_race_leaderboard_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_race_week.dart';

/// #1 Power lineup race entry for the current UTC week (global / same board for everyone).
class TeamBestLineupInAppCard extends StatefulWidget {
  const TeamBestLineupInAppCard({super.key});

  @override
  State<TeamBestLineupInAppCard> createState() => _TeamBestLineupInAppCardState();
}

class _TeamBestLineupInAppCardState extends State<TeamBestLineupInAppCard> {
  List<LineupRaceBoardRow> _rows = const [];
  bool _loading = true;
  String? _error;

  String get _raceKey => lineupRaceKeyPower(lineupRaceMondayIdUtc());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<GetLineupRaceLeaderboardUsecase>()(raceKey: _raceKey);
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
        _rows = const [];
      }),
      (rows) => setState(() {
        _loading = false;
        _rows = rows;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final monday = lineupRaceMondayIdUtc();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.emoji_events_rounded, color: scheme.secondary, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Best lineup in the app',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Top Power score this UTC week ($monday). Same rules as Lineup races — train, submit, climb.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loading ? null : _reload,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading && _error == null && _rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_error != null)
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                )
              else if (!_loading && _rows.isEmpty)
                Text(
                  'No submissions yet — be first on the board.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else if (_rows.isNotEmpty)
                _TopLineupTile(row: _rows.first, theme: theme, scheme: scheme),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopLineupTile extends StatelessWidget {
  const _TopLineupTile({
    required this.row,
    required this.theme,
    required this.scheme,
  });

  final LineupRaceBoardRow row;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final name = (row.username?.trim().isNotEmpty ?? false)
        ? row.username!.trim()
        : 'Player';
    final team = row.teamName.trim().isNotEmpty ? row.teamName : name;
    final avatarUrl = row.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Material(
      color: scheme.surface.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: homeFeedAvatarColor(name),
              foregroundColor: Colors.white,
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
              child: hasAvatar
                  ? null
                  : Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${name.split(' ').first} · rank #1 · Power race',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${row.score}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
