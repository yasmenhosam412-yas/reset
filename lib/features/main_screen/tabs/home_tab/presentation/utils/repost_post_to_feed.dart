import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/utils/dispose_text_controller_next_frame.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/add_home_post_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/shared_post_marker.dart';

/// Opens a dialog to publish an editable repost to the home feed (same as New post).
Future<void> showRepostPostToFeedDialog(
  BuildContext context, {
  required PostModel post,
}) async {
  if (homePostIsMine(post)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't repost your own post.")),
      );
    }
    return;
  }
  if (!post.allowShare) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This post cannot be reposted.'),
        ),
      );
    }
    return;
  }

  final author = post.userModel.username.trim().isEmpty
      ? 'Someone'
      : post.userModel.username.trim();
  final imageUrl = homePostResolvedImageUrl(post).trim();
  final initialCaption = homePostDisplayContent(post).trim();

  final controller = TextEditingController(text: initialCaption);
  try {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Repost to home feed'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'From $author',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Image is attached to this repost.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: controller,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment (optional)…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Publish repost'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    var body = controller.text.trim();
    final prefixLine = '$kSharedPostBodyPrefix$author';
    if (body.startsWith(prefixLine)) {
      body = body.substring(prefixLine.length).trimLeft();
    }
    body = body.isEmpty ? prefixLine : '$prefixLine\n\n$body';
    final r = await getIt<AddHomePostUsecase>()(
      postContent: body,
      postImage: imageUrl,
      allowShare: true,
    );
    if (!context.mounted) return;
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repost published')),
        );
        context.read<HomeBloc>().add(HomePostsRequested());
      },
    );
  } finally {
    disposeTextControllerNextFrame(controller);
  }
}
