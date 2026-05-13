import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/post_reactions_codec.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/post_reactions.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/repost_post_to_feed.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/shared_post_marker.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/home_post_media_attachment.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/widgets/post_text_with_links.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final l10n = context.l10n;

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
                  l10n.react,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.tapAgainToRemoveReaction,
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
                                    : scheme.surfaceContainerHighest.withValues(
                                        alpha: 0.65,
                                      ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? accent.withValues(alpha: 0.55)
                                      : scheme.outlineVariant.withValues(
                                          alpha: 0.35,
                                        ),
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
                              postReactionLabelL10n(l10n, key),
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
    final totalReactions = post.likes
        .where((e) => postReactionEntryUserId(e).isNotEmpty)
        .length;
    final isShared = homePostIsSharedRepost(post);
    final feedImageUrl = homePostResolvedImageUrl(post);
    final displayContent = homePostDisplayContent(post);
    final typeStyle = _postTypeStyle(post.postType, scheme);
    final l10n = context.l10n;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: typeStyle.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container(
            //   height: 4,
            //   margin: const EdgeInsets.only(bottom: 10),
            //   decoration: BoxDecoration(
            //     color: typeStyle.accentColor.withValues(alpha: 0.9),
            //     borderRadius: BorderRadius.circular(999),
            //   ),
            // ),
            _AuthorHeader(
              author: author,
              timeAgo: homeFeedTimeAgo(post.createdAt),
              theme: theme,
              scheme: scheme,
              hasAvatarImage: hasAvatarImage,
              avatarUrl: avatarUrl,
              onAuthorTap: onAuthorTap,
            ),
            if (post.postType != 'post') ...[
              const SizedBox(height: 8),
              _PostTypeBadge(
                theme: theme,
                scheme: scheme,
                postType: post.postType,
                accentColor: typeStyle.accentColor,
                backgroundColor: typeStyle.badgeBackgroundColor,
              ),
            ],
            if (isShared) ...[
              const SizedBox(height: 8),
              _SharedPostBadge(theme: theme, scheme: scheme),
            ],
            if (displayContent.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              PostTextWithLinks(
                text: displayContent,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
              ),
            ],
            if (feedImageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: HomePostMediaAttachment(
                  url: feedImageUrl,
                  scheme: scheme,
                ),
              ),
            ],
            if (post.postType == 'ads' &&
                (post.adLink?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openAdLink(context, post.adLink!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.visitAd),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: post.id.isEmpty
                          ? null
                          : () => _openReactionPicker(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: breakdown.isEmpty
                            ? Row(
                                children: [
                                  Icon(
                                    Icons.add_reaction_outlined,
                                    size: 20,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.react,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final e in breakdown) ...[
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: myReaction == e.key
                                              ? postReactionColor(
                                                  e.key,
                                                  scheme,
                                                ).withValues(alpha: 0.16)
                                              : scheme.surface.withValues(
                                                  alpha: 0.78,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: myReaction == e.key
                                                ? postReactionColor(
                                                    e.key,
                                                    scheme,
                                                  ).withValues(alpha: 0.42)
                                                : scheme.outlineVariant
                                                      .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              postReactionIcon(e.key),
                                              size: 16,
                                              color: postReactionColor(
                                                e.key,
                                                scheme,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
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
                                    ],
                                    Text(
                                      l10n.homeReactionsCount(totalReactions),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _ActionPill(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.comments.length}',
                    scheme: scheme,
                    onTap: onOpenComments,
                  ),
                  if (homePostRepostAllowed(post)) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: l10n.repostToHomeFeed,
                      child: _ActionPill(
                        icon: Icons.repeat_rounded,
                        scheme: scheme,
                        onTap: post.id.isEmpty
                            ? null
                            : () => showRepostPostToFeedDialog(
                                context,
                                post: post,
                              ),
                      ),
                    ),
                  ],
                  if (post.id.trim().isNotEmpty) ...[
                    const SizedBox(width: 6),
                    BlocSelector<HomeBloc, HomeState, bool>(
                      selector: (s) {
                        final id = post.id.trim();
                        return id.isNotEmpty && s.savedPostIds.contains(id);
                      },
                      builder: (context, isSaved) {
                        return Tooltip(
                          message: isSaved
                              ? l10n.removeFromSaves
                              : l10n.saveToSaves,
                          child: _ActionPill(
                            icon: isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            scheme: scheme,
                            onTap: () {
                              context.read<HomeBloc>().add(
                                HomePostSaveToggled(
                                  postId: post.id,
                                  saved: !isSaved,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdLink(BuildContext context, String rawLink) async {
    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.invalidAdLink)));
      return;
    }
    // Some Android devices/emulators report no external component.
    // Try multiple modes before failing.
    final opened =
        await _tryLaunchUrl(uri, LaunchMode.externalApplication) ||
        await _tryLaunchUrl(uri, LaunchMode.platformDefault) ||
        await _tryLaunchUrl(uri, LaunchMode.inAppBrowserView);
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpenAdLink)));
    }
  }

  Future<bool> _tryLaunchUrl(Uri uri, LaunchMode mode) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.scheme,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final ColorScheme scheme;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SharedPostBadge extends StatelessWidget {
  const _SharedPostBadge({required this.theme, required this.scheme});

  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              l10n.shared,
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

class _PostTypeBadge extends StatelessWidget {
  const _PostTypeBadge({
    required this.theme,
    required this.scheme,
    required this.postType,
    required this.accentColor,
    required this.backgroundColor,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final String postType;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final normalized = postType.trim().toLowerCase();
    final l10n = context.l10n;
    final (icon, label) = switch (normalized) {
      'announcement' => (Icons.campaign_outlined, l10n.postTypeAnnouncement),
      'celebration' => (Icons.celebration_outlined, l10n.postTypeCelebration),
      'ads' => (Icons.storefront_outlined, l10n.postTypeAds),
      _ => (Icons.edit_note_rounded, l10n.postTypePost),
    };
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({Color accentColor, Color borderColor, Color badgeBackgroundColor})
_postTypeStyle(String postType, ColorScheme scheme) {
  final normalized = postType.trim().toLowerCase();
  switch (normalized) {
    case 'announcement':
      return (
        accentColor: Colors.orange.shade800,
        borderColor: Colors.orange.shade200,
        badgeBackgroundColor: Colors.orange.shade50,
      );
    case 'celebration':
      return (
        accentColor: Colors.purple.shade700,
        borderColor: Colors.purple.shade200,
        badgeBackgroundColor: Colors.purple.shade50,
      );
    case 'ads':
      return (
        accentColor: Colors.teal.shade700,
        borderColor: Colors.teal.shade200,
        badgeBackgroundColor: Colors.teal.shade50,
      );
    default:
      return (
        accentColor: scheme.primary,
        borderColor: scheme.outlineVariant.withValues(alpha: 0.35),
        badgeBackgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
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
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
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
