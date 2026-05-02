import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';

class HomePostCard extends StatelessWidget {
  const HomePostCard({
    super.key,
    required this.post,
    required this.likedByMe,
    required this.onOpenComments,
    this.onAuthorTap,
  });

  final PostModel post;
  final bool likedByMe;
  final VoidCallback onOpenComments;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final author = post.userModel.username;
    final avatarUrl = post.userModel.avatarUrl?.trim();
    final hasAvatarImage = avatarUrl != null && avatarUrl.isNotEmpty;

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
            if (post.postImage.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    post.postImage,
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
            Text(post.postContent, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: post.id.isEmpty
                      ? null
                      : () => context.read<HomeBloc>().add(
                            HomePostLikeRequested(postId: post.id),
                          ),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          likedByMe
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 22,
                          color: likedByMe ? scheme.primary : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes.length}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: likedByMe
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onOpenComments,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              ],
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
