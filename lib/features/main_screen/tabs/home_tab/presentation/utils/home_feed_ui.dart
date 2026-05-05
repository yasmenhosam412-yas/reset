import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/post_reactions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Color homeFeedAvatarColor(String name) {
  final i = name.hashCode.abs() % Colors.primaries.length;
  return Colors.primaries[i];
}

bool homePostLikedByCurrentUser(PostModel post) =>
    homePostReactedByCurrentUser(post);

/// True when the author row can open the actions sheet (signed in + known author id).
/// Same user still gets the sheet so they can delete their own post.
bool homePostAuthorActionsAvailable(PostModel post) {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return false;
  return post.userModel.id.trim().isNotEmpty;
}

bool homePostIsMine(PostModel post) {
  final myId =
      Supabase.instance.client.auth.currentUser?.id.trim().toLowerCase();
  final aid = post.userModel.id.trim().toLowerCase();
  return myId != null && myId.isNotEmpty && myId == aid;
}

/// True when the repost action should appear for this post.
bool homePostRepostAllowed(PostModel post) {
  if (homePostIsMine(post)) return false;
  return post.allowShare;
}

/// Short relative label, e.g. `5m ago`, `2h ago`, `3d ago`.
String homeFeedTimeAgo(DateTime? at, {DateTime? clock}) {
  if (at == null) return '';
  final now = clock ?? DateTime.now();
  var delta = now.difference(at);
  if (delta.isNegative) {
    delta = Duration.zero;
  }
  if (delta.inSeconds < 45) return 'just now';
  if (delta.inMinutes < 60) {
    final m = delta.inMinutes;
    return '${m}m ago';
  }
  if (delta.inHours < 24) {
    final h = delta.inHours;
    return '${h}h ago';
  }
  if (delta.inDays < 7) {
    final d = delta.inDays;
    return '${d}d ago';
  }
  final w = delta.inDays ~/ 7;
  if (w < 5) return '${w}w ago';
  final mo = delta.inDays ~/ 30;
  if (mo < 12) return '${mo}mo ago';
  final y = delta.inDays ~/ 365;
  return '${y}y ago';
}
