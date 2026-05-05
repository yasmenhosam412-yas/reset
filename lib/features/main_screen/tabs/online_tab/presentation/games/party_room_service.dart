import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartyRoomInviteRow {
  const PartyRoomInviteRow({
    required this.roomId,
    required this.gameId,
    required this.maxPlayers,
    required this.hostUserId,
    required this.hostName,
    this.alreadyJoined = false,
    this.invitedAt,
  });

  final String roomId;
  final int gameId;
  final int maxPlayers;
  final String hostUserId;
  final String hostName;

  /// True when this user already accepted (`joined`) — still show the card until they leave or the room closes.
  final bool alreadyJoined;

  /// When this user’s membership row was created (invite sent / you were added to the room).
  final DateTime? invitedAt;
}

class PartyRoomScoreRow {
  const PartyRoomScoreRow({
    required this.userId,
    required this.username,
    required this.score,
    required this.meta,
  });

  final String userId;
  final String username;
  final int score;
  final Map<String, dynamic> meta;
}

class PartyRoomPresence {
  const PartyRoomPresence({
    required this.maxPlayers,
    required this.joinedCount,
    required this.members,
  });

  final int maxPlayers;
  final int joinedCount;
  final List<UserModel> members;
}

class PartyRoomService {
  PartyRoomService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<String> createRoomAndInvite({
    required int gameId,
    required int maxPlayers,
    required List<String> inviteUserIds,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in first.');
    if (maxPlayers < 2 || maxPlayers > 5) {
      throw StateError('Room size must be between 2 and 5.');
    }

    final room = await _client
        .from('party_game_rooms')
        .insert({
          'host_user_id': uid,
          'game_id': gameId,
          'max_players': maxPlayers,
          'status': 'open',
        })
        .select('id')
        .single();
    final roomId = room['id']?.toString() ?? '';
    if (roomId.isEmpty) throw StateError('Could not create room.');

    await _client.from('party_game_room_members').upsert({
      'room_id': roomId,
      'user_id': uid,
      'invited_by': uid,
      'status': 'joined',
    });

    final unique = inviteUserIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != uid)
        .toSet()
        .toList(growable: false);
    final requiredInvites = maxPlayers - 1;
    if (unique.length != requiredInvites) {
      throw StateError('Select exactly $requiredInvites players for this room size.');
    }

    if (unique.isNotEmpty) {
      final rows = [
        for (final id in unique)
          {
            'room_id': roomId,
            'user_id': id,
            'invited_by': uid,
            'status': 'invited',
          },
      ];
      await _client.from('party_game_room_members').upsert(rows);
    }

    return roomId;
  }

  static Future<PartyRoomPresence> fetchRoomPresence(String roomId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Sign in first.');
    }
    final rid = roomId.trim();
    if (rid.isEmpty) {
      throw StateError('Invalid room.');
    }

    final room = await _client
        .from('party_game_rooms')
        .select('max_players')
        .eq('id', rid)
        .maybeSingle();
    if (room == null) {
      throw StateError('Room not found.');
    }
    final maxPlayers = (room['max_players'] as num?)?.toInt() ?? 2;

    final membersRaw = await _client
        .from('party_game_room_members')
        .select('user_id, status')
        .eq('room_id', rid)
        .eq('status', 'joined');
    final membersRows = (membersRaw as List<dynamic>)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final userIds = membersRows
        .map((e) => e['user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final members = <UserModel>[];
    if (userIds.isNotEmpty) {
      final profilesRaw = await _client
          .from('profiles')
          .select('id, username, avatar_url')
          .inFilter('id', userIds);
      final rows = (profilesRaw as List<dynamic>)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      members.addAll(rows.map(UserModel.fromJson));
    }

    return PartyRoomPresence(
      maxPlayers: maxPlayers,
      // Count distinct users; the membership table may contain duplicate rows
      // for the same user if constraints/upserts are not strict.
      joinedCount: userIds.length,
      members: members,
    );
  }

  static Future<List<PartyRoomInviteRow>> fetchIncomingInvites() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];

    final memberRowsRaw = await _client
        .from('party_game_room_members')
        .select('room_id, status, created_at')
        .eq('user_id', uid)
        .inFilter('status', ['invited', 'joined']);
    final memberRows = (memberRowsRaw as List<dynamic>)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final joinedByRoomId = <String, bool>{};
    final invitedAtByRoomId = <String, DateTime?>{};
    for (final row in memberRows) {
      final rid = row['room_id']?.toString() ?? '';
      if (rid.isEmpty) continue;
      final st = row['status']?.toString() ?? '';
      joinedByRoomId[rid] = st == 'joined';
      invitedAtByRoomId[rid] = _parseMemberTimestamp(row['created_at']);
    }
    final roomIds = joinedByRoomId.keys.toList(growable: false);
    if (roomIds.isEmpty) return const [];

    final roomsRaw = await _client
        .from('party_game_rooms')
        .select('id, game_id, max_players, host_user_id, status')
        .inFilter('id', roomIds)
        .eq('status', 'open');
    final rooms = (roomsRaw as List<dynamic>)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    if (rooms.isEmpty) return const [];

    final hostIds = rooms
        .map((e) => e['host_user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final profilesRaw = await _client
        .from('profiles')
        .select('id, username, avatar_url')
        .inFilter('id', hostIds);
    final profiles = (profilesRaw as List<dynamic>)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final profileById = {
      for (final p in profiles) (p['id']?.toString() ?? ''): UserModel.fromJson(p),
    };

    final out = <PartyRoomInviteRow>[];
    for (final r in rooms) {
      final rid = r['id']?.toString() ?? '';
      if (rid.isEmpty) continue;
      final hostId = r['host_user_id']?.toString() ?? '';
      final host = profileById[hostId];
      final gameId = (r['game_id'] as num?)?.toInt() ?? 0;
      final maxPlayers = (r['max_players'] as num?)?.toInt() ?? 2;
      out.add(
        PartyRoomInviteRow(
          roomId: rid,
          gameId: gameId,
          maxPlayers: maxPlayers,
          hostUserId: hostId,
          hostName: host?.username.trim().isEmpty ?? true
              ? 'Player'
              : host!.username.trim(),
          alreadyJoined: joinedByRoomId[rid] ?? false,
          invitedAt: invitedAtByRoomId[rid],
        ),
      );
    }
    out.sort((a, b) {
      final ta = a.invitedAt;
      final tb = b.invitedAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return out;
  }

  static DateTime? _parseMemberTimestamp(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static Future<void> respondInvite({
    required String roomId,
    required bool accept,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in first.');
    final rid = roomId.trim();
    if (rid.isEmpty) throw StateError('Invalid room.');

    if (accept) {
      final room = await _client
          .from('party_game_rooms')
          .select('max_players, status')
          .eq('id', rid)
          .maybeSingle();
      if (room == null) throw StateError('Room no longer exists.');
      final status = room['status']?.toString() ?? '';
      if (status != 'open') throw StateError('Room is closed.');
      final maxPlayers = (room['max_players'] as num?)?.toInt() ?? 2;

      final joinedRaw = await _client
          .from('party_game_room_members')
          .select('user_id')
          .eq('room_id', rid)
          .eq('status', 'joined');
      final joined = (joinedRaw as List).length;
      if (joined >= maxPlayers) throw StateError('Room is full.');
    }

    await _client
        .from('party_game_room_members')
        .update({
          'status': accept ? 'joined' : 'declined',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('room_id', rid)
        .eq('user_id', uid)
        .eq('status', 'invited');
  }

  /// Step out of an open party room after you had joined (e.g. back from lobby).
  static Future<void> leaveJoinedPartyRoom({required String roomId}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in first.');
    final rid = roomId.trim();
    if (rid.isEmpty) throw StateError('Invalid room.');
    await _client
        .from('party_game_room_members')
        .update({
          'status': 'left',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('room_id', rid)
        .eq('user_id', uid)
        .eq('status', 'joined');
  }

  /// Leaving the party flow (lobby back, or Leave on the Online tab card).
  /// Host closes the room so it drops off Party rooms for everyone; any member
  /// clears their `joined` or `invited` row so the card disappears.
  static Future<void> leavePartyRoomUi({required String roomId}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final rid = roomId.trim();
    if (rid.isEmpty) return;
    try {
      final room = await _client
          .from('party_game_rooms')
          .select('host_user_id, status')
          .eq('id', rid)
          .maybeSingle();
      if (room == null) return;
      final roomOpen = (room['status']?.toString() ?? '') == 'open';
      final hostId = room['host_user_id']?.toString() ?? '';
      if (roomOpen && hostId == uid) {
        await _client.from('party_game_rooms').update({
          'status': 'closed',
        }).eq('id', rid).eq('host_user_id', uid);
      }
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('party_game_room_members').update({
        'status': 'left',
        'updated_at': now,
      }).eq('room_id', rid).eq('user_id', uid).eq('status', 'joined');
      await _client.from('party_game_room_members').update({
        'status': 'declined',
        'updated_at': now,
      }).eq('room_id', rid).eq('user_id', uid).eq('status', 'invited');
    } catch (_) {}
  }

  /// Deletes all scores in [roomId] only if every joined member finished (5 rounds or timeout).
  /// RPC raises if the match is still in progress.
  static Future<void> resetPartyRoomMatchIfAllFinished({
    required String roomId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in first.');
    final rid = roomId.trim();
    if (rid.isEmpty) throw StateError('Invalid room.');
    await _client.rpc<void>(
      'party_game_room_reset_match',
      params: {'p_room': rid},
    );
  }

  static Future<void> submitScore({
    required String roomId,
    required int score,
    Map<String, dynamic>? meta,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in first.');
    final rid = roomId.trim();
    if (rid.isEmpty) throw StateError('Invalid room.');
    await _client.from('party_game_room_scores').upsert({
      'room_id': rid,
      'user_id': uid,
      'score': score,
      'meta': meta ?? <String, dynamic>{},
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<List<PartyRoomScoreRow>> fetchLeaderboard(String roomId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    final rid = roomId.trim();
    if (rid.isEmpty) return const [];

    final membersRaw = await _client
        .from('party_game_room_members')
        .select('user_id, status')
        .eq('room_id', rid)
        .eq('status', 'joined');
    final members = (membersRaw as List<dynamic>)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final userIds = members
        .map((e) => e['user_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (userIds.isEmpty) return const [];

    final profilesRaw = await _client
        .from('profiles')
        .select('id, username')
        .inFilter('id', userIds);
    final profileRows = (profilesRaw as List<dynamic>)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final names = <String, String>{
      for (final p in profileRows)
        (p['id']?.toString() ?? ''):
            ((p['username']?.toString().trim() ?? '').isEmpty
                ? 'Player'
                : p['username'].toString().trim()),
    };

    final scoresRaw = await _client
        .from('party_game_room_scores')
        .select('user_id, score, meta')
        .eq('room_id', rid)
        .inFilter('user_id', userIds);
    final scoreRows = (scoresRaw as List<dynamic>)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final scoreByUser = <String, int>{
      for (final s in scoreRows)
        (s['user_id']?.toString() ?? ''): (s['score'] as num?)?.toInt() ?? 0,
    };
    final metaByUser = <String, Map<String, dynamic>>{
      for (final s in scoreRows)
        (s['user_id']?.toString() ?? ''):
            ((s['meta'] is Map)
                ? Map<String, dynamic>.from(s['meta'] as Map)
                : <String, dynamic>{}),
    };

    final out = <PartyRoomScoreRow>[
      for (final id in userIds)
        PartyRoomScoreRow(
          userId: id,
          username: names[id] ?? 'Player',
          score: scoreByUser[id] ?? 0,
          meta: metaByUser[id] ?? <String, dynamic>{},
        ),
    ];
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }
}
