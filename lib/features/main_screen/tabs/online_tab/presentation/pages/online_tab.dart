import 'package:flutter/material.dart';
import 'package:new_project/core/widgets/tab_loading_skeletons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/routing/app_router.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_route_args.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_titles.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/party_room_lobby_screen.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/party_room_service.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_game_screen.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/fantasy_cards/fantasy_duel_game.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/rps_duel/rps_duel_game.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/dialogs/send_online_challenge_dialog.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_state.dart';

class _GameItem {
  const _GameItem({
    required this.gameId,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final int gameId;
  final String title;
  final String subtitle;
  final IconData icon;
}

List<_GameItem> _onlineTabGames(BuildContext context) {
  final l10n = context.l10n;
  return [
    _GameItem(
      gameId: 1,
      title: onlineGameTitleL10n(l10n, 1),
      subtitle: l10n.singleDeviceNotOnlineMatch,
      icon: Icons.sports_soccer_rounded,
    ),
    _GameItem(
      gameId: 2,
      title: onlineGameTitleL10n(l10n, 2),
      subtitle: l10n.singleDeviceChallengeFriendHint,
      icon: Icons.balance_rounded,
    ),
    _GameItem(
      gameId: 3,
      title: onlineGameTitleL10n(l10n, 3),
      subtitle: l10n.singleDeviceSameDuelHint,
      icon: Icons.auto_awesome_rounded,
    ),
    _GameItem(
      gameId: 4,
      title: onlineGameTitleL10n(l10n, 4),
      subtitle: l10n.onlinePartyGameTwoToFive,
      icon: Icons.flash_on_rounded,
    ),
    _GameItem(
      gameId: 5,
      title: onlineGameTitleL10n(l10n, 5),
      subtitle: l10n.onlinePartyGameRoundsGetHarder,
      icon: Icons.grid_view_rounded,
    ),
  ];
}

Color _onlineAvatarColor(String name) {
  final i = name.hashCode.abs() % Colors.primaries.length;
  return Colors.primaries[i];
}

String _onlineDisplayNameForFromId(
  String fromId,
  List<UserModel> friends, {
  required String fallbackPlayerLabel,
}) {
  for (final f in friends) {
    if (f.id == fromId) {
      final n = f.username.trim();
      return n.isEmpty ? fallbackPlayerLabel : n;
    }
  }
  if (fromId.length <= 12) return fromId;
  return '${fromId.substring(0, 10)}…';
}

_GameItem? _onlineGameItemForId(BuildContext context, int id) {
  for (final g in _onlineTabGames(context)) {
    if (g.gameId == id) return g;
  }
  return null;
}

String _onlineOpponentNameForChallenge(
  ChallengeRequestModel c,
  String uid,
  List<UserModel> friends,
  String fallbackPlayerLabel,
) {
  final oid = c.fromId == uid ? c.toId : c.fromId;
  return _onlineDisplayNameForFromId(
    oid,
    friends,
    fallbackPlayerLabel: fallbackPlayerLabel,
  );
}

List<ChallengeRequestModel> _onlineAcceptedLobbyChallenges(
  List<ChallengeRequestModel> challenges,
  String? uid,
  AcceptedMatchPreview? pendingLobby,
) {
  if (uid == null) return const [];
  return challenges
      .where((c) {
        final cid = c.id?.trim();
        if (cid == null || cid.isEmpty) return false;
        if (c.status.toLowerCase() != 'accepted') return false;
        if (c.fromId != uid && c.toId != uid) return false;
        if (pendingLobby != null && pendingLobby.challengeId == cid) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}

void _showAcceptedMatchLobbyDialog(
  BuildContext context,
  AcceptedMatchPreview preview,
) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final bloc = context.read<OnlineBloc>();
  final g = _onlineGameItemForId(context, preview.gameId);
  final gameTitle = g?.title ?? onlineGameTitleL10n(l10n, preview.gameId);
  final gameSubtitle = g?.subtitle ?? '';
  final gameIcon = g?.icon ?? Icons.sports_esports_rounded;

  final name = preview.opponentDisplayName;
  final avatarUrl = preview.opponentAvatarUrl?.trim();
  final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.matchAccepted),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.opponent,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _onlineAvatarColor(name),
                    foregroundColor: Colors.white,
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: hasAvatar
                        ? null
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.game,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(gameIcon, size: 22),
                title: Text(gameTitle),
                subtitle: gameSubtitle.isEmpty ? null : Text(gameSubtitle),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              bloc.add(
                OnlineChallengeReadyRequested(challengeId: preview.challengeId),
              );
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.ready),
          ),
        ],
      );
    },
  ).whenComplete(() {
    bloc.add(OnlinePendingMatchLobbyDismissed());
  });
}

Future<void> _refreshOnlineTab(BuildContext context) async {
  context.read<OnlineBloc>().add(OnlineLoadRequested());
  await context.read<OnlineBloc>().stream.firstWhere(
    (s) => s.status != OnlineStatus.loading,
  );
}

Future<void> _openGameVsAi(
  BuildContext context,
  _GameItem g,
  List<UserModel> friends,
) async {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  switch (g.gameId) {
    case 1:
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: Text(g.title),
              backgroundColor: theme.scaffoldBackgroundColor,
            ),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l10n.practiceVsAi,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.singleDeviceNotOnlineMatch,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                PenaltyShootoutGame(
                  scheme: scheme,
                  theme: theme,
                  opponentName: l10n.aiLabel,
                ),
              ],
            ),
          ),
        ),
      );
      return;
    case 2:
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: Text(g.title),
              backgroundColor: theme.scaffoldBackgroundColor,
            ),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l10n.practiceVsAi,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.singleDeviceChallengeFriendHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                RpsDuelGame(
                  scheme: scheme,
                  theme: theme,
                  opponentName: l10n.aiLabel,
                ),
              ],
            ),
          ),
        ),
      );
      return;
    case 3:
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: Text(g.title),
              backgroundColor: theme.scaffoldBackgroundColor,
            ),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l10n.practiceVsAi,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.singleDeviceSameDuelHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FantasyDuelGame(
                  scheme: scheme,
                  theme: theme,
                  opponentName: l10n.aiLabel,
                ),
              ],
            ),
          ),
        ),
      );
      return;
    case 4:
    case 5:
      final roomId = await _showCreatePartyRoomDialog(
        context: context,
        game: g,
        friends: friends,
      );
      if (roomId == null || !context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PartyRoomLobbyScreen(
            roomId: roomId,
            gameId: g.gameId,
            gameTitle: g.title,
          ),
        ),
      );
      return;
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vsAiNotAvailableYet(g.title))),
      );
  }
}

Future<String?> _showCreatePartyRoomDialog({
  required BuildContext context,
  required _GameItem game,
  required List<UserModel> friends,
}) async {
  var maxPlayers = 4;
  final selected = <String>{};
  var creating = false;

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      final l10n = ctx.l10n;
      final theme = Theme.of(ctx);
      final scheme = theme.colorScheme;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final inviteLimit = maxPlayers - 1;
          final canCreate = selected.length == inviteLimit;
          return AlertDialog(
            title: Text(l10n.createRoomTitle(game.title)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: maxPlayers,
                    decoration: InputDecoration(labelText: l10n.roomSize),
                    items: const [2, 3, 4, 5]
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(l10n.playersMax(v)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: creating
                        ? null
                        : (v) {
                            if (v == null) return;
                            setDialogState(() {
                              maxPlayers = v;
                              while (selected.length > maxPlayers - 1) {
                                selected.remove(selected.first);
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.inviteExactlyFriends(inviteLimit),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in friends)
                        FilterChip(
                          label: Text(
                            f.username.trim().isEmpty
                                ? l10n.player
                                : f.username.trim(),
                          ),
                          selected: selected.contains(f.id),
                          onSelected: creating
                              ? null
                              : (on) {
                                  setDialogState(() {
                                    if (on) {
                                      if (selected.length < inviteLimit) {
                                        selected.add(f.id);
                                      }
                                    } else {
                                      selected.remove(f.id);
                                    }
                                  });
                                },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: creating ? null : () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: canCreate && !creating
                    ? () async {
                        setDialogState(() => creating = true);
                        try {
                          final roomId =
                              await PartyRoomService.createRoomAndInvite(
                                gameId: game.gameId,
                                maxPlayers: maxPlayers,
                                inviteUserIds: selected.toList(growable: false),
                              );
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop(roomId);
                        } catch (e) {
                          if (!ctx.mounted) return;
                          setDialogState(() => creating = false);
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    : null,
                child: creating
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.creating,
                            style: TextStyle(color: scheme.onPrimary),
                          ),
                        ],
                      )
                    : Text(l10n.createRoom),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Shared section chrome for the Online tab (icon chip + title + optional subtitle).
class _OnlineSectionHeader extends StatelessWidget {
  const _OnlineSectionHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _OnlineGameCard extends StatelessWidget {
  const _OnlineGameCard({
    required this.game,
    required this.scheme,
    required this.theme,
    required this.compact,
    required this.onTap,
  });

  final _GameItem game;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [scheme.primary, scheme.tertiary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          game.icon,
                          size: 24,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      game.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      game.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: scheme.primary,
                        size: 32,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [scheme.primary, scheme.tertiary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(game.icon, color: scheme.onPrimary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            game.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: scheme.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class OnlineTab extends StatelessWidget {
  const OnlineTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OnlineTabView();
  }
}

class _OnlineTabView extends StatefulWidget {
  const _OnlineTabView();

  @override
  State<_OnlineTabView> createState() => _OnlineTabViewState();
}

class _OnlineTabViewState extends State<_OnlineTabView> {
  final GlobalKey<_PartyRoomInvitesBlockState> _partyInvitesKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocConsumer<OnlineBloc, OnlineState>(
      listenWhen: (prev, curr) =>
          (curr.errorMessage != null &&
              curr.errorMessage != prev.errorMessage) ||
          (curr.successMessage != null &&
              curr.successMessage != prev.successMessage) ||
          (curr.pendingMatchLobby != null &&
              curr.pendingMatchLobby != prev.pendingMatchLobby) ||
          (curr.pendingGameLaunch != null &&
              curr.pendingGameLaunch != prev.pendingGameLaunch),
      listener: (context, state) {
        final l10n = context.l10n;
        final err = state.errorMessage;
        if (err != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
        final ok = switch (state.successType) {
          OnlineSuccessType.challengeSent => l10n.challengeSentTo(
            onlineGameTitleL10n(l10n, state.successGameId ?? 1),
            (state.successName?.trim().isEmpty ?? true)
                ? l10n.friend
                : state.successName!.trim(),
          ),
          OnlineSuccessType.leftMatch => l10n.opponentLeftMatch,
          OnlineSuccessType.challengeDeclined => l10n.challengeDeclined,
          OnlineSuccessType.challengeAccepted => l10n.challengeAccepted,
          OnlineSuccessType.challengeAcceptedHasOtherMatches =>
            l10n.challengeAcceptedHasOtherMatches,
          OnlineSuccessType.readyWaitingOpponent => l10n.readyWaitingForOpponent,
          null => state.successMessage,
        };
        if (ok != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ok)));
        }
        final lobby = state.pendingMatchLobby;
        if (lobby != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            _showAcceptedMatchLobbyDialog(context, lobby);
          });
        }
        final launch = state.pendingGameLaunch;
        if (launch != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final route = ModalRoute.of(context);
            if (route != null && !route.isCurrent) {
              context.read<OnlineBloc>().add(OnlineGameLaunchConsumed());
              return;
            }
            final loc = GoRouterState.of(context).uri.path;
            if (loc == AppRouter.gameSessionPath) {
              context.read<OnlineBloc>().add(OnlineGameLaunchConsumed());
              return;
            }
            context.push(
              AppRouter.gameSessionPath,
              extra: OnlineGameRouteArgs(
                challengeId: launch.challengeId,
                gameId: launch.gameId,
                opponentUserId: launch.opponentUserId,
                opponentDisplayName: launch.opponentDisplayName,
                challengeFromUserId: launch.challengeFromUserId,
                challengeToUserId: launch.challengeToUserId,
              ),
            );
            context.read<OnlineBloc>().add(OnlineGameLaunchConsumed());
          });
        }
      },
      builder: (context, state) {
        final loading = state.status == OnlineStatus.loading;
        final empty = state.friends.isEmpty && state.challenges.isEmpty;
        final uid = state.currentUserId;
        final invites = uid == null
            ? <ChallengeRequestModel>[]
            : state.challenges
                  .where((c) => c.toId == uid && c.status == 'pending')
                  .toList(growable: false);

        if (loading && empty) {
          return Scaffold(
            body: SafeArea(child: TabLoadingSkeletons.onlineTab(context)),
          );
        }

        if (state.status == OnlineStatus.failure && empty) {
          final msg = state.errorMessage ?? l10n.somethingWentWrong;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: scheme.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.couldNotLoadOnline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: () => context.read<OnlineBloc>().add(
                          OnlineLoadRequested(),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.tryAgain),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshOnlineTab(context);
                _partyInvitesKey.currentState?.reload();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primaryContainer.withValues(alpha: 0.72),
                              scheme.surfaceContainerHighest.withValues(
                                alpha: 0.92,
                              ),
                              scheme.tertiaryContainer.withValues(alpha: 0.45),
                            ],
                          ),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.07),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.primary.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: scheme.primary.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Icon(
                                Icons.wifi_tethering_rounded,
                                color: scheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.online,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.6,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.onlineHeaderSubtitle,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _OnlineSectionHeader(
                        title: l10n.friends,
                        subtitle: state.friends.isEmpty
                            ? null
                            : l10n.tapFriendToChallenge,
                        icon: Icons.people_alt_rounded,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 136,
                      child: state.friends.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerLow.withValues(
                                    alpha: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: scheme.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_add_rounded,
                                      color: scheme.onSurfaceVariant,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        l10n.noFriendsYetAcceptFromHome,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              height: 1.35,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: state.friends.length,
                              separatorBuilder: (context_, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final f = state.friends[index];
                                final label = f.username.trim().isEmpty
                                    ? l10n.player
                                    : f.username;
                                final avatarUrl = f.avatarUrl?.trim();
                                final hasAvatar =
                                    avatarUrl != null && avatarUrl.isNotEmpty;
                                return SizedBox(
                                  width: 94,
                                  child: Material(
                                    color: scheme.surfaceContainerLow
                                        .withValues(alpha: 0.85),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(
                                        color: scheme.outlineVariant.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () =>
                                          showSendOnlineChallengeDialog(
                                            context,
                                            f,
                                          ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          10,
                                          12,
                                          10,
                                          10,
                                        ),
                                        child: Column(
                                          children: [
                                            Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                CircleAvatar(
                                                  radius: 26,
                                                  backgroundColor:
                                                      _onlineAvatarColor(label),
                                                  foregroundColor: Colors.white,
                                                  backgroundImage: hasAvatar
                                                      ? NetworkImage(avatarUrl)
                                                      : null,
                                                  child: hasAvatar
                                                      ? null
                                                      : Text(
                                                          label.isNotEmpty
                                                              ? label[0]
                                                                    .toUpperCase()
                                                              : '?',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 18,
                                                              ),
                                                        ),
                                                ),
                                                Positioned(
                                                  right: -2,
                                                  bottom: -2,
                                                  child: Container(
                                                    width: 15,
                                                    height: 15,
                                                    decoration: BoxDecoration(
                                                      color: scheme.tertiary,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: scheme.surface,
                                                        width: 2,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: scheme.tertiary
                                                              .withValues(
                                                                alpha: 0.45,
                                                              ),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              label.split(' ').first,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            Text(
                                              l10n.friend,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _OnlineSectionHeader(
                        title: l10n.partyRooms,
                        subtitle: l10n.partyRoomsSubtitle,
                        icon: Icons.groups_rounded,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: _PartyRoomInvitesBlock(
                        key: _partyInvitesKey,
                        scheme: scheme,
                        theme: theme,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _OnlineSectionHeader(
                        title: l10n.playInvites,
                        subtitle: l10n.playInvitesSubtitle,
                        icon: Icons.mark_email_unread_rounded,
                        trailing: TextButton.icon(
                          onPressed: () => context.read<OnlineBloc>().add(
                            OnlineLoadRequested(),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: Text(l10n.refresh),
                        ),
                      ),
                    ),
                  ),
                  if (invites.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow.withValues(
                              alpha: 0.75,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                color: scheme.onSurfaceVariant,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.noPendingInvites,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: invites.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final inv = invites[index];
                          final fromName = _onlineDisplayNameForFromId(
                            inv.fromId,
                            state.friends,
                            fallbackPlayerLabel: l10n.player,
                          );
                          String? opponentAvatarUrl;
                          for (final fr in state.friends) {
                            if (fr.id == inv.fromId) {
                              opponentAvatarUrl = fr.avatarUrl?.trim();
                              break;
                            }
                          }
                          final firstName = fromName.split(' ').first;
                          final gameTitle = onlineGameTitleL10n(
                            l10n,
                            inv.gameId,
                          );
                          final timeLabel = homeFeedTimeAgo(inv.createdAt);
                          return Card(
                            margin: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            color: scheme.surfaceContainerLow.withValues(
                              alpha: 0.55,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: _onlineAvatarColor(
                                          fromName,
                                        ),
                                        foregroundColor: Colors.white,
                                        child: Text(
                                          fromName.isNotEmpty
                                              ? fromName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text.rich(
                                              TextSpan(
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(height: 1.25),
                                                children: [
                                                  TextSpan(
                                                    text: firstName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: l10n.invitedYouToPlay,
                                                    style: TextStyle(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: gameTitle,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: scheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (timeLabel.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                timeLabel,
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: inv.id == null
                                              ? null
                                              : () => context
                                                    .read<OnlineBloc>()
                                                    .add(
                                                      OnlineChallengeDecisionRequested(
                                                        challengeId: inv.id!,
                                                        accept: false,
                                                      ),
                                                    ),
                                          child: Text(l10n.decline),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: inv.id == null
                                              ? null
                                              : () => context
                                                    .read<OnlineBloc>()
                                                    .add(
                                                      OnlineChallengeDecisionRequested(
                                                        challengeId: inv.id!,
                                                        accept: true,
                                                        opponentDisplayName:
                                                            fromName,
                                                        opponentAvatarUrl:
                                                            opponentAvatarUrl,
                                                        gameId: inv.gameId,
                                                      ),
                                                    ),
                                          child: Text(l10n.accept),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ...() {
                    final uid = state.currentUserId;
                    final lobbies = _onlineAcceptedLobbyChallenges(
                      state.challenges,
                      uid,
                      state.pendingMatchLobby,
                    );
                    if (lobbies.isEmpty) return <Widget>[];
                    return [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: _OnlineSectionHeader(
                            title: l10n.activeMatches,
                            subtitle: lobbies.length > 1
                                ? l10n.activeMatchesMultiHint
                                : l10n.tapReadyWhenSet,
                            icon: Icons.bolt_rounded,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.separated(
                          itemCount: lobbies.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final c = lobbies[index];
                            final opp = _onlineOpponentNameForChallenge(
                              c,
                              uid!,
                              state.friends,
                              l10n.player,
                            );
                            final gameTitle = onlineGameTitleL10n(
                              l10n,
                              c.gameId,
                            );
                            final meFrom = c.fromId == uid;
                            final iAmReady = meFrom ? c.fromReady : c.toReady;
                            final theyReady = meFrom ? c.toReady : c.fromReady;
                            final bothReady = c.fromReady && c.toReady;
                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: scheme.primary.withValues(alpha: 0.22),
                                ),
                              ),
                              color: scheme.primaryContainer.withValues(
                                alpha: 0.22,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opp,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      gameTitle,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      bothReady
                                          ? l10n.bothPlayersReady
                                          : l10n.readyStatusLine(
                                              iAmReady
                                                  ? l10n.ready
                                                  : l10n.notReady,
                                              theyReady
                                                  ? l10n.ready
                                                  : l10n.waiting,
                                            ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                    if (!bothReady) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          onPressed: !iAmReady && c.id != null
                                              ? () => context
                                                    .read<OnlineBloc>()
                                                    .add(
                                                      OnlineChallengeReadyRequested(
                                                        challengeId: c.id!,
                                                      ),
                                                    )
                                              : null,
                                          child: Text(
                                            iAmReady
                                                ? l10n.waitingForOpponent
                                                : l10n.ready,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ];
                  }(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _OnlineSectionHeader(
                        title: l10n.games,
                        subtitle: l10n.gamesSubtitle,
                        icon: Icons.sports_esports_rounded,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverToBoxAdapter(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final orientation = MediaQuery.orientationOf(context);
                          // Row of three when there is enough width, or in landscape on typical phones.
                          final wide =
                              constraints.maxWidth >= 560 ||
                              (orientation == Orientation.landscape &&
                                  constraints.maxWidth >= 480);
                          final cards = _onlineTabGames(context)
                              .map(
                                (g) => _OnlineGameCard(
                                  game: g,
                                  scheme: scheme,
                                  theme: theme,
                                  compact: wide,
                                  onTap: () =>
                                      _openGameVsAi(context, g, state.friends),
                                ),
                              )
                              .toList(growable: false);
                          if (wide) {
                            final cardWidth = (constraints.maxWidth - 10) / 2;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final c in cards)
                                  SizedBox(width: cardWidth, child: c),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(height: 10),
                                cards[i],
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PartyRoomInvitesBlock extends StatefulWidget {
  const _PartyRoomInvitesBlock({
    super.key,
    required this.scheme,
    required this.theme,
  });

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  State<_PartyRoomInvitesBlock> createState() => _PartyRoomInvitesBlockState();
}

class _PartyRoomInvitesBlockState extends State<_PartyRoomInvitesBlock> {
  late Future<List<PartyRoomInviteRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = PartyRoomService.fetchIncomingInvites();
  }

  /// Schedules a refetch on the next frame so we never call [setState] while a parent
  /// (e.g. [BlocConsumer] or route transition) is still in [build].
  void reload() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _future = PartyRoomService.fetchIncomingInvites();
      });
    });
  }

  Future<void> _navigateToLobby(
    PartyRoomInviteRow inv, {
    required bool acceptFirst,
  }) async {
    if (acceptFirst) {
      await PartyRoomService.respondInvite(roomId: inv.roomId, accept: true);
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PartyRoomLobbyScreen(
          roomId: inv.roomId,
          gameId: inv.gameId,
          gameTitle: onlineGameTitleL10n(context.l10n, inv.gameId),
        ),
      ),
    );
    reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = widget.scheme;
    final theme = widget.theme;

    return FutureBuilder<List<PartyRoomInviteRow>>(
      future: _future,
      builder: (context, snap) {
        final invites = snap.data ?? const <PartyRoomInviteRow>[];
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: scheme.primary,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
              ),
            ),
          );
        }
        if (invites.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  color: scheme.onSurfaceVariant,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.noPartyRoomInvitesYet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final inv in invites) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: scheme.tertiary.withValues(alpha: 0.28),
                  ),
                ),
                color: scheme.tertiaryContainer.withValues(alpha: 0.18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: scheme.tertiary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              inv.alreadyJoined
                                  ? Icons.login_rounded
                                  : Icons.mail_outline_rounded,
                              color: scheme.tertiary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inv.alreadyJoined
                                      ? l10n.inHostsPartyRoom(inv.hostName)
                                      : l10n.hostInvitedYou(inv.hostName),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.gameUpToPlayers(
                                    onlineGameTitleL10n(l10n, inv.gameId),
                                    inv.maxPlayers,
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                                if (inv.invitedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    homeFeedTimeAgo(inv.invitedAt),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  if (inv.alreadyJoined) {
                                    await PartyRoomService.leavePartyRoomUi(
                                      roomId: inv.roomId,
                                    );
                                  } else {
                                    await PartyRoomService.respondInvite(
                                      roomId: inv.roomId,
                                      accept: false,
                                    );
                                  }
                                  if (!mounted) return;
                                  reload();
                                  if (!context.mounted) return;
                                  context.read<OnlineBloc>().add(
                                    OnlineLoadRequested(),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              },
                              child: Text(
                                inv.alreadyJoined ? l10n.leave : l10n.decline,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                try {
                                  await _navigateToLobby(
                                    inv,
                                    acceptFirst: !inv.alreadyJoined,
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              },
                              child: Text(
                                inv.alreadyJoined
                                    ? l10n.openLobby
                                    : l10n.joinRoom,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
