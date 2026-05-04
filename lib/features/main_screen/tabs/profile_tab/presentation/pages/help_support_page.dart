import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & support'),
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
            'Get started',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: 'What are the main tabs?',
            answer:
                'Home is your social feed and friends. Online is live challenges '
                'and games with people you know. Team is your six-player squad, '
                'training, and squad battles. Profile is your account, requests, '
                'and settings.',
          ),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: 'How do I add friends?',
            answer:
                'Send a request from Home. The other person accepts under '
                'Profile → Friend requests. You both need an account.',
          ),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: 'How does the Team tab work?',
            answer:
                'Create a team, name your players, then train stats with skill '
                'points. You can run daily challenges, lineup races, friend '
                'spars, and a solo Academy friendly for extra points—check each '
                'card for rules and limits.',
          ),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: 'Why can’t I save my squad?',
            answer:
                'Make sure you are signed in and online. Open Team after login so '
                'your squad can sync to your profile.',
          ),
          const SizedBox(height: 8),
          Text(
            'Troubleshooting',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: 'Something looks stuck',
            answer:
                'Pull to refresh on Profile. For Online, use refresh where shown. '
                'If a game won’t load, go back and open the challenge again.',
          ),
          _FaqTile(
            scheme: scheme,
            theme: theme,
            question: 'I signed out by accident',
            answer:
                'Sign in again from the login screen with the same email. Your '
                'cloud data stays tied to your account.',
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
                    'Contact',
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
