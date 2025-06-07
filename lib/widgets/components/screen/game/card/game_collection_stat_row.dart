// lib/widgets/components/screen/game/card/game_collection_stat_row.dart

/// 该文件定义了 GameCollectionStatRow 组件，一个用于显示游戏收藏统计信息的行。
/// GameCollectionStatRow 展示收藏标签、数量、百分比和进度条。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具

/// `GameCollectionStatRow` 类：显示游戏收藏统计信息的行组件。
///
/// 该组件展示收藏标签、数量、百分比、进度条和对应图标。
class GameCollectionStatRow extends StatelessWidget {
  final String label; // 统计标签
  final int count; // 统计数量
  final double percent; // 占总数的百分比
  final Color color; // 统计项的主题颜色
  final IconData icon; // 统计项的图标

  /// 构造函数。
  ///
  /// [label]：标签。
  /// [count]：数量。
  /// [percent]：百分比。
  /// [color]：颜色。
  /// [icon]：图标。
  const GameCollectionStatRow({
    super.key,
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
    required this.icon,
  });

  /// 构建游戏收藏统计行。
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withSafeOpacity(0.1), // 背景色
        borderRadius: BorderRadius.circular(12), // 圆角
        border: Border.all(
          color: color.withSafeOpacity(0.3), // 边框颜色
          width: 1, // 边框宽度
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 内边距
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 主轴两端对齐
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color), // 图标
                  const SizedBox(width: 8), // 间距
                  Text(
                    label, // 标签文本
                    style: TextStyle(
                      fontSize: 14, // 字号
                      fontWeight: FontWeight.w500, // 字重
                      color: Colors.grey[800], // 颜色
                    ),
                  ),
                ],
              ),
              Text(
                count.toString(), // 数量文本
                style: TextStyle(
                  fontWeight: FontWeight.bold, // 字重
                  fontSize: 14, // 字号
                  color: color, // 颜色
                ),
              ),
            ],
          ),

          const SizedBox(height: 8), // 间距

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6), // 圆角
              boxShadow: [
                // 阴影
                BoxShadow(
                  color: Colors.black.withSafeOpacity(0.05), // 阴影颜色
                  blurRadius: 1, // 模糊半径
                  offset: const Offset(0, 1), // 偏移量
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6), // 裁剪圆角
              child: LinearProgressIndicator(
                value: percent / 100, // 进度值
                backgroundColor: Colors.grey.shade200, // 背景色
                valueColor: AlwaysStoppedAnimation<Color>(color), // 颜色
                minHeight: 6, // 最小高度
              ),
            ),
          ),

          const SizedBox(height: 4), // 间距

          Align(
            alignment: Alignment.centerRight, // 居右对齐
            child: Text(
              '${percent.toStringAsFixed(1)}%', // 百分比文本
              style: TextStyle(
                fontSize: 12, // 字号
                color: Colors.grey[600], // 颜色
              ),
            ),
          ),
        ],
      ),
    );
  }
}
