import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_formation.dart';

/// Maps each pitch row to global slot indices (0 … rosterSize − 1).
List<List<int>> slotRowsForFormation(TeamFormation formation) {
  var start = 0;
  return formation.rows.map((count) {
    final row = List.generate(count, (i) => start + i);
    start += count;
    return row;
  }).toList();
}
