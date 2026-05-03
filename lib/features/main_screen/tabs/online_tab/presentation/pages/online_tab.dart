import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/routing/app_router.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/data/models/challenge_request_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_route_args.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_titles.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/penalty_shootout/penalty_shootout_game_screen.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/fantasy_cards/fantasy_duel_game.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/rim_shot/rim_shot_game.dart';
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

Color _onlineAvatarColor(String name) {
  final i = name.hashCode.abs() % Colors.primaries.length;
  return Colors.primaries[i];
}

String _onlineDisplayNameForFromId(String fromId, List<UserModel> friends) {
  for (final f in friends) {
    if (f.id == fromId) {
      final n = f.username.trim();
      return n.isEmpty ? 'Player' : n;
    }
  }
  if (fromId.length <= 12) return fromId;
  return '${fromId.substring(0, 10)}…';
}

_GameItem? _onlineGameItemForId(int id) {
  for (final g in _OnlineTabView._games) {
    if (g.gameId == id) return g;
  }
  return null;
}

String _onlineOpponentNameForChallenge(
  ChallengeRequestModel c,
  String uid,
  List<UserModel> friends,
) {
  final oid = c.fromId == uid ? c.toId : c.fromId;
  return _onlineDisplayNameForFromId(oid, friends);
}

List<ChallengeRequestModel> _onlineAcceptedLobbyChallenges(
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

void _showAcceptedMatchLobbyDialog(
  BuildContext context,
  AcceptedMatchPreview preview,
) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final bloc = context.read<OnlineBloc>();
  final g = _onlineGameItemForId(preview.gameId);
  final gameTitle = g?.title ?? onlineGameTitle(preview.gameId);
  final gameSubtitle = g?.subtitle ?? '';
  final gameIcon = g?.icon ?? Icons.sports_esports_rounded;

  final name = preview.opponentDisplayName;
  final avatarUrl = preview.opponentAvatarUrl?.trim();
  final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Match accepted'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Opponent',
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
                    backgroundImage:
                        hasAvatar ? NetworkImage(avatarUrl) : null,
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
                'Game',
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
                OnlineChallengeReadyRequested(
                  challengeId: preview.challengeId,
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Ready'),
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

void _openGameVsAi(BuildContext context, _GameItem g) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  switch (g.gameId) {
    case 1:
      Navigator.of(context).push<void>(
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
                  'Practice vs AI',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Single device — not an online match.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                PenaltyShootoutGame(
                  scheme: scheme,
                  theme: theme,
                  opponentName: 'AI',
                ),
              ],
            ),
          ),
        ),
      );
      return;
    case 2:
      Navigator.of(context).push<void>(
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
                  'Practice vs AI',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Single device — challenge a friend online for a real duel.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                RimShotGame(
                  scheme: scheme,
                  theme: theme,
                  opponentName: 'AI',
                ),
              ],
            ),
          ),
        ),
      );
      return;
    case 3:
      Navigator.of(context).push<void>(
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
                  'Practice vs AI',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Single device — same duel online vs a friend.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FantasyDuelGame(
                  scheme: scheme,
                  theme: theme,
                  opponentName: 'AI',
                ),
              ],
            ),
          ),
        ),
      );
      return;
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${g.title} vs AI is not available yet.')),
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

class _OnlineTabView extends StatelessWidget {
  const _OnlineTabView();

  static const List<_GameItem> _games = [
    _GameItem(
      gameId: 1,
      title: 'Penalty shootout',
      subtitle: 'Tap to play vs AI on this device',
      icon: Icons.sports_soccer_rounded,
    ),
    _GameItem(
      gameId: 2,
      title: 'Rim shot',
      subtitle:
          'Free throws — tight power window, wing pads, first to ${RimShotGame.winningScore}',
      icon: Icons.sports_basketball_rounded,
    ),
    _GameItem(
      gameId: 3,
      title: 'Fantasy cards',
      subtitle: 'Glyph duel — pick 3 of 5 lanes vs AI here',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
        final err = state.errorMessage;
        if (err != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
        final ok = state.successMessage;
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
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        if (state.status == OnlineStatus.failure && empty) {
          final msg = state.errorMessage ?? 'Something went wrong';
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.read<OnlineBloc>().add(
                          OnlineLoadRequested(),
                        ),
                        child: const Text('Try again'),
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
              onRefresh: () => _refreshOnlineTab(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Online',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Friends',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 128,
                      child: state.friends.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'No friends yet. Accept requests from Home.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
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
                                    ? 'Player'
                                    : f.username;
                                final avatarUrl = f.avatarUrl?.trim();
                                final hasAvatar =
                                    avatarUrl != null && avatarUrl.isNotEmpty;
                                return SizedBox(
                                  width: 88,
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    child: InkWell(
                                      onTap: () =>
                                          showSendOnlineChallengeDialog(
                                            context,
                                            f,
                                          ),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
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
                                                    width: 14,
                                                    height: 14,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF2E7D32,
                                                      ),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: scheme.surface,
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              label.split(' ').first,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            Text(
                                              'Friend',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        scheme.onSurfaceVariant,
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
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Play invites',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Friends invited you to a match',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.read<OnlineBloc>().add(
                              OnlineLoadRequested(),
                            ),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (invites.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'No pending invites.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
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
                          );
                          String? opponentAvatarUrl;
                          for (final fr in state.friends) {
                            if (fr.id == inv.fromId) {
                              opponentAvatarUrl = fr.avatarUrl?.trim();
                              break;
                            }
                          }
                          final firstName = fromName.split(' ').first;
                          final gameTitle = onlineGameTitle(inv.gameId);
                          final timeLabel = homeFeedTimeAgo(inv.createdAt);
                          return Card(
                            margin: EdgeInsets.zero,
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
                                        radius: 22,
                                        backgroundColor: _onlineAvatarColor(
                                          fromName,
                                        ),
                                        foregroundColor: Colors.white,
                                        child: Text(
                                          fromName.isNotEmpty
                                              ? fromName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
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
                                                    text:
                                                        ' invited you to play ',
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
                                          child: const Text('Decline'),
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
                                          child: const Text('Accept'),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active matches',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (lobbies.length > 1) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Each card is a separate game. Mark Ready per '
                                  'match; when both players are ready on a card, '
                                  'you can start that game from there.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
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
                            );
                            final gameTitle = onlineGameTitle(c.gameId);
                            final meFrom = c.fromId == uid;
                            final iAmReady =
                                meFrom ? c.fromReady : c.toReady;
                            final theyReady =
                                meFrom ? c.toReady : c.fromReady;
                            final bothReady = c.fromReady && c.toReady;
                            return Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opp,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      gameTitle,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      bothReady
                                          ? 'Both players ready.'
                                          : 'You: ${iAmReady ? 'Ready' : 'Not ready'} · '
                                                'Them: ${theyReady ? 'Ready' : 'Waiting'}',
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
                                          onPressed: !iAmReady &&
                                                  c.id != null
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
                                                ? 'Waiting for opponent'
                                                : 'Ready',
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
                      child: Text(
                        'Games',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: _games.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final g = _games[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: scheme.primaryContainer,
                              foregroundColor: scheme.onPrimaryContainer,
                              child: Icon(g.icon),
                            ),
                            title: Text(
                              g.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              g.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.play_circle_fill_rounded,
                              color: scheme.primary,
                              size: 36,
                            ),
                            onTap: () => _openGameVsAi(context, g),
                          ),
                        );
                      },
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
