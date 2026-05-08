import 'dart:math';
import 'dart:typed_data';

import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_datasource.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/datasource/home_supabase_tables.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/post_reactions_codec.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/comment_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/people_discovery_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/user_feed_notification_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/lineup_race_board_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/team_cloud_snapshot.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeDatasourceImpl implements HomeDatasource {
  HomeDatasourceImpl({required SupabaseClient supabaseClient})
    : _client = supabaseClient;

  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  String get _postsSelect =>
      '''
      ${PostCols.id},
      ${PostCols.userId},
      ${PostCols.postImage},
      ${PostCols.postContent},
      ${PostCols.likes},
      ${PostCols.allowShare},
      ${PostCols.postVisibility},
      ${PostCols.postType},
      ${PostCols.adLink},
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
    bool allowShare = true,
    String postVisibility = 'general',
    String postType = 'post',
    String? adLink,
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
    final normalizedType = _normalizePostType(postType);
    final normalizedAdLink = _normalizeAdLink(adLink);
    final effectiveAllowShare = normalizedType == 'ads' ? false : allowShare;
    if (normalizedType == 'ads' && normalizedAdLink == null) {
      throw ArgumentError('Ads posts require a valid ad link.');
    }
    await _client.from(HomeTable.posts).insert({
      PostCols.userId: uid,
      PostCols.postContent: postContent,
      PostCols.postImage: imageUrl,
      PostCols.likes: <String>[],
      PostCols.allowShare: effectiveAllowShare,
      PostCols.postVisibility: _normalizePostVisibility(postVisibility),
      PostCols.postType: normalizedType,
      PostCols.adLink: normalizedAdLink,
    });
  }

  @override
  Future<void> deleteOwnPost({required String postId}) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Cannot delete a post while signed out.');
    }
    final id = postId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(postId, 'postId', 'must not be empty');
    }

    final row = await _client
        .from(HomeTable.posts)
        .select(PostCols.postImage)
        .eq(PostCols.id, id)
        .eq(PostCols.userId, uid)
        .maybeSingle();

    if (row == null) {
      throw StateError('Post not found or you cannot delete it.');
    }

    final imageUrl = row[PostCols.postImage]?.toString() ?? '';

    await _client
        .from(HomeTable.posts)
        .delete()
        .eq(PostCols.id, id)
        .eq(PostCols.userId, uid);

    await _removePostImageByPublicUrl(imageUrl);
  }

  @override
  Future<void> updateOwnPost({
    required String postId,
    required String postContent,
    Uint8List? imageBytes,
    String? imageContentType,
    bool clearImage = false,
    required bool allowShare,
    String postVisibility = 'general',
    String postType = 'post',
    String? adLink,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Cannot update a post while signed out.');
    }
    final id = postId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(postId, 'postId', 'must not be empty');
    }

    final row = await _client
        .from(HomeTable.posts)
        .select(PostCols.postImage)
        .eq(PostCols.id, id)
        .eq(PostCols.userId, uid)
        .maybeSingle();

    if (row == null) {
      throw StateError('Post not found or you cannot edit it.');
    }

    var imageUrl = row[PostCols.postImage]?.toString() ?? '';
    final previousStored = imageUrl;
    final normalizedType = _normalizePostType(postType);
    final normalizedVisibility = _normalizePostVisibility(postVisibility);
    final normalizedAdLink = _normalizeAdLink(adLink);
    final effectiveAllowShare = normalizedType == 'ads' ? false : allowShare;
    if (normalizedType == 'ads' && normalizedAdLink == null) {
      throw ArgumentError('Ads posts require a valid ad link.');
    }

    if (clearImage) {
      if (imageUrl.isNotEmpty) {
        await _removePostImageByPublicUrl(imageUrl);
      }
      imageUrl = '';
    } else if (imageBytes != null && imageBytes.isNotEmpty) {
      final uploaded = await _uploadPostImage(
        uid: uid,
        bytes: imageBytes,
        contentType: imageContentType ?? 'image/jpeg',
      );
      if (previousStored.isNotEmpty && previousStored != uploaded) {
        await _removePostImageByPublicUrl(previousStored);
      }
      imageUrl = uploaded;
    }

    await _client
        .from(HomeTable.posts)
        .update({
          PostCols.postContent: postContent,
          PostCols.postImage: imageUrl,
          PostCols.allowShare: effectiveAllowShare,
          PostCols.postVisibility: normalizedVisibility,
          PostCols.postType: normalizedType,
          PostCols.adLink: normalizedAdLink,
        })
        .eq(PostCols.id, id)
        .eq(PostCols.userId, uid);
  }

  Future<void> _removePostImageByPublicUrl(String imageUrl) async {
    final t = imageUrl.trim();
    if (t.isEmpty) return;
    final bucket = HomeStorage.postImagesBucket;
    final marker = '/object/public/$bucket/';
    final i = t.indexOf(marker);
    if (i < 0) return;
    final path = Uri.decodeFull(t.substring(i + marker.length));
    if (path.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (_) {}
  }

  Future<String> _uploadPostImage({
    required String uid,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ext = _fileExtensionForContentType(contentType);
    final path =
        '$uid/${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 20)}$ext';
    await _client.storage
        .from(HomeStorage.postImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return _client.storage
        .from(HomeStorage.postImagesBucket)
        .getPublicUrl(path);
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
  Future<void> setPostReaction({
    required String postId,
    String? reaction,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Cannot react to a post while signed out.');
    }

    final r = reaction?.trim().toLowerCase();
    if (r != null && r.isNotEmpty) {
      if (!kPostReactionKeys.contains(r)) {
        throw ArgumentError.value(reaction, 'reaction', 'unknown reaction');
      }
    }

    // Use atomic SQL function (row lock) so concurrent reactions from different
    // users do not overwrite each other.
    await _client.rpc(
      'set_post_reaction',
      params: {'p_post_id': postId, 'p_reaction': r},
    );
  }

  @override
  Future<List<PostModel>> getPosts({
    required int limit,
    required int offset,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      return const [];
    }

    final friendIds = await _acceptedFriendIdSet(uid);
    final to = offset + limit - 1;

    final response = await _client
        .from(HomeTable.posts)
        .select(_postsSelect)
        .range(offset, to)
        .order(PostCols.createdAt, ascending: false);

    final rows = _asMapList(response);
    return rows
        .map(_mapPostRow)
        .where((post) {
          if (post.postVisibility != 'friends') return true;
          final authorId = post.userModel.id.trim();
          if (authorId == uid) return true;
          return friendIds.contains(authorId);
        })
        .toList(growable: false);
  }

  @override
  Future<List<PeopleDiscoveryRow>> searchPeopleDiscovery(
    String rawQuery,
  ) async {
    final uid = _currentUserId;
    if (uid == null) return const [];

    final q = rawQuery.trim();
    if (q.length < 2) return const [];

    final safe = q.replaceAll('%', '').replaceAll('_', '');
    if (safe.length < 2) return const [];

    final profilesRaw = await _client
        .from(HomeTable.profiles)
        .select(
          '${ProfileCols.id}, ${ProfileCols.username}, ${ProfileCols.avatarUrl}',
        )
        .ilike(ProfileCols.username, '%$safe%')
        .neq(ProfileCols.id, uid)
        .limit(40);

    final profileRows = _asMapList(profilesRaw);
    if (profileRows.isEmpty) return const [];

    final users = profileRows
        .map(UserModel.fromJson)
        .where((u) => u.id.trim().isNotEmpty)
        .toList(growable: false);

    final idList = users.map((u) => u.id.trim()).toList();
    if (idList.isEmpty) return const [];

    final outgoingRaw = await _client
        .from(HomeTable.friendRequests)
        .select('${FriendRequestCols.toUserId}, ${FriendRequestCols.status}')
        .eq(FriendRequestCols.fromUserId, uid)
        .inFilter(FriendRequestCols.toUserId, idList);

    final incomingRaw = await _client
        .from(HomeTable.friendRequests)
        .select('${FriendRequestCols.fromUserId}, ${FriendRequestCols.status}')
        .eq(FriendRequestCols.toUserId, uid)
        .inFilter(FriendRequestCols.fromUserId, idList);

    final linkById = <String, PeopleDiscoveryLink>{
      for (final id in idList) id: PeopleDiscoveryLink.none,
    };

    for (final m in _asMapList(outgoingRaw)) {
      final tid = m[FriendRequestCols.toUserId]?.toString().trim() ?? '';
      if (tid.isEmpty) continue;
      final st = (m[FriendRequestCols.status]?.toString() ?? '')
          .toLowerCase()
          .trim();
      if (st == FriendRequestStatus.accepted) {
        linkById[tid] = PeopleDiscoveryLink.friend;
      } else if (st == FriendRequestStatus.pending) {
        linkById[tid] = PeopleDiscoveryLink.pendingOutgoing;
      }
    }

    for (final m in _asMapList(incomingRaw)) {
      final fid = m[FriendRequestCols.fromUserId]?.toString().trim() ?? '';
      if (fid.isEmpty) continue;
      final st = (m[FriendRequestCols.status]?.toString() ?? '')
          .toLowerCase()
          .trim();
      if (st == FriendRequestStatus.accepted) {
        linkById[fid] = PeopleDiscoveryLink.friend;
      } else if (st == FriendRequestStatus.pending) {
        linkById[fid] = PeopleDiscoveryLink.pendingIncoming;
      }
    }

    final out = <PeopleDiscoveryRow>[
      for (final u in users)
        PeopleDiscoveryRow(
          user: _mergeSessionProfileIfNeeded(u, u.id.trim()),
          link: linkById[u.id.trim()] ?? PeopleDiscoveryLink.none,
        ),
    ];

    out.sort(
      (a, b) => a.user.username.toLowerCase().compareTo(
        b.user.username.toLowerCase(),
      ),
    );
    return out;
  }

  PostModel _mapPostRow(Map<String, dynamic> row) {
    final author = _firstProfileMap(row);
    final authorId =
        author[ProfileCols.id]?.toString() ??
        row[PostCols.userId]?.toString() ??
        '';
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
        final commentAuthorId =
            cAuthor[ProfileCols.id]?.toString() ??
            map[PostCommentCols.userId]?.toString() ??
            '';
        comments.add(
          CommentModel(
            userModel: _mergeSessionProfileIfNeeded(
              UserModel.fromJson({
                ProfileCols.id: commentAuthorId,
                ProfileCols.username:
                    cAuthor[ProfileCols.username]?.toString() ?? '',
                ProfileCols.avatarUrl:
                    cAuthor[ProfileCols.avatarUrl] as String?,
              }),
              commentAuthorId,
            ),
            comment:
                map[PostCommentCols.comment]?.toString() ??
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
      createdAt: _parsePostCreatedAt(row[PostCols.createdAt]),
      allowShare: _parseAllowShareColumn(row[PostCols.allowShare]),
      postVisibility: _normalizePostVisibility(row[PostCols.postVisibility]),
      postType: _normalizePostType(row[PostCols.postType]),
      adLink: _normalizeAdLink(row[PostCols.adLink]),
    );
  }

  static String _normalizePostVisibility(dynamic raw) {
    final v = (raw?.toString() ?? '').trim().toLowerCase();
    if (v == 'friends') return 'friends';
    return 'general';
  }

  static String _normalizePostType(dynamic raw) {
    final v = (raw?.toString() ?? '').trim().toLowerCase();
    switch (v) {
      case 'announcement':
      case 'celebration':
      case 'ads':
        return v;
      default:
        return 'post';
    }
  }

  static String? _normalizeAdLink(dynamic raw) {
    final t = (raw?.toString() ?? '').trim();
    if (t.isEmpty) return null;
    final uri = Uri.tryParse(t);
    if (uri == null) return null;
    if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return null;
    }
    return t;
  }

  static bool _parseAllowShareColumn(dynamic raw) {
    if (raw == null) return true;
    if (raw is bool) return raw;
    if (raw is String) {
      final s = raw.toLowerCase();
      return s == 'true' || s == 't' || s == '1';
    }
    return true;
  }

  static DateTime? _parsePostCreatedAt(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
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
    final emailLocal = sessionUser.email?.split('@').first.trim() ?? '';

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

  List<String> _parseLikesField(dynamic raw) =>
      List<String>.from(normalizeLikesJson(raw), growable: true);

  List<Map<String, dynamic>> _asMapList(dynamic response) {
    if (response is! List) return const [];
    return response
        .map(
          (e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
        )
        .toList(growable: false);
  }

  ({String from, String to}) _resolveOutgoingPair(UserModel userModel) {
    final from = _currentUserId;
    if (from == null) {
      throw StateError('Cannot send request while signed out.');
    }
    final to = userModel.id.trim();
    if (to.isEmpty) {
      throw StateError('Cannot send request: missing user id.');
    }
    if (to == from) {
      throw StateError('Cannot send request to yourself.');
    }
    return (from: from, to: to);
  }

  bool _isUniqueViolation(PostgrestException e) {
    final code = e.code;
    if (code == '23505') return true;
    final msg = '${e.message} ${e.details}'.toLowerCase();
    return msg.contains('duplicate') || msg.contains('unique');
  }

  @override
  Future<void> sendFriendRequest(UserModel userModel) async {
    final pair = _resolveOutgoingPair(userModel);
    try {
      await _client.from(HomeTable.friendRequests).insert({
        FriendRequestCols.fromUserId: pair.from,
        FriendRequestCols.toUserId: pair.to,
        FriendRequestCols.status: FriendRequestStatus.pending,
      });
    } on PostgrestException catch (e) {
      if (_isUniqueViolation(e)) {
        throw StateError('A friend request with this user already exists.');
      }
      rethrow;
    }
  }

  @override
  Future<void> sendChallengeRequest(UserModel userModel, int gameId) async {
    final pair = _resolveOutgoingPair(userModel);
    try {
      await _client.from(HomeTable.gameChallenges).insert({
        GameChallengeCols.fromUserId: pair.from,
        GameChallengeCols.toUserId: pair.to,
        GameChallengeCols.gameId: gameId,
        GameChallengeCols.status: GameChallengeStatus.pending,
      });
    } on PostgrestException catch (e) {
      if (_isUniqueViolation(e)) {
        throw StateError(
          'A pending challenge to this user for this game already exists.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<ProfileDashboardModel> loadProfileDashboard() async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Cannot load profile while signed out.');
    }

    final sessionUser = _client.auth.currentUser;
    final email = sessionUser?.email;

    final profileRow = await _client
        .from(HomeTable.profiles)
        .select(
          '${ProfileCols.id}, ${ProfileCols.username}, ${ProfileCols.avatarUrl}, ${ProfileCols.acceptsMatchInvites}, ${ProfileCols.pushNotificationsEnabled}',
        )
        .eq(ProfileCols.id, uid)
        .maybeSingle();

    var acceptsMatchInvites = true;
    var pushNotificationsEnabled = true;
    final UserModel user;
    if (profileRow == null) {
      if (sessionUser == null) {
        throw StateError('No profile or session.');
      }
      user = _mergeSessionProfileIfNeeded(
        UserModel.fromSupabaseUser(sessionUser),
        uid,
      );
    } else {
      final map = Map<String, dynamic>.from(profileRow);
      acceptsMatchInvites = _coerceBool(
        map[ProfileCols.acceptsMatchInvites],
        defaultValue: true,
      );
      pushNotificationsEnabled = _coerceBool(
        map[ProfileCols.pushNotificationsEnabled],
        defaultValue: true,
      );
      user = _mergeSessionProfileIfNeeded(UserModel.fromJson(map), uid);
    }

    final postsRes = await _client
        .from(HomeTable.posts)
        .select(PostCols.id)
        .eq(PostCols.userId, uid);
    final postsCount = (postsRes as List).length;

    final friendsCount = await _countAcceptedFriends(uid);

    final chRes = await _client
        .from(HomeTable.gameChallenges)
        .select(PostCols.id)
        .or(
          '${GameChallengeCols.fromUserId}.eq.$uid,'
          '${GameChallengeCols.toUserId}.eq.$uid',
        );
    final challengesCount = (chRes as List).length;

    final incoming = await _fetchIncomingFriendRequests(uid);

    return ProfileDashboardModel(
      user: user,
      email: email,
      stats: UserProfileStats(
        postsCount: postsCount,
        friendsCount: friendsCount,
        challengesCount: challengesCount,
      ),
      incomingFriendRequests: incoming,
      acceptsMatchInvites: acceptsMatchInvites,
      pushNotificationsEnabled: pushNotificationsEnabled,
    );
  }

  static bool _coerceBool(dynamic raw, {required bool defaultValue}) {
    if (raw == null) return defaultValue;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.toLowerCase();
      if (s == 'true' || s == 't' || s == '1') return true;
      if (s == 'false' || s == 'f' || s == '0') return false;
    }
    return defaultValue;
  }

  @override
  Future<void> updateAcceptsMatchInvites(bool accepts) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Not signed in.');
    }
    await _client
        .from(HomeTable.profiles)
        .update({ProfileCols.acceptsMatchInvites: accepts})
        .eq(ProfileCols.id, uid);
  }

  @override
  Future<void> updatePushNotificationsEnabled(bool enabled) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Not signed in.');
    }
    final patch = <String, dynamic>{
      ProfileCols.pushNotificationsEnabled: enabled,
    };
    if (!enabled) {
      patch[ProfileCols.fcmToken] = null;
    }
    await _client
        .from(HomeTable.profiles)
        .update(patch)
        .eq(ProfileCols.id, uid);
  }

  @override
  Future<void> updateMyProfile({
    required String username,
    Uint8List? avatarBytes,
    String? avatarContentType,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Not signed in.');
    }
    final name = username.trim();
    if (name.isEmpty) {
      throw ArgumentError('Display name cannot be empty.');
    }

    String? newAvatarUrl;
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      newAvatarUrl = await _uploadPostImage(
        uid: uid,
        bytes: avatarBytes,
        contentType: avatarContentType ?? 'image/jpeg',
      );
    }

    final patch = <String, dynamic>{ProfileCols.username: name};
    if (newAvatarUrl != null) {
      patch[ProfileCols.avatarUrl] = newAvatarUrl;
    }

    await _client.from(HomeTable.profiles).upsert({
      ProfileCols.id: uid,
      ...patch,
    }, onConflict: ProfileCols.id);

    final meta = <String, dynamic>{'username': name};
    if (newAvatarUrl != null) {
      meta['avatar_url'] = newAvatarUrl;
    }
    await _client.auth.updateUser(UserAttributes(data: meta));
  }

  Future<Set<String>> _acceptedFriendIdSet(String uid) async {
    final response = await _client
        .from(HomeTable.friendRequests)
        .select(
          '${FriendRequestCols.fromUserId}, ${FriendRequestCols.toUserId}',
        )
        .eq(FriendRequestCols.status, FriendRequestStatus.accepted)
        .or(
          '${FriendRequestCols.fromUserId}.eq.$uid,'
          '${FriendRequestCols.toUserId}.eq.$uid',
        );

    final rows = _asMapList(response);
    final friendIds = <String>{};
    for (final m in rows) {
      final from = m[FriendRequestCols.fromUserId]?.toString().trim() ?? '';
      final to = m[FriendRequestCols.toUserId]?.toString().trim() ?? '';
      if (from == uid && to.isNotEmpty) {
        friendIds.add(to);
      } else if (to == uid && from.isNotEmpty) {
        friendIds.add(from);
      }
    }
    return friendIds;
  }

  Future<int> _countAcceptedFriends(String uid) async {
    final friendIds = await _acceptedFriendIdSet(uid);
    return friendIds.length;
  }

  @override
  Future<Set<String>> getAcceptedFriendUserIds() async {
    final uid = _currentUserId;
    if (uid == null) return {};
    return _acceptedFriendIdSet(uid);
  }

  Future<List<IncomingFriendRequestModel>> _fetchIncomingFriendRequests(
    String uid,
  ) async {
    final rowsRaw = await _client
        .from(HomeTable.friendRequests)
        .select(
          '${FriendRequestCols.id}, ${FriendRequestCols.fromUserId}, ${PostCols.createdAt}',
        )
        .eq(FriendRequestCols.toUserId, uid)
        .eq(FriendRequestCols.status, FriendRequestStatus.pending)
        .order(PostCols.createdAt, ascending: false);

    final rows = _asMapList(rowsRaw);
    if (rows.isEmpty) return const [];

    final fromIds = <String>{};
    for (final m in rows) {
      final fid = m[FriendRequestCols.fromUserId]?.toString() ?? '';
      if (fid.isNotEmpty) fromIds.add(fid);
    }
    if (fromIds.isEmpty) return const [];

    final profilesRaw = await _client
        .from(HomeTable.profiles)
        .select(
          '${ProfileCols.id}, ${ProfileCols.username}, ${ProfileCols.avatarUrl}',
        )
        .inFilter(ProfileCols.id, fromIds.toList());

    final profileById = <String, Map<String, dynamic>>{};
    for (final p in _asMapList(profilesRaw)) {
      final id = p[ProfileCols.id]?.toString();
      if (id != null) profileById[id] = p;
    }

    final out = <IncomingFriendRequestModel>[];
    for (final m in rows) {
      final rid = m[FriendRequestCols.id]?.toString() ?? '';
      final fid = m[FriendRequestCols.fromUserId]?.toString() ?? '';
      if (rid.isEmpty || fid.isEmpty) continue;

      final pMap = profileById[fid];
      final fromUser = pMap != null
          ? UserModel.fromJson(pMap)
          : UserModel(id: fid, username: 'User', avatarUrl: null);

      out.add(
        IncomingFriendRequestModel(
          requestId: rid,
          fromUser: _mergeSessionProfileIfNeeded(fromUser, fid),
          createdAt: _parsePostCreatedAt(m[PostCols.createdAt]),
        ),
      );
    }
    return out;
  }

  @override
  Future<void> respondToFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Cannot respond while signed out.');
    }
    final id = requestId.trim();
    if (id.isEmpty) {
      throw ArgumentError('requestId must not be empty');
    }

    await _client
        .from(HomeTable.friendRequests)
        .update({
          FriendRequestCols.status: accept
              ? FriendRequestStatus.accepted
              : FriendRequestStatus.declined,
        })
        .eq(FriendRequestCols.id, id)
        .eq(FriendRequestCols.toUserId, uid);
  }

  @override
  Future<void> removeAcceptedFriendship({required String friendUserId}) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Cannot unfriend while signed out.');
    }
    final fid = friendUserId.trim();
    if (fid.isEmpty) {
      throw ArgumentError.value(
        friendUserId,
        'friendUserId',
        'must not be empty',
      );
    }

    final row = await _client
        .from(HomeTable.friendRequests)
        .select(FriendRequestCols.id)
        .eq(FriendRequestCols.status, FriendRequestStatus.accepted)
        .or(
          'and(${FriendRequestCols.fromUserId}.eq.$uid,${FriendRequestCols.toUserId}.eq.$fid),'
          'and(${FriendRequestCols.fromUserId}.eq.$fid,${FriendRequestCols.toUserId}.eq.$uid)',
        )
        .maybeSingle();

    if (row == null) {
      throw StateError('No friendship found with this user.');
    }
    final rid = row[FriendRequestCols.id]?.toString() ?? '';
    if (rid.isEmpty) {
      throw StateError('No friendship found with this user.');
    }

    await _client
        .from(HomeTable.friendRequests)
        .delete()
        .eq(FriendRequestCols.id, rid);
  }

  String _utcDateString(DateTime utc) {
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Future<TeamCloudSnapshot> fetchTeamCloudSnapshot() async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Not signed in.');
    }
    final row = await _client
        .from(HomeTable.profiles)
        .select('${ProfileCols.teamSkillPoints}, ${ProfileCols.teamSquad}')
        .eq(ProfileCols.id, uid)
        .maybeSingle();

    final ptsRaw = row?[ProfileCols.teamSkillPoints];
    final pts = ptsRaw is int
        ? ptsRaw
        : ptsRaw is num
        ? ptsRaw.toInt()
        : int.tryParse('$ptsRaw') ?? 0;

    final squadRaw = row?[ProfileCols.teamSquad];
    Map<String, dynamic>? squadJson;
    if (squadRaw is Map) {
      squadJson = Map<String, dynamic>.from(squadRaw);
    }

    final today = _utcDateString(DateTime.now().toUtc());
    final claims = await _client
        .from(HomeTable.teamChallengeDailyClaims)
        .select(TeamChallengeClaimCols.challengeKey)
        .eq(TeamChallengeClaimCols.userId, uid)
        .eq(TeamChallengeClaimCols.claimDay, today);

    final keys = <String>{};
    final list = claims as List<dynamic>?;
    if (list != null) {
      for (final e in list) {
        if (e is Map) {
          final k = e[TeamChallengeClaimCols.challengeKey]?.toString();
          if (k != null && k.isNotEmpty) keys.add(k);
        }
      }
    }

    return TeamCloudSnapshot(
      skillPoints: pts,
      squadJson: squadJson,
      claimedChallengeKeysToday: keys,
    );
  }

  @override
  Future<void> upsertMyTeamSquad(Map<String, dynamic> squadJson) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('Not signed in.');
    }
    await _client
        .from(HomeTable.profiles)
        .update({ProfileCols.teamSquad: squadJson})
        .eq(ProfileCols.id, uid);
  }

  @override
  Future<Map<String, dynamic>> rpcClaimTeamDailyChallenge(String key) async {
    final raw = await _client.rpc(
      'claim_team_daily_challenge',
      params: {'p_challenge_key': key},
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('Unexpected RPC response');
  }

  @override
  Future<Map<String, dynamic>> rpcTrainTeamPlayer({
    required int playerSlot,
    required String statKey,
  }) async {
    final raw = await _client.rpc(
      'train_team_player',
      params: {'p_slot': playerSlot, 'p_stat': statKey},
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('Unexpected RPC response');
  }

  @override
  Future<Map<String, dynamic>> rpcClaimTeamSquadSpar(
    String opponentUserId,
  ) async {
    final id = opponentUserId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        opponentUserId,
        'opponentUserId',
        'must not be empty',
      );
    }
    final raw = await _client.rpc(
      'claim_team_squad_spar',
      params: {'p_opponent': id},
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('Unexpected RPC response');
  }

  @override
  Future<Map<String, dynamic>> rpcClaimTeamAcademyScrim() async {
    final raw = await _client.rpc('claim_team_academy_scrim');
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('Unexpected RPC response');
  }

  DateTime? _parseSubmittedAt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  LineupRaceBoardRow _mapLineupRaceRow(Map<String, dynamic> m) {
    final uid = m[TeamLineupRaceCols.userId]?.toString() ?? '';
    final sc = m[TeamLineupRaceCols.score];
    final score = sc is int ? sc : (sc is num ? sc.toInt() : 0);
    final tname = m[TeamLineupRaceCols.teamName]?.toString() ?? '';
    final prof = m[HomeTable.profiles];
    String? username;
    String? avatarUrl;
    if (prof is Map) {
      final pm = Map<String, dynamic>.from(prof);
      username = pm[ProfileCols.username]?.toString();
      final av = pm[ProfileCols.avatarUrl]?.toString();
      avatarUrl = (av != null && av.isNotEmpty) ? av : null;
    }
    return LineupRaceBoardRow(
      userId: uid,
      score: score,
      teamName: tname,
      username: username,
      avatarUrl: avatarUrl,
      submittedAt: _parseSubmittedAt(m[TeamLineupRaceCols.submittedAt]),
    );
  }

  @override
  Future<List<LineupRaceBoardRow>> fetchLineupRaceLeaderboard({
    required String raceKey,
    int limit = 40,
  }) async {
    final rk = raceKey.trim();
    if (rk.isEmpty) return const [];

    final response = await _client
        .from(HomeTable.teamLineupRaceEntries)
        .select(
          '${TeamLineupRaceCols.userId}, ${TeamLineupRaceCols.score}, '
          '${TeamLineupRaceCols.teamName}, ${TeamLineupRaceCols.submittedAt}, '
          '${HomeTable.profiles}(${ProfileCols.username}, ${ProfileCols.avatarUrl})',
        )
        .eq(TeamLineupRaceCols.raceKey, rk)
        .order(TeamLineupRaceCols.score, ascending: false)
        .limit(limit);

    final rows = response as List<dynamic>;
    return rows
        .map((e) => _mapLineupRaceRow(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> rpcSubmitTeamLineupRace(String raceKey) async {
    final raw = await _client.rpc(
      'submit_team_lineup_race',
      params: {'p_race_key': raceKey},
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('Unexpected RPC response');
  }

  @override
  Future<List<UserFeedNotificationModel>> fetchMyUserNotifications({
    int limit = 50,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return const [];

    final response = await _client
        .from(HomeTable.userNotifications)
        .select(
          '${UserNotificationCols.id}, ${UserNotificationCols.kind}, '
          '${UserNotificationCols.title}, ${UserNotificationCols.body}, '
          '${UserNotificationCols.data}, ${UserNotificationCols.createdAt}',
        )
        .eq(UserNotificationCols.userId, uid)
        .order(UserNotificationCols.createdAt, ascending: false)
        .limit(limit);

    final rows = _asMapList(response);
    return rows.map(UserFeedNotificationModel.fromJson).toList(growable: false);
  }
}
