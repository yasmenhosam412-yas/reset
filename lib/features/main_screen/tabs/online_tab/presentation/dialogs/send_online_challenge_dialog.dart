import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';

const int _kPenaltyGameId = 1;
const int _kRimShotGameId = 2;
const int _kFantasyGameId = 3;

/// Game picker + send invite (uses [OnlineBloc] from context).
void showSendOnlineChallengeDialog(BuildContext context, UserModel friend) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final bloc = context.read<OnlineBloc>();
  final display = friend.username.trim().isEmpty
      ? 'this friend'
      : friend.username;

  var selectedId = _kPenaltyGameId;

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
                    'Choose a game',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ChallengeGameTile(
                    gameId: _kPenaltyGameId,
                    title: 'Penalty shootout',
                    icon: Icons.sports_soccer_rounded,
                    selectedId: selectedId,
                    scheme: scheme,
                    onTap: () => setState(() => selectedId = _kPenaltyGameId),
                  ),
                  _ChallengeGameTile(
                    gameId: _kRimShotGameId,
                    title: 'Rim shot',
                    icon: Icons.sports_basketball_rounded,
                    selectedId: selectedId,
                    scheme: scheme,
                    onTap: () => setState(() => selectedId = _kRimShotGameId),
                  ),
                  _ChallengeGameTile(
                    gameId: _kFantasyGameId,
                    title: 'Fantasy cards',
                    icon: Icons.auto_awesome_rounded,
                    selectedId: selectedId,
                    scheme: scheme,
                    onTap: () => setState(() => selectedId = _kFantasyGameId),
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
