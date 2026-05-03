import 'dart:async';

import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/data/team_squad_json_codec.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_formation.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_roster_player.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/claim_team_daily_challenge_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/get_team_cloud_progress_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/sync_team_squad_to_cloud_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/usecases/train_team_player_stat_usecase.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/dialogs/team_name_dialog.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_roster_defaults.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_slot_layout.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_daily_challenges_card.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_empty_squad_body.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_friends_duel_strip.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_lineup_race_panel.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_formation_pill.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_pitch_board.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_skill_training_strip.dart';
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

  bool _cloudReady = false;
  int _skillPoints = 0;
  final Set<String> _claimedChallengeKeys = {};
  String? _claimBusyKey;
  bool _trainingBusy = false;
  int _trainingSlot = 0;

  @override
  void initState() {
    super.initState();
    _players = defaultTeamRoster();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_loadCloudProgress()));
  }

  List<TeamRosterPlayer> _clonePlayers(List<TeamRosterPlayer> src) {
    return src
        .map(
          (e) => TeamRosterPlayer(
            name: e.name,
            attack: e.attack,
            defense: e.defense,
            speed: e.speed,
            stamina: e.stamina,
          ),
        )
        .toList(growable: false);
  }

  TeamFormation get _formation => kTeamFormations[_formationIndex];

  Future<void> _loadCloudProgress() async {
    final r = await getIt<GetTeamCloudProgressUsecase>()();
    if (!mounted) return;
    r.fold(
      (f) {
        setState(() {
          _cloudReady = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        );
      },
      (snap) {
        setState(() {
          _cloudReady = true;
          _skillPoints = snap.skillPoints;
          _claimedChallengeKeys
            ..clear()
            ..addAll(snap.claimedChallengeKeysToday);
          final stored = parseStoredTeamSquad(snap.squadJson);
          if (stored != null) {
            _teamName = stored.teamName;
            _formationIndex = stored.formationIndex;
            _players = _clonePlayers(stored.players);
          }
        });
      },
    );
  }

  Future<void> _syncSquadToCloud() async {
    if (_teamName == null || _teamName!.isEmpty) return;
    final json = encodeTeamSquadJson(
      teamName: _teamName!,
      formationIndex: _formationIndex,
      players: _players,
    );
    final r = await getIt<SyncTeamSquadToCloudUsecase>()(json);
    if (!mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save squad: ${f.message}')),
      ),
      (_) {},
    );
  }

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
    await _syncSquadToCloud();
    if (mounted) {
      await _loadCloudProgress();
    }
  }

  Future<void> _onClaimChallenge(String key) async {
    setState(() => _claimBusyKey = key);
    final r = await getIt<ClaimTeamDailyChallengeUsecase>()(key);
    if (!mounted) return;
    setState(() => _claimBusyKey = null);
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (ok) {
        setState(() {
          _skillPoints = ok.balanceAfter;
          _claimedChallengeKeys.add(key);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '+${ok.pointsAwarded} pts · balance ${ok.balanceAfter}',
            ),
          ),
        );
      },
    );
  }

  Future<void> _onTrainStat(String statKey) async {
    setState(() => _trainingBusy = true);
    final r = await getIt<TrainTeamPlayerStatUsecase>()(
      playerSlot: _trainingSlot.clamp(0, 5),
      statKey: statKey,
    );
    if (!mounted) return;
    setState(() => _trainingBusy = false);
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (ok) {
        setState(() {
          _skillPoints = ok.balanceAfter;
          final stored = parseStoredTeamSquad(ok.squadJson);
          if (stored != null) {
            _players = _clonePlayers(stored.players);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player trained (+1 stat).')),
        );
      },
    );
  }

  Widget _challengesCard() {
    return TeamDailyChallengesCard(
      claimedKeysToday: _claimedChallengeKeys,
      onClaim: (k) => unawaited(_onClaimChallenge(k)),
      claimBusyKey: _claimBusyKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!_cloudReady) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_teamName == null) {
      return Scaffold(
        body: SafeArea(
          child: TeamEmptySquadBody(
            onCreateTeam: _openCreateTeam,
            challengesFooter: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _challengesCard(),
                const TeamLineupRacePanel(
                  hasSquad: false,
                  ensureSquadSynced: null,
                ),
              ],
            ),
          ),
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
                skillPoints: _skillPoints,
                onTeamRenamed: (next) {
                  setState(() => _teamName = next);
                  unawaited(_syncSquadToCloud());
                },
              ),
            ),
            SliverToBoxAdapter(child: _challengesCard()),
            SliverToBoxAdapter(
              child: TeamSkillTrainingStrip(
                players: _players,
                skillPoints: _skillPoints,
                selectedSlot: _trainingSlot,
                busy: _trainingBusy,
                onSlotChanged: (i) => setState(() => _trainingSlot = i),
                onTrain: (k) => unawaited(_onTrainStat(k)),
              ),
            ),
            SliverToBoxAdapter(
              child: TeamLineupRacePanel(
                hasSquad: true,
                ensureSquadSynced: _syncSquadToCloud,
              ),
            ),
            SliverToBoxAdapter(
              child: TeamFriendsDuelStrip(teamName: _teamName!),
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
                      onTap: () {
                        setState(() => _formationIndex = i);
                        unawaited(_syncSquadToCloud());
                      },
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
                      Icons.sports_soccer_outlined,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Formation board is view-only. Use skill training below to raise stats.',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
