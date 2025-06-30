// lib/models/game/game/enrich_game_status.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/preset/simple_color_theme.dart';

import 'game.dart';

class EnrichGameStatus implements SimpleColorThemeExtension {
  final String? status;
  EnrichGameStatus({
    required this.status,
  });

  @override
  Color getBackgroundColor() => getGameStatusColor(status);

  @override
  Color getTextColor() => Colors.white;

  @override
  String getTextLabel() => getGameStatusLabel(status);

  /// 获取游戏状态的显示属性。
  ///
  /// [approvalStatus]：审核状态字符串。
  /// 返回包含文本和颜色的 Map。
  static String getGameStatusLabel(String? approvalStatus) {
    switch (approvalStatus?.toLowerCase()) {
      case Game.gameStatusPending:
        return '审核中';
      case Game.gameStatusApproved:
        return '已通过';
      case Game.gameStatusRejected:
        return '已拒绝';
      default:
        return '未知';
    }
  }

  /// 获取游戏状态的显示属性。
  ///
  /// [approvalStatus]：审核状态字符串。
  /// 返回包含文本和颜色的 Map。
  static Color getGameStatusColor(String? approvalStatus) {
    switch (approvalStatus?.toLowerCase()) {
      case Game.gameStatusPending:
        return Colors.orange;
      case Game.gameStatusApproved:
        return Colors.green;
      case Game.gameStatusRejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  factory EnrichGameStatus.fromStatus(String? status) {
    return EnrichGameStatus(
      status: status,
    );
  }
}
