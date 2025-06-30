// lib/models/user/user/user_type.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';

class EnrichUserGroup implements BackgroundColorExtension {
  final String userId;

  const EnrichUserGroup({
    required this.userId,
  });

  factory EnrichUserGroup.fromUserId(String userId) => EnrichUserGroup(userId: userId);

  // 按用户分组时返回随机用户颜色
  static final List<Color> _userColors = [
    Colors.blue.shade300,
    Colors.red.shade300,
    Colors.green.shade300,
    Colors.purple.shade300,
    Colors.orange.shade300,
    Colors.teal.shade300,
    Colors.indigo.shade300,
    Colors.pink.shade300
  ];

  static getUserGroupColor(String userId) =>
      _userColors[userId.hashCode % _userColors.length];

  @override
  Color getBackgroundColor() => getUserGroupColor(userId);
}
