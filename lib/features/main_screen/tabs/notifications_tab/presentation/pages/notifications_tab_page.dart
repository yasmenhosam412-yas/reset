import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/navigation/main_shell_controller.dart';
import 'package:new_project/core/widgets/tab_loading_skeletons.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/user_feed_notification_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_my_user_notifications_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/navigation/open_author_posts_screen.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_titles.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_state.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/domain/usecases/respond_profile_friend_request_usecase.dart';

String _friendName(String userId, List<UserModel> friends) {
  for (final f in friends) {
    if (f.id == userId) {
      final n = f.username.trim();
      return n.isEmpty ? 'Player' : n;
    }
  }
  if (userId.length <= 12) return userId;
  return '${userId.substring(0, 10)}…';
}

String _opponentName(ChallengeRequestModel c, String uid, List<UserModel> friends) {
  final oid = c.fromId == uid ? c.toId : c.fromId;
  return _friendName(oid, friends);
}

List<ChallengeRequestModel> _lobbiesForNotifications(
  List<ChallengeRequestModel> challenges,
  String? uid,
  AcceptedMatchPreview? pendingLobby,
) {
  if (uid == null) return const [];
  return challenges.where((c) {
    final cid = c.id?.trim();
    if (cid == null || cid.isEmpty) return false;
    if (c.status.toLowerCase() != 'accepted') return false;
    if (c.fromId != uid && c.toId != uid) return false;
    if (pendingLobby != null && pendingLobby.challengeId == cid) {
      return false;
    }
    return true;
  }).toList(growable: false);
}

DateTime _sortTime(DateTime? t) =>
    t ?? DateTime.fromMillisecondsSinceEpoch(0);

/// Single row in the merged Alerts list (feed inbox + match rows).
final class _MergedNotif {
  _MergedNotif.feed(UserFeedNotificationModel m)
      : feed = m,
        invite = null,
        lobby = null,
        sortTime = _sortTime(m.createdAt);

  _MergedNotif.invite(ChallengeRequestModel inv)
      : feed = null,
        invite = inv,
        lobby = null,
        sortTime = _sortTime(inv.createdAt);

  _MergedNotif.lobby(ChallengeRequestModel c)
      : feed = null,
        invite = null,
        lobby = c,
        sortTime = _sortTime(c.createdAt);

  final UserFeedNotificationModel? feed;
  final ChallengeRequestModel? invite;
  final ChallengeRequestModel? lobby;
  final DateTime sortTime;
}

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<UserFeedNotificationModel> _feed = const [];
  bool _feedLoading = true;
  final _alertsCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadFeed();
    });
  }

  @override
  void dispose() {
    _alertsCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() => _feedLoading = true);
    final result = await getIt<GetMyUserNotificationsUsecase>()();
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _feedLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        );
      },
      (list) {
        setState(() {
          _feed = list;
          _feedLoading = false;
        });
      },
    );
  }

  Future<void> _onRefresh(BuildContext context) async {
    context.read<OnlineBloc>().add(OnlineLoadRequested());
    await _loadFeed();
    if (!context.mounted) return;
    await context.read<OnlineBloc>().stream.firstWhere(
          (s) => s.status != OnlineStatus.loading,
        );
  }

  Future<void> _respondFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await getIt<RespondProfileFriendRequestUsecase>()(
      requestId: requestId,
      accept: accept,
    );
    if (!mounted) return;
    result.fold(
      (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(accept ? 'Friend request accepted.' : 'Declined.'),
          ),
        );
        _loadFeed().then((_) {
          if (mounted) {
            context.read<OnlineBloc>().add(OnlineLoadRequested());
          }
        });
      },
    );
  }

  List<_MergedNotif> _buildMerged({
    required List<UserFeedNotificationModel> feed,
    required List<ChallengeRequestModel> invites,
    required List<ChallengeRequestModel> lobbies,
  }) {
    final out = <_MergedNotif>[
      for (final n in feed) _MergedNotif.feed(n),
      for (final inv in invites) _MergedNotif.invite(inv),
      for (final c in lobbies) _MergedNotif.lobby(c),
    ]..sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Alerts'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
      ),
      body: BlocBuilder<OnlineBloc, OnlineState>(
        builder: (context, onlineState) {
          final uid = onlineState.currentUserId;
          final invites = uid == null
              ? <ChallengeRequestModel>[]
              : onlineState.challenges
                  .where((c) => c.toId == uid && c.status == 'pending')
                  .toList(growable: false);
          final lobbies = _lobbiesForNotifications(
            onlineState.challenges,
            uid,
            onlineState.pendingMatchLobby,
          );
          final merged = _buildMerged(
            feed: _feed,
            invites: invites,
            lobbies: lobbies,
          );
          final empty = merged.isEmpty;
          final onlineLoading =
              onlineState.status == OnlineStatus.loading && invites.isEmpty && lobbies.isEmpty;
          final showSkeleton = empty && (onlineLoading || _feedLoading);

          Widget emptyListBody() {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 100),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: _NotifCard(
                      scheme: scheme,
                      theme: theme,
                      leading: _NotifIconBadge(
                        scheme: scheme,
                        icon: Icons.notifications_none_rounded,
                        iconColor: scheme.outline,
                        backgroundOpacity: 0.2,
                      ),
                      title: 'You are all caught up',
                      subtitle:
                          'Likes, comments, friend requests, and match invites will show here. Pull down to refresh.',
                      actions: null,
                    ),
                  ),
                ),
              ],
            );
          }

          Widget dataList() {
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
              itemCount: merged.length,
              itemBuilder: (context, index) {
                final row = merged[index];
                final f = row.feed;
                if (f != null) {
                  if (f.kind == UserNotificationKind.friendRequest) {
                    final rid = f.data['request_id']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FriendRequestFeedItem(
                        body: f.body,
                        meta: homeFeedTimeAgo(f.createdAt),
                        scheme: scheme,
                        theme: theme,
                        requestId: rid,
                        onRespond: _respondFriendRequest,
                        onOpenRelated: () =>
                            getIt<MainShellController>().openProfileTab(),
                      ),
                    );
                  }
                  final (icon, color) = switch (f.kind) {
                    UserNotificationKind.postLike => (
                        Icons.favorite_rounded,
                        scheme.error,
                      ),
                    UserNotificationKind.postComment => (
                        Icons.chat_bubble_rounded,
                        scheme.tertiary,
                      ),
                    _ => (
                        Icons.notifications_rounded,
                        scheme.primary,
                      ),
                  };
                  final postId = f.data['post_id']?.toString().trim() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlainFeedItem(
                      body: f.body,
                      meta: homeFeedTimeAgo(f.createdAt),
                      scheme: scheme,
                      theme: theme,
                      icon: icon,
                      accent: color,
                      onOpenRelated: postId.isEmpty || uid == null || uid.isEmpty
                          ? null
                          : () {
                              final authorName = context
                                      .read<ProfileBloc>()
                                      .state
                                      .dashboard
                                      ?.user
                                      .username
                                      .trim() ??
                                  '';
                              openAuthorPostsScreen(
                                context: context,
                                authorId: uid,
                                authorName: authorName,
                                commentController: _alertsCommentController,
                                focusPostId: postId,
                                openCommentsAfterScroll: f.kind ==
                                    UserNotificationKind.postComment,
                              );
                            },
                    ),
                  );
                }
                final inv = row.invite;
                if (inv != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InviteListItem(
                      inv: inv,
                      friends: onlineState.friends,
                      scheme: scheme,
                      theme: theme,
                      onOpenRelated: () =>
                          getIt<MainShellController>().openOnlineTab(),
                    ),
                  );
                }
                final lobby = row.lobby;
                if (lobby != null && uid != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LobbyListItem(
                      c: lobby,
                      uid: uid,
                      friends: onlineState.friends,
                      scheme: scheme,
                      theme: theme,
                      onOpenRelated: () =>
                          getIt<MainShellController>().openOnlineTab(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          }

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: showSkeleton
                  ? TabLoadingSkeletons.notificationsTab(context)
                  : empty
                      ? emptyListBody()
                      : dataList(),
            ),
          );
        },
      ),
    );
  }
}

class _NotifIconBadge extends StatelessWidget {
  const _NotifIconBadge({
    required this.scheme,
    required this.icon,
    required this.iconColor,
    this.backgroundOpacity = 0.18,
  });

  final ColorScheme scheme;
  final IconData icon;
  final Color iconColor;
  final double backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: backgroundOpacity),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 24),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.scheme,
    required this.theme,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.onTap,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.35),
      ),
    );
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (subtitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (actions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: actions!,
            ),
        ],
      ),
    );
  }
}

class _PlainFeedItem extends StatelessWidget {
  const _PlainFeedItem({
    required this.body,
    required this.meta,
    required this.scheme,
    required this.theme,
    required this.icon,
    required this.accent,
    this.onOpenRelated,
  });

  final String body;
  final String meta;
  final ColorScheme scheme;
  final ThemeData theme;
  final IconData icon;
  final Color accent;
  final VoidCallback? onOpenRelated;

  @override
  Widget build(BuildContext context) {
    final secondary = meta.isEmpty ? '' : meta;
    return _NotifCard(
      scheme: scheme,
      theme: theme,
      leading: _NotifIconBadge(
        scheme: scheme,
        icon: icon,
        iconColor: accent,
      ),
      title: body,
      subtitle: secondary,
      actions: null,
      onTap: onOpenRelated,
    );
  }
}

class _FriendRequestFeedItem extends StatelessWidget {
  const _FriendRequestFeedItem({
    required this.body,
    required this.meta,
    required this.scheme,
    required this.theme,
    required this.requestId,
    required this.onRespond,
    this.onOpenRelated,
  });

  final String body;
  final String meta;
  final ColorScheme scheme;
  final ThemeData theme;
  final String requestId;
  final Future<void> Function({
    required String requestId,
    required bool accept,
  }) onRespond;
  final VoidCallback? onOpenRelated;

  @override
  Widget build(BuildContext context) {
    final hasId = requestId.trim().isNotEmpty;
    return _NotifCard(
      scheme: scheme,
      theme: theme,
      leading: _NotifIconBadge(
        scheme: scheme,
        icon: Icons.person_add_alt_1_rounded,
        iconColor: scheme.primary,
      ),
      title: body,
      subtitle: meta,
      onTap: onOpenRelated,
      actions: hasId
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onRespond(requestId: requestId, accept: false),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => onRespond(requestId: requestId, accept: true),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

class _InviteListItem extends StatelessWidget {
  const _InviteListItem({
    required this.inv,
    required this.friends,
    required this.scheme,
    required this.theme,
    this.onOpenRelated,
  });

  final ChallengeRequestModel inv;
  final List<UserModel> friends;
  final ColorScheme scheme;
  final ThemeData theme;
  final VoidCallback? onOpenRelated;

  @override
  Widget build(BuildContext context) {
    final body = '${_friendName(inv.fromId, friends)} '
        'invited you to ${onlineGameTitle(inv.gameId)}.';
    final meta = homeFeedTimeAgo(inv.createdAt);

    return _NotifCard(
      scheme: scheme,
      theme: theme,
      leading: _NotifIconBadge(
        scheme: scheme,
        icon: Icons.sports_esports_rounded,
        iconColor: scheme.secondary,
      ),
      title: body,
      subtitle: meta,
      onTap: onOpenRelated,
      actions: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: inv.id == null
                  ? null
                  : () => context.read<OnlineBloc>().add(
                        OnlineChallengeDecisionRequested(
                          challengeId: inv.id!,
                          accept: false,
                        ),
                      ),
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: inv.id == null
                  ? null
                  : () {
                      String? opponentAvatarUrl;
                      final fromName = _friendName(inv.fromId, friends);
                      for (final fr in friends) {
                        if (fr.id == inv.fromId) {
                          opponentAvatarUrl = fr.avatarUrl?.trim();
                          break;
                        }
                      }
                      context.read<OnlineBloc>().add(
                            OnlineChallengeDecisionRequested(
                              challengeId: inv.id!,
                              accept: true,
                              opponentDisplayName: fromName,
                              opponentAvatarUrl: opponentAvatarUrl,
                              gameId: inv.gameId,
                            ),
                          );
                    },
              child: const Text('Accept'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyListItem extends StatelessWidget {
  const _LobbyListItem({
    required this.c,
    required this.uid,
    required this.friends,
    required this.scheme,
    required this.theme,
    this.onOpenRelated,
  });

  final ChallengeRequestModel c;
  final String uid;
  final List<UserModel> friends;
  final ColorScheme scheme;
  final ThemeData theme;
  final VoidCallback? onOpenRelated;

  @override
  Widget build(BuildContext context) {
    final opp = _opponentName(c, uid, friends);
    final gameTitle = onlineGameTitle(c.gameId);
    final meFrom = c.fromId == uid;
    final iAmReady = meFrom ? c.fromReady : c.toReady;
    final theyReady = meFrom ? c.toReady : c.fromReady;
    final bothReady = c.fromReady && c.toReady;
    final you = iAmReady ? 'ready' : 'not ready yet';
    final them = theyReady ? 'ready' : 'still waiting';
    final body = bothReady
        ? '$gameTitle with $opp — both players are ready.'
        : '$gameTitle with $opp — you are $you; your opponent is $them.';

    return _NotifCard(
      scheme: scheme,
      theme: theme,
      leading: _NotifIconBadge(
        scheme: scheme,
        icon: Icons.handshake_rounded,
        iconColor: scheme.tertiary,
      ),
      title: body,
      subtitle: '',
      onTap: onOpenRelated,
      actions: !bothReady
          ? SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: !iAmReady && c.id != null
                    ? () => context.read<OnlineBloc>().add(
                          OnlineChallengeReadyRequested(
                            challengeId: c.id!,
                          ),
                        )
                    : null,
                child: Text(
                  iAmReady ? 'Waiting for opponent' : 'Mark ready',
                ),
              ),
            )
          : null,
    );
  }
}
