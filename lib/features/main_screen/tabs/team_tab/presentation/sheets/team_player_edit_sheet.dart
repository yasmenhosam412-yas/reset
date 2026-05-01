import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_player_edit_result.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_roster_player.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/constants/team_stat_colors.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_ui_utils.dart';

Future<TeamPlayerEditResult?> showTeamPlayerEditSheet(
  BuildContext context, {
  required int playerIndex,
  required TeamRosterPlayer player,
}) async {
  final nameCtrl = TextEditingController(text: player.name);
  var atk = player.attack;
  var def = player.defense;
  var spd = player.speed;
  var stm = player.stamina;

  final result = await showModalBottomSheet<TeamPlayerEditResult?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
      final scheme = Theme.of(ctx).colorScheme;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: StatefulBuilder(
          builder: (context, setModal) {
            Widget statRow(
              String label,
              int value,
              Color accent,
              void Function(double) onChanged,
            ) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(label, style: Theme.of(ctx).textTheme.titleSmall),
                      const Spacer(),
                      Text(
                        '$value',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: accent,
                      thumbColor: accent,
                      overlayColor: accent.withValues(alpha: 0.12),
                      inactiveTrackColor: scheme.surfaceContainerHighest,
                    ),
                    child: Slider(
                      value: value.toDouble(),
                      min: 40,
                      max: 99,
                      divisions: 59,
                      label: '$value',
                      onChanged: (v) {
                        onChanged(v);
                        setModal(() {});
                      },
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Player ${playerIndex + 1} of 6',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Edit roster',
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  statRow(
                    'Attack',
                    atk,
                    TeamStatColors.attack,
                    (v) => atk = v.round(),
                  ),
                  statRow(
                    'Defense',
                    def,
                    TeamStatColors.defense,
                    (v) => def = v.round(),
                  ),
                  statRow(
                    'Speed',
                    spd,
                    TeamStatColors.speed,
                    (v) => spd = v.round(),
                  ),
                  statRow(
                    'Stamina',
                    stm,
                    TeamStatColors.stamina,
                    (v) => stm = v.round(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final n = nameCtrl.text.trim();
                      if (n.isEmpty) return;
                      Navigator.pop(
                        ctx,
                        TeamPlayerEditResult(
                          name: n,
                          attack: atk,
                          defense: def,
                          speed: spd,
                          stamina: stm,
                        ),
                      );
                    },
                    child: const Text('Save changes'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
  disposeTextControllerNextFrame(nameCtrl);
  return result;
}
