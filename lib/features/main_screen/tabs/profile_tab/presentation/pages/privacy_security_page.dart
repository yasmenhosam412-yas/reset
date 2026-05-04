import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// In-app summary of how the app handles account data and safety expectations.
/// Replace with your lawyer-reviewed policy before production if required.
class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & security'),
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
            'Your account and data',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _Paragraph(
            text:
                'You sign in with email and password. Your session is managed '
                'securely by our backend (Supabase Auth). We store the profile '
                'information you choose to save, such as display name and avatar.',
            scheme: scheme,
            theme: theme,
          ),
          const SizedBox(height: 20),
          Text(
            'What we use your data for',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text:
                'Home and social features: posts, comments, likes, and friend requests.',
          ),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text:
                'Online play: challenges, match state, and related game records.',
          ),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text:
                'Team mode: squad lineup, skill points, daily challenges, and leaderboards.',
          ),
          const SizedBox(height: 20),
          Text(
            'Friends and visibility',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Paragraph(
            text:
                'When you accept a friend request, each of you can interact in '
                'features that require friends (for example invites and team '
                'battles). Declined requests are not shown as active connections.',
            scheme: scheme,
            theme: theme,
          ),
          const SizedBox(height: 20),
          Text(
            'Security tips',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text: 'Use a strong, unique password for this app.',
          ),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text: 'Sign out from Profile when using a shared device.',
          ),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text:
                'If you suspect unauthorized access, change your password and sign out everywhere from your account provider if available.',
          ),
          const SizedBox(height: 20),
          Text(
            'Questions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Paragraph(
            text:
                'This screen is a product summary, not a legal contract. For '
                'formal terms or data requests, contact the team that operates '
                'this app and publish a full privacy policy where your users expect it.',
            scheme: scheme,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({
    required this.text,
    required this.scheme,
    required this.theme,
  });

  final String text;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.45,
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({
    required this.text,
    required this.scheme,
    required this.theme,
  });

  final String text;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
