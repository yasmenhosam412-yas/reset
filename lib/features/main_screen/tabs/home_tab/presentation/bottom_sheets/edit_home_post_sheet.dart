import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_project/core/l10n/l10n.dart';
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
          child: _EditHomePostBody(
            hostContext: context,
            post: post,
            contentController: controller,
          ),
        );
      },
    );
  } finally {
    disposeTextControllerNextFrame(controller);
  }
}

class _EditHomePostBody extends StatefulWidget {
  const _EditHomePostBody({
    required this.hostContext,
    required this.post,
    required this.contentController,
  });

  final BuildContext hostContext;
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
  late String _postVisibility;
  late String _postType;
  late final TextEditingController _adLinkController;
  String? _contentError;
  String? _adLinkError;

  String get _existingUrl => homePostResolvedImageUrl(widget.post).trim();

  @override
  void initState() {
    super.initState();
    _allowShare = widget.post.allowShare;
    _postVisibility = widget.post.postVisibility;
    _postType = widget.post.postType;
    if (_postType == 'ads') {
      _allowShare = false;
    }
    _adLinkController = TextEditingController(text: widget.post.adLink ?? '');
  }

  @override
  void dispose() {
    _adLinkController.dispose();
    super.dispose();
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

  String? _normalizedAdLink() {
    final raw = _adLinkController.text.trim();
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return null;
    }
    return raw;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final merged = homePostMergeEditedBody(
      storedPostContent: widget.post.postContent,
      editedDisplayTrimmed: widget.contentController.text.trim(),
    );
    String? contentError;
    String? adLinkError;
    if (merged.isEmpty) {
      contentError = l10n.postTextEmptyError;
    }
    final adLink = _normalizedAdLink();
    if (_postType == 'ads' && adLink == null) {
      adLinkError = l10n.adLinkInvalidError;
    }
    if (contentError != null || adLinkError != null) {
      setState(() {
        _contentError = contentError;
        _adLinkError = adLinkError;
      });
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
              postVisibility: _postVisibility,
              postType: _postType,
              adLink: adLink,
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
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.editPost, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'post',
                icon: Icon(Icons.edit_note_rounded, size: 18),
                label: Text(l10n.postTypePost),
              ),
              ButtonSegment<String>(
                value: 'announcement',
                icon: Icon(Icons.campaign_outlined, size: 18),
                label: Text(l10n.postTypeAnnouncement),
              ),
              ButtonSegment<String>(
                value: 'celebration',
                icon: Icon(Icons.celebration_outlined, size: 18),
                label: Text(l10n.postTypeCelebration),
              ),
              ButtonSegment<String>(
                value: 'ads',
                icon: Icon(Icons.storefront_outlined, size: 18),
                label: Text(l10n.postTypeAds),
              ),
            ],
            selected: {_postType},
            onSelectionChanged: _saving
                ? null
                : (values) {
                    if (values.isEmpty) return;
                    setState(() {
                      _postType = values.first;
                      if (_postType == 'ads') {
                        _allowShare = false;
                      }
                    });
                  },
          ),
          const SizedBox(height: 8),
          if (_postType == 'ads') ...[
            TextField(
              controller: _adLinkController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              onChanged: (_) {
                if (_adLinkError != null) {
                  setState(() => _adLinkError = null);
                }
              },
              decoration: InputDecoration(
                labelText: l10n.adLink,
                hintText: l10n.adLinkHint,
                prefixIcon: const Icon(Icons.link_rounded),
                errorText: _adLinkError,
              ),
            ),
            const SizedBox(height: 8),
          ],
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'general',
                icon: Icon(Icons.public_rounded, size: 18),
                label: Text(l10n.general),
              ),
              ButtonSegment<String>(
                value: 'friends',
                icon: Icon(Icons.group_rounded, size: 18),
                label: Text(l10n.friendsOnly),
              ),
            ],
            selected: {_postVisibility},
            onSelectionChanged: _saving
                ? null
                : (values) {
                    if (values.isEmpty) return;
                    setState(() => _postVisibility = values.first);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.contentController,
            maxLines: 5,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_contentError != null) {
                setState(() => _contentError = null);
              }
            },
            decoration: InputDecoration(
              hintText: l10n.postContentHint,
              alignLabelWithHint: true,
              errorText: _contentError,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: Text(
                  _existingUrl.isNotEmpty ? l10n.changePhoto : l10n.addPhoto,
                ),
              ),
              if (_willHaveImage)
                TextButton.icon(
                  onPressed: _saving ? null : _removePhoto,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: Text(l10n.removePhoto),
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
            onChanged: _saving || _postType == 'ads'
                ? null
                : (v) => setState(() => _allowShare = v),
            title: Text(l10n.allowReposts),
            subtitle: Text(
              _postType == 'ads'
                  ? l10n.adsCannotRepost
                  : _allowShare
                  ? l10n.othersCanShare
                  : l10n.repostHidden,
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
            label: Text(_saving ? l10n.saving : l10n.save),
          ),
        ],
      ),
    );
  }
}
