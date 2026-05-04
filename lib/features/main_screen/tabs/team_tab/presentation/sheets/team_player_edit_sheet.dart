import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_player_edit_result.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/domain/models/team_roster_player.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/constants/team_stat_colors.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_ui_utils.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/widgets/team_stat_mini_bar.dart';

Future<TeamPlayerEditResult?> showTeamPlayerEditSheet(
  BuildContext context, {
  required int playerIndex,
  required TeamRosterPlayer player,
}) async {
  final nameCtrl = TextEditingController(text: player.name);
  var avatarB64 = player.avatarBase64;

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
                    'Edit player',
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Photo',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Builder(
                        builder: (_) {
                          final prov = _avatarProvider(avatarB64);
                          final rawName = nameCtrl.text.trim();
                          final letter = rawName.isNotEmpty
                              ? rawName[0].toUpperCase()
                              : (player.name.isNotEmpty
                                  ? player.name[0].toUpperCase()
                                  : '?');
                          return CircleAvatar(
                            radius: 36,
                            backgroundColor: scheme.surfaceContainerHighest,
                            backgroundImage: prov,
                            child: prov == null
                                ? Text(
                                    letter,
                                    style: Theme.of(ctx).textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                final x = await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 512,
                                  maxHeight: 512,
                                  imageQuality: 82,
                                );
                                if (x == null) return;
                                final bytes = await x.readAsBytes();
                                if (!ctx.mounted) return;
                                setModal(() {
                                  avatarB64 = base64Encode(bytes);
                                });
                              },
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Choose'),
                            ),
                            TextButton(
                              onPressed: avatarB64 == null
                                  ? null
                                  : () => setModal(() => avatarB64 = null),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    onChanged: (_) => setModal(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Stats (skill training only)',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Raise ATK, DEF, SPD, and STM from the training section above.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TeamStatMiniBar(
                        label: 'ATK',
                        value: player.attack,
                        accent: TeamStatColors.attack,
                      ),
                      const SizedBox(width: 3),
                      TeamStatMiniBar(
                        label: 'DEF',
                        value: player.defense,
                        accent: TeamStatColors.defense,
                      ),
                      const SizedBox(width: 3),
                      TeamStatMiniBar(
                        label: 'SPD',
                        value: player.speed,
                        accent: TeamStatColors.speed,
                      ),
                      const SizedBox(width: 3),
                      TeamStatMiniBar(
                        label: 'STM',
                        value: player.stamina,
                        accent: TeamStatColors.stamina,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                          avatarBase64: avatarB64,
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

ImageProvider? _avatarProvider(String? b64) {
  if (b64 == null || b64.isEmpty) return null;
  try {
    return MemoryImage(base64Decode(b64));
  } catch (_) {
    return null;
  }
}
