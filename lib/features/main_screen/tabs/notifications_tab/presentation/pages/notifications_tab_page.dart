import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/l10n/l10n.dart';
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

String _friendName(
  String userId,
  List<UserModel> friends, {
  required String fallbackPlayerLabel,
}) {
  for (final f in friends) {
    if (f.id == userId) {
      final n = f.username.trim();
      return n.isEmpty ? fallbackPlayerLabel : n;
    }
  }
  if (userId.length <= 12) return userId;
  return '${userId.substring(0, 10)}…';
}

DateTime _sortTime(DateTime? t) => t ?? DateTime.fromMillisecondsSinceEpoch(0);

bool _isSupportedFeedKind(String kind) {
  return kind == UserNotificationKind.postLike ||
      kind == UserNotificationKind.postComment ||
      kind == UserNotificationKind.commentMention ||
      kind == UserNotificationKind.friendRequest ||
      kind == UserNotificationKind.partyRoomInvite;
}

String _friendlyFeedTitle(UserFeedNotificationModel f, BuildContext context) {
  final l10n = context.l10n;
  switch (f.kind) {
    case UserNotificationKind.postLike:
      return l10n.notifSomeoneReacted;
    case UserNotificationKind.postComment:
      return l10n.notifSomeoneCommented;
    case UserNotificationKind.commentMention:
      return l10n.notifYouWereMentioned;
    case UserNotificationKind.friendRequest:
      return f.body.trim().isEmpty ? l10n.notifFriendInvite : f.body;
    case UserNotificationKind.partyRoomInvite:
      return l10n.notifRoomInviteWaiting;
    default:
      return f.body.trim().isEmpty ? l10n.notifNewNotification : f.body;
  }
}

String _friendlyFeedSubtitle(
  UserFeedNotificationModel f,
  String timeAgo,
  BuildContext context,
) {
  final l10n = context.l10n;
  final time = timeAgo.trim();
  String withTime(String message) =>
      time.isEmpty ? message : '$time • $message';
  switch (f.kind) {
    case UserNotificationKind.postLike:
      return withTime(l10n.notifPostLikeOpenHint);
    case UserNotificationKind.postComment:
      return withTime(l10n.notifPostCommentOpenHint);
    case UserNotificationKind.commentMention:
      return withTime(l10n.notifMentionOpenHint);
    case UserNotificationKind.friendRequest:
      final status = f.data['status']?.toString().trim().toLowerCase() ?? '';
      if (status == 'accepted') {
        return withTime(l10n.notifFriendRequestAcceptedStatus);
      }
      if (status == 'declined' || status == 'cancelled') {
        return withTime(l10n.notifFriendRequestNoLongerPending);
      }
      return time.isEmpty
          ? l10n.notifReviewInvite
          : '$time • ${l10n.notifReviewInviteShort}';
    case UserNotificationKind.partyRoomInvite:
      return withTime(l10n.notifPartyRoomInviteOpenHint);
    default:
      return time;
  }
}

/// Single row in the merged Alerts list (feed inbox + match rows).
final class _MergedNotif {
  _MergedNotif.feed(UserFeedNotificationModel m)
    : feed = m,
      invite = null,
      sortTime = _sortTime(m.createdAt);

  _MergedNotif.invite(ChallengeRequestModel inv)
    : feed = null,
      invite = inv,
      sortTime = _sortTime(inv.createdAt);

  final UserFeedNotificationModel? feed;
  final ChallengeRequestModel? invite;
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
  final Set<String> _busyFriendRequestIds = <String>{};

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.message)));
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
    final rid = requestId.trim();
    if (rid.isEmpty || _busyFriendRequestIds.contains(rid)) return;
    setState(() => _busyFriendRequestIds.add(rid));
    final messenger = ScaffoldMessenger.of(context);
    final result = await getIt<RespondProfileFriendRequestUsecase>()(
      requestId: rid,
      accept: accept,
    );
    if (!mounted) return;
    result.fold(
      (f) {
        final msg = f.message.trim();
        final norm = msg.toLowerCase();
        final stale =
            norm.contains('not found') ||
            norm.contains('no rows') ||
            norm.contains('conflict') ||
            norm.contains('already') ||
            norm.contains('invalid') ||
            norm.contains('constraint');
        if (stale) {
          setState(() {
            _feed = _feed
                .where(
                  (n) =>
                      !(n.kind == UserNotificationKind.friendRequest &&
                          (n.data['request_id']?.toString() ?? '') == rid),
                )
                .toList(growable: false);
          });
          messenger.showSnackBar(
            SnackBar(content: Text(context.l10n.friendRequestNoLongerValid)),
          );
        } else {
          messenger.showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      (_) {
        setState(() {
          _feed = _feed
              .where(
                (n) =>
                    !(n.kind == UserNotificationKind.friendRequest &&
                        (n.data['request_id']?.toString() ?? '') == rid),
              )
              .toList(growable: false);
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? context.l10n.friendRequestAccepted
                  : context.l10n.declined,
            ),
          ),
        );
        _loadFeed().then((_) {
          if (mounted) {
            context.read<OnlineBloc>().add(OnlineLoadRequested());
          }
        });
      },
    );
    if (!mounted) return;
    setState(() => _busyFriendRequestIds.remove(rid));
  }

  List<_MergedNotif> _buildMerged({
    required List<UserFeedNotificationModel> feed,
    required List<ChallengeRequestModel> invites,
  }) {
    final out = <_MergedNotif>[
      for (final n in feed)
        if (_isSupportedFeedKind(n.kind)) _MergedNotif.feed(n),
      for (final inv in invites) _MergedNotif.invite(inv),
    ]..sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(l10n.notifications),
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
          final merged = _buildMerged(feed: _feed, invites: invites);
          final empty = merged.isEmpty;
          final onlineLoading =
              onlineState.status == OnlineStatus.loading && invites.isEmpty;
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
                      title: l10n.allCaughtUp,
                      subtitle: l10n.notificationsCaughtUpSubtitle,
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
                    final status =
                        f.data['status']?.toString().trim().toLowerCase() ?? '';
                    final actionable =
                        rid.trim().isNotEmpty &&
                        (status.isEmpty || status == 'pending');
                    final busy = _busyFriendRequestIds.contains(rid.trim());
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FriendRequestFeedItem(
                        body: _friendlyFeedTitle(f, context),
                        meta: _friendlyFeedSubtitle(
                          f,
                          homeFeedTimeAgo(f.createdAt),
                          context,
                        ),
                        scheme: scheme,
                        theme: theme,
                        requestId: rid,
                        actionable: actionable && !busy,
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
                    UserNotificationKind.commentMention => (
                      Icons.alternate_email_rounded,
                      scheme.secondary,
                    ),
                    UserNotificationKind.partyRoomInvite => (
                      Icons.groups_rounded,
                      scheme.primary,
                    ),
                    _ => (Icons.notifications_rounded, scheme.primary),
                  };
                  final postId = f.data['post_id']?.toString().trim() ?? '';
                  final VoidCallback? onOpenRelated = switch (f.kind) {
                    UserNotificationKind.partyRoomInvite =>
                      () => getIt<MainShellController>().openOnlineTab(),
                    UserNotificationKind.commentMention =>
                      postId.isEmpty
                          ? null
                          : () {
                              final fromData =
                                  f.data['author_id']?.toString().trim() ?? '';
                              final authorId = fromData.isNotEmpty
                                  ? fromData
                                  : (uid ?? '').trim();
                              if (authorId.isEmpty) return;
                              final selfName =
                                  context
                                      .read<ProfileBloc>()
                                      .state
                                      .dashboard
                                      ?.user
                                      .username
                                      .trim() ??
                                  '';
                              final authorName =
                                  uid != null && authorId == uid
                                      ? selfName
                                      : '';
                              openAuthorPostsScreen(
                                context: context,
                                authorId: authorId,
                                authorName: authorName,
                                commentController: _alertsCommentController,
                                focusPostId: postId,
                                openCommentsAfterScroll: true,
                              );
                            },
                    _ =>
                      postId.isEmpty || uid == null || uid.isEmpty
                          ? null
                          : () {
                              final authorName =
                                  context
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
                                openCommentsAfterScroll:
                                    f.kind == UserNotificationKind.postComment,
                              );
                            },
                  };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlainFeedItem(
                      body: _friendlyFeedTitle(f, context),
                      meta: _friendlyFeedSubtitle(
                        f,
                        homeFeedTimeAgo(f.createdAt),
                        context,
                      ),
                      scheme: scheme,
                      theme: theme,
                      icon: icon,
                      accent: color,
                      onOpenRelated: onOpenRelated,
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
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: backgroundOpacity),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 22),
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
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.28)),
    );
    return Material(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.55),
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
              padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
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
      leading: _NotifIconBadge(scheme: scheme, icon: icon, iconColor: accent),
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
    required this.actionable,
    required this.onRespond,
    this.onOpenRelated,
  });

  final String body;
  final String meta;
  final ColorScheme scheme;
  final ThemeData theme;
  final String requestId;
  final bool actionable;
  final Future<void> Function({required String requestId, required bool accept})
  onRespond;
  final VoidCallback? onOpenRelated;

  @override
  Widget build(BuildContext context) {
    final canRespond = actionable && requestId.trim().isNotEmpty;
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
      actions: canRespond
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        onRespond(requestId: requestId, accept: false),
                    child: Text(context.l10n.decline),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        onRespond(requestId: requestId, accept: true),
                    child: Text(context.l10n.accept),
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
    final l10n = context.l10n;
    final body =
        '${_friendName(inv.fromId, friends, fallbackPlayerLabel: l10n.player)} invited you to play '
        '${onlineGameTitleL10n(l10n, inv.gameId)} together.';
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
              child: Text(context.l10n.decline),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: inv.id == null
                  ? null
                  : () {
                      String? opponentAvatarUrl;
                      final fromName = _friendName(
                        inv.fromId,
                        friends,
                        fallbackPlayerLabel: context.l10n.player,
                      );
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
              child: Text(context.l10n.accept),
            ),
          ),
        ],
      ),
    );
  }
}
