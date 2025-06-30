// lib/widgets/components/screen/game/card/game_status_overlay.dart

/// 该文件定义了 GameApprovalStatusOverlay 组件，一个用于显示游戏审核状态的叠加层。
/// GameApprovalStatusOverlay 展示游戏审核状态徽章、重新提交按钮和拒绝原因。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/game/game/game.dart'; // 导入游戏模型
import 'package:suxingchahui/models/game/game/game_extension.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具

/// `GameApprovalStatusOverlay` 类：游戏审核状态叠加层组件。
///
/// 该组件在游戏卡片上叠加显示游戏的审核状态徽章、重新提交按钮（针对被拒绝状态）
/// 和拒绝原因（如果存在）。
class GameApprovalStatusOverlay extends StatelessWidget {
  final Game game; // 游戏数据
  final VoidCallback onResubmit; // 重新提交按钮点击回调
  final Function(String) onShowReviewComment; // 显示拒绝原因回调

  /// 构造函数。
  ///
  /// [game]：游戏数据。
  /// [onResubmit]：重新提交回调。
  /// [onShowReviewComment]：显示拒绝评论回调。
  const GameApprovalStatusOverlay({
    super.key,
    required this.game,
    required this.onResubmit,
    required this.onShowReviewComment,
  });

  /// 构建游戏审核状态叠加层。
  @override
  Widget build(BuildContext context) {
    final statusInfo = game.enrichStatus; // 获取状态显示信息
    final bool isRejected = game.approvalStatus?.toLowerCase() ==
        Game.gameStatusRejected; // 判断是否为被拒绝状态
    final bool showComment = isRejected &&
        game.reviewComment != null &&
        game.reviewComment!.isNotEmpty; // 是否显示拒绝原因

    return Stack(
      children: [
        Positioned(
          top: 6, // 顶部偏移
          left: 6, // 左侧偏移
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // 内边距
            decoration: BoxDecoration(
                color: statusInfo.backgroundColor.withSafeOpacity(0.85), // 背景色
                borderRadius: BorderRadius.circular(12), // 圆角
                boxShadow: [
                  // 阴影
                  BoxShadow(
                    color: Colors.black.withSafeOpacity(0.2), // 阴影颜色
                    blurRadius: 2, // 模糊半径
                    offset: const Offset(0, 1), // 偏移量
                  )
                ]),
            child: Text(
              statusInfo.textLabel, // 状态文本
              style: const TextStyle(
                color: Colors.white, // 颜色
                fontWeight: FontWeight.bold, // 字重
                fontSize: 10, // 字号
              ),
            ),
          ),
        ),
        if (isRejected) // 被拒绝状态时显示重新提交按钮
          Positioned(
            bottom: 8, // 底部偏移
            right: 8, // 右侧偏移
            child: Tooltip(
              message: '重新提交审核', // 提示
              child: FloatingActionButton.small(
                heroTag: 'resubmit_overlay_${game.id}', // 唯一 Hero 标签
                onPressed: onResubmit, // 点击回调
                backgroundColor: Colors.blue.shade600, // 背景色
                child:
                    const Icon(Icons.keyboard_return_rounded, size: 18), // 图标
              ),
            ),
          ),
        if (showComment) // 显示拒绝原因叠加层
          Positioned(
            bottom: isRejected ? 55 : 8, // 底部偏移，根据是否被拒绝调整
            left: 8, // 左侧偏移
            right: 8, // 右侧偏移
            child: GestureDetector(
              onTap: () => onShowReviewComment(game.reviewComment!), // 点击回调
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5), // 内边距
                decoration: BoxDecoration(
                    color: Colors.white.withSafeOpacity(0.95), // 背景色
                    borderRadius: BorderRadius.circular(6), // 圆角
                    border: Border.all(
                        color: Colors.red.shade200, width: 0.5), // 边框
                    boxShadow: [
                      // 阴影
                      BoxShadow(
                        color: Colors.black.withSafeOpacity(0.1), // 阴影颜色
                        blurRadius: 3, // 模糊半径
                        offset: const Offset(0, 1), // 偏移量
                      )
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
                  mainAxisSize: MainAxisSize.min, // 垂直方向适应内容
                  children: [
                    Text(
                      '拒绝原因:', // 文本
                      style: TextStyle(
                        fontWeight: FontWeight.bold, // 字重
                        color: Colors.red.shade800, // 颜色
                        fontSize: 11, // 字号
                      ),
                    ),
                    const SizedBox(height: 2), // 间距
                    Text(
                      game.reviewComment!, // 拒绝原因文本
                      style: const TextStyle(
                          fontSize: 10, color: Colors.black87), // 样式
                      maxLines: 2, // 最大行数
                      overflow: TextOverflow.ellipsis, // 溢出显示省略号
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
