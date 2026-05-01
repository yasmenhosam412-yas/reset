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

const List<TeamFormation> kTeamFormations = [
  TeamFormation(id: '2-2-2', label: '2-2-2', rows: [2, 2, 2]),
  TeamFormation(id: '3-2-1', label: '3-2-1', rows: [3, 2, 1]),
  TeamFormation(id: '1-2-2-1', label: '1-2-2-1', rows: [1, 2, 2, 1]),
  TeamFormation(id: '1-3-2', label: '1-3-2', rows: [1, 3, 2]),
];
