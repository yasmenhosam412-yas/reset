import 'package:flutter/material.dart';

class _OnlineFriend {
  const _OnlineFriend({required this.name, required this.status});

  final String name;
  final String status;
}

class _FriendGameInvite {
  const _FriendGameInvite({
    required this.fromFriendName,
    required this.gameTitle,
    required this.gameDetail,
    required this.timeLabel,
    required this.expiresLabel,
  });

  final String fromFriendName;
  final String gameTitle;
  final String gameDetail;
  final String timeLabel;
  final String expiresLabel;
}

class _GameItem {
  const _GameItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class OnlineTab extends StatelessWidget {
  const OnlineTab({super.key});

  static const List<_OnlineFriend> _friends = [
    _OnlineFriend(name: 'Alex Rivera', status: 'In lobby'),
    _OnlineFriend(name: 'Jordan Kim', status: 'Playing Chess'),
    _OnlineFriend(name: 'Morgan Lee', status: 'Available'),
    _OnlineFriend(name: 'Sam Patel', status: 'In queue'),
  ];

  static const List<_FriendGameInvite> _invites = [
    _FriendGameInvite(
      fromFriendName: 'Jordan Kim',
      gameTitle: 'Chess',
      gameDetail: 'Rated · 10 min clock',
      timeLabel: 'Invited 6 min ago',
      expiresLabel: 'Invite expires in 54 min',
    ),
    _FriendGameInvite(
      fromFriendName: 'Alex Rivera',
      gameTitle: 'Quick duel',
      gameDetail: 'Casual · first to 3',
      timeLabel: 'Invited 22 min ago',
      expiresLabel: 'Invite expires in 38 min',
    ),
    _FriendGameInvite(
      fromFriendName: 'Morgan Lee',
      gameTitle: 'Trivia rush',
      gameDetail: 'Party mode · 5 rounds',
      timeLabel: 'Invited 1 hr ago',
      expiresLabel: 'Invite expires in 2 hr',
    ),
  ];

  static const List<_GameItem> _games = [
    _GameItem(
      title: 'Chess',
      subtitle: 'Rated · 10 min',
      icon: Icons.grid_3x3_rounded,
    ),
    _GameItem(
      title: 'Quick duel',
      subtitle: 'Casual · live',
      icon: Icons.flash_on_rounded,
    ),
    _GameItem(
      title: 'Trivia rush',
      subtitle: 'Party mode',
      icon: Icons.quiz_rounded,
    ),
  ];

  Color _avatarColor(String name) {
    final i = name.hashCode.abs() % Colors.primaries.length;
    return Colors.primaries[i];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
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
                  'Friends online',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _friends.length,
                  separatorBuilder: (context_, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final f = _friends[index];
                    return SizedBox(
                      width: 88,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () {},
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
                                      backgroundColor: _avatarColor(f.name),
                                      foregroundColor: Colors.white,
                                      child: Text(
                                        f.name.isNotEmpty
                                            ? f.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
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
                                          color: const Color(0xFF2E7D32),
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
                                  f.name.split(' ').first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  f.status,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
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
                    TextButton(onPressed: () {}, child: const Text('See all')),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: _invites.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final inv = _invites[index];
                  final firstName = inv.fromFriendName.split(' ').first;
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    _avatarColor(inv.fromFriendName),
                                foregroundColor: Colors.white,
                                child: Text(
                                  inv.fromFriendName.isNotEmpty
                                      ? inv.fromFriendName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(height: 1.25),
                                              children: [
                                                TextSpan(
                                                  text: firstName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      ' invited you to play ',
                                                  style: TextStyle(
                                                    color: scheme
                                                        .onSurfaceVariant,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: inv.gameTitle,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: scheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      inv.gameDetail,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${inv.timeLabel} · ${inv.expiresLabel}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
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
                                  onPressed: () {},
                                  child: const Text('Decline'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {},
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
                separatorBuilder: (context, index) => const SizedBox(height: 10),
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
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
