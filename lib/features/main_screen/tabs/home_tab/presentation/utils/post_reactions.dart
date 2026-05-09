import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/post_reactions_codec.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:new_project/features/main_screen/tabs/home_tab/data/post_reactions_codec.dart'
    show kPostReactionKeys;

/// Order used when sorting tied reaction counts (same as picker).
const List<String> kPostReactionDisplayOrder = [
  'like',
  'love',
  'laugh',
  'wow',
  'sad',
  'care',
];

/// Counts per reaction type (skips malformed empty entries).
Map<String, int> postReactionCounts(PostModel post) {
  final m = <String, int>{};
  for (final e in post.likes) {
    final id = postReactionEntryUserId(e);
    if (id.isEmpty) continue;
    final t = postReactionEntryType(e);
    m[t] = (m[t] ?? 0) + 1;
  }
  return m;
}

/// Non-zero counts, sorted by count desc then [kPostReactionDisplayOrder].
List<MapEntry<String, int>> postReactionCountsSorted(PostModel post) {
  final list = postReactionCounts(post).entries.where((e) => e.value > 0).toList();
  int orderIndex(String k) {
    final i = kPostReactionDisplayOrder.indexOf(k);
    return i < 0 ? 99 : i;
  }

  list.sort((a, b) {
    final c = b.value.compareTo(a.value);
    if (c != 0) return c;
    return orderIndex(a.key).compareTo(orderIndex(b.key));
  });
  return list;
}

/// Current user's reaction key, or `null` if they did not react.
String? homePostMyReaction(PostModel post) {
  final raw = Supabase.instance.client.auth.currentUser?.id;
  if (raw == null) return null;
  final uid = raw.trim().toLowerCase();
  if (uid.isEmpty) return null;
  for (final e in post.likes) {
    if (postReactionEntryUserId(e).trim().toLowerCase() == uid) {
      return postReactionEntryType(e);
    }
  }
  return null;
}

/// True if the user has any reaction (including legacy like).
bool homePostReactedByCurrentUser(PostModel post) =>
    homePostMyReaction(post) != null;

IconData postReactionIcon(String key) {
  switch (key) {
    case 'love':
      return Icons.favorite_rounded;
    case 'laugh':
      return Icons.sentiment_very_satisfied_rounded;
    case 'wow':
      return Icons.auto_awesome_rounded;
    case 'sad':
      return Icons.sentiment_dissatisfied_rounded;
    case 'care':
      return Icons.volunteer_activism_rounded;
    case 'like':
    default:
      return Icons.thumb_up_rounded;
  }
}

Color postReactionColor(String key, ColorScheme scheme) {
  switch (key) {
    case 'love':
      return scheme.error;
    case 'laugh':
      return scheme.tertiary;
    case 'wow':
      return scheme.secondary;
    case 'sad':
      return scheme.outline;
    case 'care':
      return scheme.primary;
    case 'like':
    default:
      return scheme.primary;
  }
}

String postReactionLabel(String key) {
  switch (key) {
    case 'love':
      return 'Love';
    case 'laugh':
      return 'Haha';
    case 'wow':
      return 'Wow';
    case 'sad':
      return 'Sad';
    case 'care':
      return 'Care';
    case 'like':
    default:
      return 'Like';
  }
}

String postReactionLabelL10n(AppLocalizations l10n, String key) {
  switch (key) {
    case 'love':
      return l10n.reactionLove;
    case 'laugh':
      return l10n.reactionHaha;
    case 'wow':
      return l10n.reactionWow;
    case 'sad':
      return l10n.reactionSad;
    case 'care':
      return l10n.reactionCare;
    case 'like':
    default:
      return l10n.reactionLike;
  }
}
