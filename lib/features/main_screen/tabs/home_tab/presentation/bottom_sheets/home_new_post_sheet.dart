import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<void> showHomeNewPostSheet(
  BuildContext context, {
  required TextEditingController contentController,
  required Future<void> Function(
    String content,
    Uint8List? imageBytes,
    String? imageContentType,
    bool allowShare,
  ) onPublish,
}) {
  contentController.clear();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: _HomeNewPostSheetBody(
          contentController: contentController,
          onPublish: onPublish,
        ),
      );
    },
  );
}

class _HomeNewPostSheetBody extends StatefulWidget {
  const _HomeNewPostSheetBody({
    required this.contentController,
    required this.onPublish,
  });

  final TextEditingController contentController;
  final Future<void> Function(
    String content,
    Uint8List? imageBytes,
    String? imageContentType,
    bool allowShare,
  ) onPublish;

  @override
  State<_HomeNewPostSheetBody> createState() => _HomeNewPostSheetBodyState();
}

class _HomeNewPostSheetBodyState extends State<_HomeNewPostSheetBody> {
  Uint8List? _imageBytes;
  String? _imageContentType;
  bool _posting = false;
  bool _allowShare = true;

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
      _imageBytes = bytes;
      _imageContentType = _mimeFromFile(file);
    });
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imageContentType = null;
    });
  }

  Future<void> _submit() async {
    final text = widget.contentController.text;
    final trimmed = text.trim();
    if (trimmed.isEmpty && (_imageBytes == null || _imageBytes!.isEmpty)) {
      return;
    }
    setState(() => _posting = true);
    try {
      await widget.onPublish(
        trimmed,
        _imageBytes,
        _imageContentType,
        _allowShare,
      );
    } finally {
      if (mounted) setState(() => _posting = false);
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
          Text('New post', style: theme.textTheme.titleLarge),
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
                onPressed: _posting ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: const Text('Add photo'),
              ),
              if (_imageBytes != null)
                TextButton.icon(
                  onPressed: _posting ? null : _clearImage,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text('Remove photo'),
                ),
            ],
          ),
          if (_imageBytes != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _allowShare,
            onChanged: _posting
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
          FilledButton.icon(
            onPressed: _posting ? null : _submit,
            icon: _posting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 20),
            label: Text(_posting ? 'Posting…' : 'Post'),
          ),
        ],
      ),
    );
  }
}
