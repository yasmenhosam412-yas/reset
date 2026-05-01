import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/team_tab/presentation/utils/team_ui_utils.dart';

Future<String?> showTeamNameDialog(
  BuildContext context, {
  required String title,
  String? hintText,
  String? labelText,
  String? initialValue,
  IconData icon = Icons.shield_moon_outlined,
  String confirmButtonLabel = 'Save',
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        icon: Icon(icon, color: scheme.primary, size: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: labelText ?? 'Team name',
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(confirmButtonLabel),
          ),
        ],
      );
    },
  );
  disposeTextControllerNextFrame(controller);
  return result;
}
