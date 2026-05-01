import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_formation.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_roster_player.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/dialogs/team_name_dialog.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/sheets/team_player_edit_sheet.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_roster_defaults.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_slot_layout.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_empty_squad_body.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_formation_pill.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_pitch_board.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_squad_header.dart';

class TeamTab extends StatefulWidget {
  const TeamTab({super.key});

  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  String? _teamName;
  int _formationIndex = 0;
  late List<TeamRosterPlayer> _players;

  @override
  void initState() {
    super.initState();
    _players = defaultTeamRoster();
  }

  TeamFormation get _formation => kTeamFormations[_formationIndex];

  Future<void> _openCreateTeam() async {
    final name = await showTeamNameDialog(
      context,
      title: 'Create team',
      hintText: 'e.g. Night Owls',
      confirmButtonLabel: 'Create',
    );
    if (!mounted || name == null || name.isEmpty) return;
    setState(() {
      _teamName = name;
      _players = defaultTeamRoster();
      _formationIndex = 0;
    });
  }

  Future<void> _openEditPlayer(int index) async {
    final p = _players[index];
    final result = await showTeamPlayerEditSheet(
      context,
      playerIndex: index,
      player: p,
    );
    if (!mounted || result == null) return;
    setState(() {
      p.name = result.name;
      p.attack = result.attack;
      p.defense = result.defense;
      p.speed = result.speed;
      p.stamina = result.stamina;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_teamName == null) {
      return Scaffold(
        body: SafeArea(
          child: TeamEmptySquadBody(onCreateTeam: _openCreateTeam),
        ),
      );
    }

    assert(
      _formation.total == kTeamRosterSize && _players.length == kTeamRosterSize,
    );

    final slotRows = slotRowsForFormation(_formation);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TeamSquadHeader(
                teamName: _teamName!,
                formationLabel: _formation.label,
                onTeamRenamed: (next) => setState(() => _teamName = next),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(Icons.map_outlined, size: 22, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Formation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: List.generate(kTeamFormations.length, (i) {
                    final f = kTeamFormations[i];
                    return TeamFormationPill(
                      label: f.label,
                      selected: i == _formationIndex,
                      onTap: () => setState(() => _formationIndex = i),
                    );
                  }),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Board is interactive — tap a player card to edit.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverToBoxAdapter(
                child: TeamPitchBoard(
                  formationLabel: _formation.label,
                  slotRows: slotRows,
                  players: _players,
                  onPlayerTap: _openEditPlayer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
