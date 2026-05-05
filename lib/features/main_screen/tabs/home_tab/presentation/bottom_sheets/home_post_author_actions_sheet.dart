import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_challenge_games.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Author menu for a post (friend request, challenge, delete own post).
void showHomePostAuthorActionsSheet(BuildContext context, PostModel post) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final author = post.userModel.username;
  final state = context.read<HomeBloc>().state;
  final authorIdNorm = post.userModel.id.trim().toLowerCase();
  final alreadyFriend = authorIdNorm.isNotEmpty &&
      state.acceptedFriendUserIds.contains(authorIdNorm);
  final myId =
      Supabase.instance.client.auth.currentUser?.id.trim().toLowerCase();
  final isSelf = myId != null && myId.isNotEmpty && myId == authorIdNorm;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                author,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              if (isSelf) ...[
                Text(
                  'This is your post.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _confirmDeletePost(context, post);
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  label: Text(
                    'Delete post',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ] else ...[
                if (alreadyFriend)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.people_rounded, color: scheme.primary),
                    title: const Text('Friends'),
                    subtitle: Text(
                      'You are already connected — no new request needed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.read<HomeBloc>().add(
                            HomeSendFriendRequest(
                              userModel: post.userModel,
                            ),
                          );
                    },
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Send friend request'),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _showChallengeGamePicker(context, post);
                  },
                  icon: const Icon(Icons.sports_esports_rounded),
                  label: const Text('Send challenge'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

void _confirmDeletePost(BuildContext context, PostModel post) {
  final pid = post.id.trim();
  if (pid.isEmpty) return;
  final scheme = Theme.of(context).colorScheme;
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This removes your post and its comments for everyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<HomeBloc>().add(
                    HomePostDeleteRequested(postId: pid),
                  );
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

void _showChallengeGamePicker(BuildContext context, PostModel post) {
  var selectedId = OnlineChallengeGames.penaltyShootout;
  final homeContext = context;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final target = post.userModel.username.trim().isEmpty
      ? 'this player'
      : post.userModel.username.trim();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (_, setDialogState) {
          return AlertDialog(
            title: Text('Challenge $target'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(game.icon, size: 22),
                      title: Text(game.title),
                      selected: selectedId == game.id,
                      selectedTileColor:
                          scheme.primaryContainer.withValues(alpha: 0.35),
                      onTap: () => setDialogState(() => selectedId = game.id),
                      trailing: Icon(
                        selectedId == game.id
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selectedId == game.id
                            ? scheme.primary
                            : scheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  homeContext.read<HomeBloc>().add(
                        HomeSendChallenge(
                          userModel: post.userModel,
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
