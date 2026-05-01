import 'dart:math';
import 'dart:typed_data';

import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_datasource.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/comment_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeDatasourceImpl implements HomeDatasource {
  HomeDatasourceImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  String get _postsSelect => '''
      ${PostCols.id},
      ${PostCols.userId},
      ${PostCols.postImage},
      ${PostCols.postContent},
      ${PostCols.likes},
      ${PostCols.createdAt},
      ${HomeTable.profiles}!inner(${ProfileCols.id}, ${ProfileCols.username}, ${ProfileCols.avatarUrl}),
      ${HomeTable.postComments}(
        ${PostCommentCols.id},
        ${PostCommentCols.comment},
        ${PostCommentCols.userId},
        ${HomeTable.profiles}!inner(${ProfileCols.id}, ${ProfileCols.username}, ${ProfileCols.avatarUrl})
      )
    ''';

  @override
  Future<void> addPost({
    required String postContent,
    String postImage = '',
    Uint8List? imageBytes,
    String? imageContentType,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Cannot create a post while signed out.');
    }
    var imageUrl = postImage;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      imageUrl = await _uploadPostImage(
        uid: uid,
        bytes: imageBytes,
        contentType: imageContentType ?? 'image/jpeg',
      );
    }
    await _client.from(HomeTable.posts).insert({
      PostCols.userId: uid,
      PostCols.postContent: postContent,
      PostCols.postImage: imageUrl,
      PostCols.likes: <String>[],
    });
  }

  Future<String> _uploadPostImage({
    required String uid,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ext = _fileExtensionForContentType(contentType);
    final path =
        '$uid/${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 20)}$ext';
    await _client.storage.from(HomeStorage.postImagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );
    return _client.storage.from(HomeStorage.postImagesBucket).getPublicUrl(path);
  }

  static String _fileExtensionForContentType(String contentType) {
    final ct = contentType.toLowerCase().split(';').first.trim();
    switch (ct) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      default:
        return '.jpg';
    }
  }

  @override
  Future<void> addComment({
    required String postId,
    required String comment,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Cannot add a comment while signed out.');
    }
    await _client.from(HomeTable.postComments).insert({
      PostCommentCols.postId: postId,
      PostCommentCols.userId: uid,
      PostCommentCols.comment: comment,
    });
  }

  @override
  Future<void> togglePostLike({required String postId}) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Cannot like a post while signed out.');
    }

    final row = await _client
        .from(HomeTable.posts)
        .select(PostCols.likes)
        .eq(PostCols.id, postId)
        .maybeSingle();

    if (row == null) {
      throw StateError('Post not found: $postId');
    }

    final likes = _parseLikesField(row[PostCols.likes]);
    if (likes.contains(uid)) {
      likes.remove(uid);
    } else {
      likes.add(uid);
    }
    await _client
        .from(HomeTable.posts)
        .update({PostCols.likes: likes})
        .eq(PostCols.id, postId);
  }

  @override
  Future<List<PostModel>> getPosts() async {
    final response = await _client
        .from(HomeTable.posts)
        .select(_postsSelect)
        .order(PostCols.createdAt, ascending: false);

    final rows = _asMapList(response);
    return rows.map(_mapPostRow).toList(growable: false);
  }

  PostModel _mapPostRow(Map<String, dynamic> row) {
    final author = _firstProfileMap(row);
    final authorId =
        author[ProfileCols.id]?.toString() ?? row[PostCols.userId]?.toString() ?? '';
    final user = _mergeSessionProfileIfNeeded(
      UserModel.fromJson({
        ProfileCols.id: authorId,
        ProfileCols.username: author[ProfileCols.username]?.toString() ?? '',
        ProfileCols.avatarUrl: author[ProfileCols.avatarUrl] as String?,
      }),
      authorId,
    );

    final comments = <CommentModel>[];
    final rawComments = row[HomeTable.postComments];
    if (rawComments is List) {
      for (final item in rawComments) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final cAuthor = _firstProfileMap(map);
        final commentAuthorId = cAuthor[ProfileCols.id]?.toString() ??
            map[PostCommentCols.userId]?.toString() ??
            '';
        comments.add(
          CommentModel(
            userModel: _mergeSessionProfileIfNeeded(
              UserModel.fromJson({
                ProfileCols.id: commentAuthorId,
                ProfileCols.username:
                    cAuthor[ProfileCols.username]?.toString() ?? '',
                ProfileCols.avatarUrl: cAuthor[ProfileCols.avatarUrl] as String?,
              }),
              commentAuthorId,
            ),
            comment: map[PostCommentCols.comment]?.toString() ??
                map['text']?.toString() ??
                '',
          ),
        );
      }
    }

    return PostModel(
      id: row[PostCols.id]?.toString() ?? '',
      userModel: user,
      postImage: row[PostCols.postImage]?.toString() ?? '',
      postContent: row[PostCols.postContent]?.toString() ?? '',
      likes: _parseLikesField(row[PostCols.likes]),
      comments: comments,
    );
  }

  Map<String, dynamic> _firstProfileMap(Map<String, dynamic> row) {
    Map<String, dynamic>? fromValue(dynamic p) {
      if (p is Map) return Map<String, dynamic>.from(p);
      if (p is List && p.isNotEmpty && p.first is Map) {
        return Map<String, dynamic>.from(p.first as Map);
      }
      return null;
    }

    final direct = fromValue(row[HomeTable.profiles]);
    if (direct != null) return direct;

    // PostgREST may use disambiguated keys (e.g. profiles!posts_user_id_fkey) when embedding.
    for (final entry in row.entries) {
      final key = entry.key;
      if (key == HomeTable.profiles) continue;
      if (key.startsWith('${HomeTable.profiles}!')) {
        final nested = fromValue(entry.value);
        if (nested != null) return nested;
      }
    }
    return {};
  }

  /// Fills missing display fields from [auth.currentUser] when the row is the signed-in user.
  UserModel _mergeSessionProfileIfNeeded(UserModel user, String authorId) {
    final sessionUid = _currentUserId;
    if (sessionUid == null || authorId != sessionUid) return user;

    final hasName = user.username.trim().isNotEmpty;
    final hasAvatar =
        user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;
    if (hasName && hasAvatar) return user;

    final sessionUser = _client.auth.currentUser;
    if (sessionUser == null) return user;

    final fromAuth = UserModel.fromSupabaseUser(sessionUser);
    final emailLocal =
        sessionUser.email?.split('@').first.trim() ?? '';

    return UserModel(
      id: user.id,
      username: hasName
          ? user.username
          : (fromAuth.username.trim().isNotEmpty
              ? fromAuth.username
              : (emailLocal.isNotEmpty ? emailLocal : 'User')),
      avatarUrl: hasAvatar
          ? user.avatarUrl
          : (fromAuth.avatarUrl != null && fromAuth.avatarUrl!.trim().isNotEmpty
              ? fromAuth.avatarUrl
              : null),
    );
  }

  List<String> _parseLikesField(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: true);
    }
    return <String>[];
  }

  List<Map<String, dynamic>> _asMapList(dynamic response) {
    if (response is! List) return const [];
    return response
        .map(
          (e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
        )
        .toList(growable: false);
  }
}
