import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';

class ProfileAccountSettingsCard extends StatelessWidget {
  const ProfileAccountSettingsCard({
    super.key,
    required this.scheme,
    this.onItemTap,
  });

  final ColorScheme scheme;
  final ValueChanged<int>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <(IconData, String)>[
      (Icons.lock_outline_rounded, l10n.privacySecurity),
      (Icons.star_rounded, l10n.rateTheApp),
      (Icons.help_outline_rounded, l10n.helpSupport),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: Icon(items[i].$1, color: scheme.primary),
              title: Text(items[i].$2),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onItemTap == null
                  ? null
                  : () => onItemTap!(i),
            ),
          ],
        ],
      ),
    );
  }
}
