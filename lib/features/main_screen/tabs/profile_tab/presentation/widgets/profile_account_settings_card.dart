import 'package:flutter/material.dart';

class ProfileAccountSettingsCard extends StatelessWidget {
  const ProfileAccountSettingsCard({super.key, required this.scheme});

  final ColorScheme scheme;

  static const _items = <(IconData, String)>[
    (Icons.lock_outline_rounded, 'Privacy & security'),
    (Icons.palette_outlined, 'Appearance'),
    (Icons.help_outline_rounded, 'Help & support'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: Icon(_items[i].$1, color: scheme.primary),
              title: Text(_items[i].$2),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ],
        ],
      ),
    );
  }
}
