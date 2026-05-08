import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/bottom_sheets/edit_home_post_sheet.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_challenge_games.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/online_game_titles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Author menu for a post (friend request, challenge, delete own post).
void showHomePostAuthorActionsSheet(BuildContext context, PostModel post) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final author = post.userModel.username;
  final l10n = context.l10n;
  final state = context.read<HomeBloc>().state;
  final authorIdNorm = post.userModel.id.trim().toLowerCase();
  final alreadyFriend =
      authorIdNorm.isNotEmpty &&
      state.acceptedFriendUserIds.contains(authorIdNorm);
  final myId = Supabase.instance.client.auth.currentUser?.id
      .trim()
      .toLowerCase();
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
                  l10n.thisIsYourPost,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    showEditHomePostSheet(context, post);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.editPost),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _confirmDeletePost(context, post);
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  label: Text(
                    l10n.deletePost,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ] else ...[
                if (alreadyFriend)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.people_rounded, color: scheme.primary),
                    title: Text(l10n.friends),
                    subtitle: Text(
                      l10n.alreadyConnectedNoRequestNeeded,
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
                        HomeSendFriendRequest(userModel: post.userModel),
                      );
                    },
                    icon: const Icon(Icons.person_add_rounded),
                    label: Text(l10n.sendFriendRequest),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _showChallengeGamePicker(context, post);
                  },
                  icon: const Icon(Icons.sports_esports_rounded),
                  label: Text(l10n.sendChallenge),
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
        title: Text(context.l10n.deletePostQuestion),
        content: Text(context.l10n.deletePostMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
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
            child: Text(context.l10n.delete),
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
      ? context.l10n.thisPlayer
      : post.userModel.username.trim();
  final l10n = context.l10n;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (_, setDialogState) {
          return AlertDialog(
            title: Text(l10n.challengeTarget(target)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.challengeInfoBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.chooseAGame,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final game in OnlineChallengeGames.all)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(game.icon, size: 22),
                      title: Text(onlineGameTitleL10n(l10n, game.id)),
                      selected: selectedId == game.id,
                      selectedTileColor: scheme.primaryContainer.withValues(
                        alpha: 0.35,
                      ),
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
                child: Text(l10n.cancel),
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
                child: Text(l10n.send),
              ),
            ],
          );
        },
      );
    },
  );
}
