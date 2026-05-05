import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_project/core/utils/dispose_text_controller_next_frame.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/shared_post_marker.dart';

Future<void> showEditHomePostSheet(BuildContext context, PostModel post) async {
  final pid = post.id.trim();
  if (pid.isEmpty) return;

  final controller = TextEditingController(
    text: homePostDisplayContent(post).trim(),
  );
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: _EditHomePostBody(post: post, contentController: controller),
        );
      },
    );
  } finally {
    disposeTextControllerNextFrame(controller);
  }
}

class _EditHomePostBody extends StatefulWidget {
  const _EditHomePostBody({
    required this.post,
    required this.contentController,
  });

  final PostModel post;
  final TextEditingController contentController;

  @override
  State<_EditHomePostBody> createState() => _EditHomePostBodyState();
}

class _EditHomePostBodyState extends State<_EditHomePostBody> {
  Uint8List? _newImageBytes;
  String? _newImageContentType;
  bool _removedImage = false;
  bool _saving = false;
  late bool _allowShare;

  String get _existingUrl => homePostResolvedImageUrl(widget.post).trim();

  @override
  void initState() {
    super.initState();
    _allowShare = widget.post.allowShare;
  }

  String? _mimeFromFile(XFile file) {
    final fromPicker = file.mimeType;
    if (fromPicker != null && fromPicker.isNotEmpty) return fromPicker;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _newImageBytes = bytes;
      _newImageContentType = _mimeFromFile(file);
      _removedImage = false;
    });
  }

  void _removePhoto() {
    setState(() {
      _newImageBytes = null;
      _newImageContentType = null;
      _removedImage = true;
    });
  }

  bool get _willHaveImage {
    if (_newImageBytes != null && _newImageBytes!.isNotEmpty) return true;
    if (!_removedImage && _existingUrl.isNotEmpty) return true;
    return false;
  }

  Future<void> _save() async {
    final merged = homePostMergeEditedBody(
      storedPostContent: widget.post.postContent,
      editedDisplayTrimmed: widget.contentController.text.trim(),
    );
    if (merged.isEmpty && !_willHaveImage) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text or a photo')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final clearImage =
          _removedImage && (_newImageBytes == null || _newImageBytes!.isEmpty);
      context.read<HomeBloc>().add(
            HomePostUpdateRequested(
              postId: widget.post.id.trim(),
              postContent: merged,
              imageBytes: _newImageBytes,
              imageContentType: _newImageContentType,
              clearImage: clearImage,
              allowShare: _allowShare,
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit post', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: widget.contentController,
            maxLines: 5,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What is on your mind?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: Text(_existingUrl.isNotEmpty ? 'Change photo' : 'Add photo'),
              ),
              if (_willHaveImage)
                TextButton.icon(
                  onPressed: _saving ? null : _removePhoto,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text('Remove photo'),
                ),
            ],
          ),
          if (_newImageBytes != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(
                  _newImageBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ] else if (!_removedImage && _existingUrl.isNotEmpty) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  _existingUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _allowShare,
            onChanged: _saving
                ? null
                : (v) => setState(() => _allowShare = v),
            title: const Text('Allow reposts'),
            subtitle: Text(
              _allowShare
                  ? 'Others can share this to the home feed.'
                  : 'Repost is hidden for this post.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    );
  }
}
