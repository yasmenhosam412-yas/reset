import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/legal/app_legal_urls.dart';
import 'package:new_project/core/l10n/l10n.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacySecurity),
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
            l10n.privacyYourAccountData,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _Paragraph(
            text: l10n.privacyYourAccountDataBody,
            scheme: scheme,
            theme: theme,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.privacyDataUsageTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text: l10n.privacyDataUsageHome,
          ),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text: l10n.privacyDataUsageOnline,
          ),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text: l10n.privacyDataUsageTeam,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.privacyFriendsVisibilityTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Paragraph(
            text: l10n.privacyFriendsVisibilityBody,
            scheme: scheme,
            theme: theme,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.privacySecurityTipsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text: l10n.privacyTipStrongPassword,
          ),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text: l10n.privacyTipSignOutShared,
          ),
          _Bullet(
            scheme: scheme,
            theme: theme,
            text: l10n.privacyTipUnauthorizedAccess,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.privacySafetyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Paragraph(
            text: l10n.privacySafetyBody(AppLegalUrls.supportEmail),
            scheme: scheme,
            theme: theme,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.privacyQuestionsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Paragraph(
            text: l10n.privacyQuestionsBody,
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
