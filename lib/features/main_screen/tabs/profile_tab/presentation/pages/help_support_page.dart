import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/l10n/l10n.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpSupport),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            l10n.helpGetStarted,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: l10n.helpQMainTabs,
            answer: l10n.helpAMainTabs,
          ),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: l10n.helpQAddFriends,
            answer: l10n.helpAAddFriends,
          ),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: l10n.helpQTeamTab,
            answer: l10n.helpATeamTab,
          ),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: l10n.helpQSaveSquad,
            answer: l10n.helpASaveSquad,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.helpTroubleshooting,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: l10n.helpQStuck,
            answer: l10n.helpAStuck,
          ),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: l10n.helpQSignedOut,
            answer: l10n.helpASignedOut,
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.contact,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "yasmenhosam412@gmail.com",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.scheme,
    required this.theme,
    required this.question,
    required this.answer,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
