import 'package:flutter/material.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Color homeFeedAvatarColor(String name) {
  final i = name.hashCode.abs() % Colors.primaries.length;
  return Colors.primaries[i];
}

bool homePostLikedByCurrentUser(PostModel post) {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return false;
  return post.likes.contains(uid);
}
