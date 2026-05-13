import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_project/core/l10n/l10n.dart';

Future<void> showHomeNewPostSheet(
  BuildContext context, {
  required TextEditingController contentController,
  required Future<void> Function(
    String content,
    Uint8List? imageBytes,
    String? imageContentType,
    String? mediaLocalPath,
    bool allowShare,
    String postVisibility,
    String postType,
    String? adLink,
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
          hostContext: context,
          contentController: contentController,
          onPublish: onPublish,
        ),
      );
    },
  );
}

class _HomeNewPostSheetBody extends StatefulWidget {
  const _HomeNewPostSheetBody({
    required this.hostContext,
    required this.contentController,
    required this.onPublish,
  });

  final BuildContext hostContext;
  final TextEditingController contentController;
  final Future<void> Function(
    String content,
    Uint8List? imageBytes,
    String? imageContentType,
    String? mediaLocalPath,
    bool allowShare,
    String postVisibility,
    String postType,
    String? adLink,
  ) onPublish;

  @override
  State<_HomeNewPostSheetBody> createState() => _HomeNewPostSheetBodyState();
}

class _HomeNewPostSheetBodyState extends State<_HomeNewPostSheetBody> {
  Uint8List? _imageBytes;
  String? _imageContentType;
  String? _videoPath;
  String? _videoContentType;
  String _videoLabel = '';
  bool _posting = false;
  bool _allowShare = true;
  String _postVisibility = 'general';
  String _postType = 'post';
  final TextEditingController _adLinkController = TextEditingController();
  String? _contentError;
  String? _adLinkError;

  @override
  void dispose() {
    _adLinkController.dispose();
    super.dispose();
  }

  bool get _hasImage => _imageBytes != null && _imageBytes!.isNotEmpty;
  bool get _hasVideo =>
      _videoPath != null && _videoPath!.trim().isNotEmpty;

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

  String? _mimeFromImageFile(XFile file) {
    final fromPicker = file.mimeType;
    if (fromPicker != null && fromPicker.isNotEmpty) return fromPicker;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String? _mimeFromVideoFile(XFile file) {
    final fromPicker = file.mimeType;
    if (fromPicker != null && fromPicker.isNotEmpty) return fromPicker;
    final name = file.name.toLowerCase();
    if (name.endsWith('.webm')) return 'video/webm';
    if (name.endsWith('.mov')) return 'video/quicktime';
    if (name.endsWith('.mkv')) return 'video/x-matroska';
    return 'video/mp4';
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
      _imageContentType = _mimeFromImageFile(file);
      _videoPath = null;
      _videoContentType = null;
      _videoLabel = '';
    });
  }

  Future<void> _pickVideo() async {
    final l10n = context.l10n;
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (file == null || !mounted) return;
    setState(() {
      _imageBytes = null;
      _imageContentType = null;
      _videoPath = file.path;
      _videoContentType = _mimeFromVideoFile(file);
      _videoLabel = file.name.isNotEmpty ? file.name : l10n.addVideo;
    });
  }

  void _clearMedia() {
    setState(() {
      _imageBytes = null;
      _imageContentType = null;
      _videoPath = null;
      _videoContentType = null;
      _videoLabel = '';
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final text = widget.contentController.text;
    final trimmed = text.trim();
    String? contentError;
    String? adLinkError;
    final hasMedia = _hasImage || _hasVideo;

    if (_postType == 'ads') {
      if (trimmed.isEmpty) {
        contentError = l10n.postTextEmptyError;
      }
    } else if (trimmed.isEmpty && !hasMedia) {
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
    setState(() => _posting = true);
    try {
      Uint8List? outBytes = _imageBytes;
      String? outMime = _imageContentType;
      String? outPath;

      if (_hasVideo) {
        outMime = _videoContentType ?? 'video/mp4';
        if (kIsWeb) {
          final xf = XFile(_videoPath!);
          outBytes = await xf.readAsBytes();
          outPath = null;
        } else {
          outBytes = null;
          outPath = _videoPath;
        }
      }

      await widget.onPublish(
        trimmed,
        outBytes,
        outMime,
        outPath,
        _allowShare,
        _postVisibility,
        _postType,
        adLink,
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.9;

    return PopScope(
      canPop: !_posting,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.newPost, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              _postType == 'announcement'
                  ? l10n.postTypeDescriptionAnnouncement
                  : _postType == 'celebration'
                  ? l10n.postTypeDescriptionCelebration
                  : _postType == 'ads'
                  ? l10n.postTypeDescriptionAds
                  : l10n.postTypeDescriptionPost,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _PostTypeTile(
                  selected: _postType == 'post',
                  icon: Icons.edit_note_rounded,
                  label: l10n.postTypePost,
                  onTap: _posting
                      ? null
                      : () => setState(() {
                          _postType = 'post';
                        }),
                ),
                _PostTypeTile(
                  selected: _postType == 'announcement',
                  icon: Icons.campaign_outlined,
                  label: l10n.postTypeAnnouncement,
                  onTap: _posting
                      ? null
                      : () => setState(() {
                          _postType = 'announcement';
                        }),
                ),
                _PostTypeTile(
                  selected: _postType == 'celebration',
                  icon: Icons.celebration_outlined,
                  label: l10n.postTypeCelebration,
                  onTap: _posting
                      ? null
                      : () => setState(() {
                          _postType = 'celebration';
                        }),
                ),
                _PostTypeTile(
                  selected: _postType == 'ads',
                  icon: Icons.storefront_outlined,
                  label: l10n.postTypeAds,
                  onTap: _posting
                      ? null
                      : () => setState(() {
                          _postType = 'ads';
                          _allowShare = false;
                        }),
                ),
              ],
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
            Text(
              _postVisibility == 'friends'
                  ? l10n.friendsVisibilityHint
                  : l10n.generalVisibilityHint,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
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
              onSelectionChanged: _posting
                  ? null
                  : (values) {
                      if (values.isEmpty) return;
                      setState(() => _postVisibility = values.first);
                    },
            ),
            const SizedBox(height: 10),
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
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _posting ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: Text(l10n.addPhoto),
                ),
                TextButton.icon(
                  onPressed: _posting ? null : _pickVideo,
                  icon: const Icon(Icons.videocam_outlined, size: 20),
                  label: Text(l10n.addVideo),
                ),
                if (_hasImage || _hasVideo)
                  TextButton.icon(
                    onPressed: _posting ? null : _clearMedia,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    label: Text(l10n.removePhoto),
                  ),
              ],
            ),
            if (_hasImage) ...[
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
            if (_hasVideo) ...[
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.movie_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  _videoLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  l10n.addVideo,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _allowShare,
              onChanged: _posting || _postType == 'ads'
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
                    label: Text(_posting ? l10n.posting : l10n.post),
                  ),
                ],
              ),
            ),
          ),
          if (_posting)
            Positioned.fill(
              child: ColoredBox(
                color: theme.colorScheme.surface.withValues(alpha: 0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 14),
                      Text(
                        l10n.posting,
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostTypeTile extends StatelessWidget {
  const _PostTypeTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.8)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
