class TeamFormation {
  const TeamFormation({
    required this.id,
    required this.label,
    required this.rows,
  });

  final String id;
  final String label;

  /// Player counts per line from back to front. Must sum to [kTeamRosterSize].
  final List<int> rows;

  int get total => rows.fold(0, (a, b) => a + b);
}

const int kTeamRosterSize = 6;

/// Single pitch layout for every squad (no formation picker).
const TeamFormation kTeamFormationFixed = TeamFormation(
  id: '2-2-2',
  label: '2-2-2',
  rows: [2, 2, 2],
);

const List<TeamFormation> kTeamFormations = [kTeamFormationFixed];
