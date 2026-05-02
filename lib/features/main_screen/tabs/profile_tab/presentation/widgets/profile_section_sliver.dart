import 'package:flutter/material.dart';

Widget profileSectionTitleSliver(
  ThemeData theme,
  String title, {
  double top = 22,
}) {
  return SliverPadding(
    padding: EdgeInsets.fromLTRB(20, top, 20, 8),
    sliver: SliverToBoxAdapter(
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
