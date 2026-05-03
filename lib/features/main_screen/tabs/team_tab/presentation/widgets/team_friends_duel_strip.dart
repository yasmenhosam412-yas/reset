import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/dialogs/send_online_challenge_dialog.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_state.dart';

Color _teamFriendAvatarColor(String name) {
  final i = name.hashCode.abs() % Colors.primaries.length;
  return Colors.primaries[i];
}

/// Squad tab hook: surface friends and one-tap challenges next to the pitch.
class TeamFriendsDuelStrip extends StatelessWidget {
  const TeamFriendsDuelStrip({super.key, required this.teamName});

  final String teamName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<OnlineBloc, OnlineState>(
      buildWhen: (prev, curr) =>
          prev.friends != curr.friends || prev.status != curr.status,
      builder: (context, state) {
        final loading =
            state.status == OnlineStatus.loading && state.friends.isEmpty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.bolt_rounded, color: scheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Play together',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Challenge a friend with “$teamName” in mind — '
                              'they get the invite on Online.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh friends',
                        onPressed: () => context.read<OnlineBloc>().add(
                          OnlineLoadRequested(),
                        ),
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (state.friends.isEmpty)
                    Text(
                      'No friends yet — send requests from Home. '
                      'When someone accepts, tap refresh here or open Online.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    )
                  else
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.friends.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final f = state.friends[index];
                          return _FriendDuelChip(
                            friend: f,
                            scheme: scheme,
                            theme: theme,
                            onTap: () =>
                                showSendOnlineChallengeDialog(context, f),
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

class _FriendDuelChip extends StatelessWidget {
  const _FriendDuelChip({
    required this.friend,
    required this.scheme,
    required this.theme,
    required this.onTap,
  });

  final UserModel friend;
  final ColorScheme scheme;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = friend.username.trim().isEmpty
        ? 'Player'
        : friend.username;
    final avatarUrl = friend.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return SizedBox(
      width: 84,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _teamFriendAvatarColor(label),
                  foregroundColor: Colors.white,
                  backgroundImage:
                      hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: hasAvatar
                      ? null
                      : Text(
                          label.isNotEmpty ? label[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  label.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Challenge',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
