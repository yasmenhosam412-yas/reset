import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';

/// First line prefix for posts created with “Share to home feed” / repost.
const String kSharedPostBodyPrefix = '🔁 Shared from ';

/// First “shared from …” line in stored content, if any.
String? homePostSharedAttributionLine(String postContent) {
  for (final line in postContent.split('\n')) {
    final t = line.trimLeft();
    if (t.startsWith(kSharedPostBodyPrefix)) return t;
  }
  return null;
}

/// Re-attach shared attribution after editing the display-only caption.
String homePostMergeEditedBody({
  required String storedPostContent,
  required String editedDisplayTrimmed,
}) {
  final attr = homePostSharedAttributionLine(storedPostContent);
  if (attr == null) return editedDisplayTrimmed;
  if (editedDisplayTrimmed.isEmpty) return attr;
  return '$attr\n\n$editedDisplayTrimmed';
}

/// True if any line opens with the shared marker (handles leading blank lines or edits
/// that left the marker on a later line).
bool homePostIsSharedRepost(PostModel post) {
  for (final line in post.postContent.split('\n')) {
    if (line.trimLeft().startsWith(kSharedPostBodyPrefix)) return true;
  }
  return false;
}

bool _isBareHttpUrl(String s) {
  final t = s.trim();
  if (t.length < 8) return false;
  if (!t.startsWith('http://') && !t.startsWith('https://')) return false;
  if (t.contains(' ') || t.contains('\n')) return false;
  final uri = Uri.tryParse(t);
  return uri != null && uri.hasScheme && uri.host.isNotEmpty;
}

bool _likelyPostImageUrl(String url) {
  final lower = url.toLowerCase();
  if (RegExp(r'\.(jpg|jpeg|png|gif|webp|avif)($|\?)').hasMatch(lower)) {
    return true;
  }
  if (lower.contains('supabase') &&
      (lower.contains('/storage/') || lower.contains('/object/'))) {
    return true;
  }
  return false;
}

/// Uses [PostModel.postImage] when set; for shared posts only, falls back to a lone
/// image-like URL line in the body (older reposts stored the URL in text).
String homePostResolvedImageUrl(PostModel post) {
  final fromCol = post.postImage.trim();
  if (fromCol.isNotEmpty) return fromCol;
  if (!homePostIsSharedRepost(post)) return '';

  final lines = post.postContent.split('\n');
  for (var i = lines.length - 1; i >= 0; i--) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    if (_isBareHttpUrl(line) && _likelyPostImageUrl(line)) return line;
  }
  return '';
}

/// Feed body: hides the stored “Shared from …” line (badge shows that) and any lone
/// image URL line already rendered as [PostModel.postImage].
String homePostDisplayContent(PostModel post) {
  if (!homePostIsSharedRepost(post)) return post.postContent;

  final imageUrl = homePostResolvedImageUrl(post);
  final stripUrls = <String>{};
  if (imageUrl.isNotEmpty) stripUrls.add(imageUrl);
  final col = post.postImage.trim();
  if (col.isNotEmpty) stripUrls.add(col);

  final out = <String>[];
  for (final line in post.postContent.split('\n')) {
    final trimmed = line.trim();
    if (line.trimLeft().startsWith(kSharedPostBodyPrefix)) continue;
    if (stripUrls.contains(trimmed)) continue;
    out.add(line);
  }
  return out.join('\n').trim();
}
