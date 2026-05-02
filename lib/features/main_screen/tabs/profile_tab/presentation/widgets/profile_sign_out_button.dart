import 'package:flutter/material.dart';

class ProfileSignOutButton extends StatelessWidget {
  const ProfileSignOutButton({
    super.key,
    required this.scheme,
    required this.onConfirmed,
  });

  final ColorScheme scheme;
  final Future<void> Function() onConfirmed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: scheme.error,
        side: BorderSide(color: scheme.error.withValues(alpha: 0.55)),
      ),
      onPressed: () => _confirmAndSignOut(context),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Sign out'),
    );
  }

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to use your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (!context.mounted || ok != true) return;
    await onConfirmed();
  }
}
