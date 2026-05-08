import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/utils/dispose_text_controller_next_frame.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_usecase.dart';

/// Lets the player publish an editable recap to the home feed (same pipeline as Home → new post).
Future<void> showShareGameResultToFeedDialog(
  BuildContext context, {
  required String title,
  required String initialBody,
}) async {
  final l10n = context.l10n;
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
              decoration: InputDecoration(
                hintText: l10n.editYourPostHint,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.postToFeed),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final body = controller.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addSomeTextToPost)),
      );
      return;
    }
    final r = await getIt<AddHomePostUsecase>()(
      postContent: body,
      allowShare: true,
    );
    if (!context.mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postedToHomeFeed)),
      ),
    );
  } finally {
    disposeTextControllerNextFrame(controller);
  }
}
