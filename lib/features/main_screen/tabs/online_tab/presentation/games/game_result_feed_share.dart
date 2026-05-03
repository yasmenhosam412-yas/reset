import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_usecase.dart';

/// Lets the player publish an editable recap to the home feed (same pipeline as Home → new post).
Future<void> showShareGameResultToFeedDialog(
  BuildContext context, {
  required String title,
  required String initialBody,
}) async {
  final controller = TextEditingController(text: initialBody);
  try {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Edit your post…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Post to feed'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final body = controller.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some text to post')),
      );
      return;
    }
    final r = await getIt<AddHomePostUsecase>()(postContent: body);
    if (!context.mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posted to your home feed')),
      ),
    );
  } finally {
    controller.dispose();
  }
}
