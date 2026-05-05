import 'package:flutter/material.dart';

export 'package:new_project/core/utils/dispose_text_controller_next_frame.dart';

Color teamAvatarColor(String name) {
  final i = name.hashCode.abs() % Colors.primaries.length;
  return Colors.primaries[i];
}
