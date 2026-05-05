/// Stored in [likes] jsonb: plain `userId` means "like", or `userId|reaction_key`.
const Set<String> kPostReactionKeys = {
  'like',
  'love',
  'laugh',
  'wow',
  'sad',
  'care',
};

String postReactionEntryUserId(String entry) {
  final e = entry.trim();
  final i = e.indexOf('|');
  if (i < 0) return e;
  return e.substring(0, i).trim();
}

String postReactionEntryType(String entry) {
  final e = entry.trim();
  final i = e.indexOf('|');
  if (i < 0) return 'like';
  final t = e.substring(i + 1).trim().toLowerCase();
  return kPostReactionKeys.contains(t) ? t : 'like';
}

String encodePostReactionEntry(String userId, String reactionKey) {
  final uid = userId.trim();
  final k = reactionKey.trim().toLowerCase();
  if (uid.isEmpty) return '';
  if (k == 'like' || !kPostReactionKeys.contains(k)) {
    return uid;
  }
  return '$uid|$k';
}

/// Normalizes API json (strings or maps) into wire strings for [PostModel.likes].
List<String> normalizeLikesJson(dynamic raw) {
  if (raw is! List) return const [];
  final out = <String>[];
  for (final e in raw) {
    if (e is String) {
      final s = e.trim();
      if (s.isNotEmpty) out.add(s);
    } else if (e is Map) {
      final m = Map<String, dynamic>.from(e);
      final u = m['u'] ?? m['user_id'];
      final t = (m['t'] ?? m['reaction'] ?? 'like').toString();
      if (u != null && u.toString().trim().isNotEmpty) {
        out.add(encodePostReactionEntry(u.toString(), t));
      }
    }
  }
  return out;
}
