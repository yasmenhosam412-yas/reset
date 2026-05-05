import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_challenge_games.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';

/// Game picker + send invite (uses [OnlineBloc] from context).
void showSendOnlineChallengeDialog(BuildContext context, UserModel friend) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final bloc = context.read<OnlineBloc>();
  final display = friend.username.trim().isEmpty
      ? 'this friend'
      : friend.username;

  var selectedId = OnlineChallengeGames.penaltyShootout;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text('Challenge $display'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Win the match for +10 team skill points (Team tab). '
                    'Your friend loses nothing if they do not win.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose a game',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final game in OnlineChallengeGames.all)
                    _ChallengeGameTile(
                      gameId: game.id,
                      title: game.title,
                      icon: game.icon,
                      selectedId: selectedId,
                      scheme: scheme,
                      onTap: () => setState(() => selectedId = game.id),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  bloc.add(
                    OnlineSendChallengeRequested(
                      friend: friend,
                      gameId: selectedId,
                    ),
                  );
                },
                child: const Text('Send'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ChallengeGameTile extends StatelessWidget {
  const _ChallengeGameTile({
    required this.gameId,
    required this.title,
    required this.icon,
    required this.selectedId,
    required this.scheme,
    required this.onTap,
  });

  final int gameId;
  final String title;
  final IconData icon;
  final int selectedId;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = gameId == selectedId;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 22),
      title: Text(title),
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
      onTap: onTap,
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? scheme.primary : scheme.outline,
      ),
    );
  }
}
