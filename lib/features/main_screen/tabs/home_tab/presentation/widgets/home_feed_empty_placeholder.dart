import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';

class HomeFeedEmptyPlaceholder extends StatelessWidget {
  const HomeFeedEmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.noPostsYetTapNewPost,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
