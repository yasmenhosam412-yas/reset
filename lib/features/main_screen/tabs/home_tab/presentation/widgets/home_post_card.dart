import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/post_reactions_codec.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/post_reactions.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/repost_post_to_feed.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/shared_post_marker.dart';

class HomePostCard extends StatelessWidget {
  const HomePostCard({
    super.key,
    required this.post,
    required this.myReaction,
    required this.onOpenComments,
    this.onAuthorTap,
  });

  final PostModel post;
  final String? myReaction;
  final VoidCallback onOpenComments;
  final VoidCallback? onAuthorTap;

  void _openReactionPicker(BuildContext context) {
    if (post.id.isEmpty) return;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = myReaction;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'React',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap again to remove your reaction.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 14,
                  alignment: WrapAlignment.spaceBetween,
                  children: kPostReactionDisplayOrder.map((key) {
                    final selected = current == key;
                    final accent = postReactionColor(key, scheme);
                    return InkWell(
                      onTap: () {
                        final next = selected ? null : key;
                        context.read<HomeBloc>().add(
                              HomePostReactionRequested(
                                postId: post.id,
                                reaction: next,
                              ),
                            );
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 72,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? accent.withValues(alpha: 0.22)
                                    : scheme.surfaceContainerHighest
                                        .withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? accent.withValues(alpha: 0.55)
                                      : scheme.outlineVariant
                                          .withValues(alpha: 0.35),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                postReactionIcon(key),
                                size: 28,
                                color: accent,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              postReactionLabel(key),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? accent
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final author = post.userModel.username;
    final avatarUrl = post.userModel.avatarUrl?.trim();
    final hasAvatarImage = avatarUrl != null && avatarUrl.isNotEmpty;
    final breakdown = postReactionCountsSorted(post);
    final totalReactions = post.likes.where((e) => postReactionEntryUserId(e).isNotEmpty).length;
    final isShared = homePostIsSharedRepost(post);
    final feedImageUrl = homePostResolvedImageUrl(post);
    final displayContent = homePostDisplayContent(post);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorHeader(
              author: author,
              timeAgo: homeFeedTimeAgo(post.createdAt),
              theme: theme,
              scheme: scheme,
              hasAvatarImage: hasAvatarImage,
              avatarUrl: avatarUrl,
              onAuthorTap: onAuthorTap,
            ),
            if (isShared) ...[
              const SizedBox(height: 10),
              _SharedPostBadge(theme: theme, scheme: scheme),
            ],
            if (feedImageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    feedImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: scheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(displayContent, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: post.id.isEmpty
                        ? null
                        : () => _openReactionPicker(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (breakdown.isEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.add_reaction_outlined,
                                  size: 22,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'React',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (final e in breakdown)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: myReaction == e.key
                                          ? postReactionColor(e.key, scheme)
                                              .withValues(alpha: 0.14)
                                          : scheme.surfaceContainerHighest
                                              .withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: myReaction == e.key
                                            ? postReactionColor(
                                                e.key,
                                                scheme,
                                              ).withValues(alpha: 0.45)
                                            : scheme.outlineVariant
                                                .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          postReactionIcon(e.key),
                                          size: 18,
                                          color: postReactionColor(
                                            e.key,
                                            scheme,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${e.value}',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Text(
                                    totalReactions == 1
                                        ? '1 reaction'
                                        : '$totalReactions reactions',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onOpenComments,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.comments.length}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (homePostRepostAllowed(post)) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Repost to home feed',
                    child: InkWell(
                      onTap: post.id.isEmpty
                          ? null
                          : () =>
                              showRepostPostToFeedDialog(context, post: post),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Icon(
                          Icons.repeat_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedPostBadge extends StatelessWidget {
  const _SharedPostBadge({
    required this.theme,
    required this.scheme,
  });

  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.secondaryContainer.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.repeat_rounded,
              size: 16,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              'Shared',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSecondaryContainer,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({
    required this.author,
    required this.timeAgo,
    required this.theme,
    required this.scheme,
    required this.hasAvatarImage,
    required this.avatarUrl,
    required this.onAuthorTap,
  });

  final String author;
  final String timeAgo;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool hasAvatarImage;
  final String? avatarUrl;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: homeFeedAvatarColor(author),
            foregroundColor: Colors.white,
            backgroundImage: hasAvatarImage && (avatarUrl?.isNotEmpty ?? false)
                ? NetworkImage(avatarUrl!)
                : null,
            onBackgroundImageError: hasAvatarImage ? (_, _) {} : null,
            child: hasAvatarImage
                ? null
                : Text(
                    author.isNotEmpty ? author[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (timeAgo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onAuthorTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (onAuthorTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAuthorTap,
        borderRadius: BorderRadius.circular(12),
        child: row,
      ),
    );
  }
}
