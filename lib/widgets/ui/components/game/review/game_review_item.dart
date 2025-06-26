// lib/widgets/ui/components/game/review/game_review_item.dart

/// 该文件定义了 GameReviewItemWidget 组件，一个显示游戏评论项的 UI 组件。
/// GameReviewItemWidget 展示评论者的信息、评论状态、评分、评论文本和笔记。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:suxingchahui/constants/game/game_constants.dart'; // 游戏常量
import 'package:suxingchahui/models/game/game_collection_review.dart'; // 游戏收藏评论模型
import 'package:suxingchahui/models/user/user.dart'; // 用户模型
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息 Provider
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 日期时间格式化工具
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展
import 'package:suxingchahui/models/game/game_collection_item.dart'; // 游戏收藏模型

/// `GameReviewItemWidget` 类：游戏评论项组件。
///
/// 该组件展示游戏评论的详细信息，包括评论者、评论状态、评分、评论内容和笔记。
class GameReviewItemWidget extends StatelessWidget {
  final User? currentUser; // 当前登录用户
  final GameCollectionReviewEntry review; // 游戏评论条目
  final UserFollowService followService; // 用户关注服务实例
  final UserInfoService infoService; // 用户信息 Provider 实例

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [currentUser]：当前登录用户。
  /// [review]：游戏评论条目。
  /// [followService]：用户关注服务实例。
  /// [infoProvider]：用户信息 Provider 实例。
  const GameReviewItemWidget({
    super.key,
    required this.currentUser,
    required this.review,
    required this.followService,
    required this.infoService,
  });

  /// 构建游戏评论项 UI。
  ///
  /// [context]：Build 上下文。
  /// 返回一个 `Padding` 组件，包含评论的各项信息。
  @override
  Widget build(BuildContext context) {
    final String userId = review.userId; // 评论用户 ID
    final DateTime updateTime = review.updateTime; // 更新时间
    final double? rating = review.rating; // 评分
    final String? reviewText = review.reviewContent; // 评论文本
    final String status = review.status; // 评论状态
    final String? notesText = review.notes; // 笔记文本

    final statusTheme = GameCollectionStatusUtils.getTheme(status); // 获取状态主题
    final statusLabel = statusTheme.text; // 状态标签文本
    final statusIcon = statusTheme.icon; // 状态图标
    final statusColor = statusTheme.textColor; // 状态颜色

    return Padding(
      // 外层内边距
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        // 垂直布局
        crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
        children: [
          Row(
            // 水平布局
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 两端对齐
            crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
            children: [
              Expanded(
                  // 扩展组件
                  child: UserInfoBadge(
                      // 用户信息徽章
                      followService: followService,
                      infoService: infoService,
                      currentUser: currentUser,
                      targetUserId: userId,
                      showFollowButton: false,
                      mini: true)),
              const SizedBox(width: 8), // 水平间距
              Chip(
                // 标签芯片
                avatar: Icon(statusIcon, size: 16, color: statusColor), // 图标
                label: Text(statusLabel, // 文本
                    style: TextStyle(fontSize: 11, color: statusColor)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 0), // 内边距
                backgroundColor: statusColor.withSafeOpacity(0.1), // 背景颜色
                visualDensity: VisualDensity.compact, // 视觉密度
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap, // 点击目标大小
                shape: RoundedRectangleBorder(
                  // 形状
                  borderRadius: BorderRadius.circular(20.0), // 圆角
                  side:
                      BorderSide(color: statusColor.withSafeOpacity(0.3)), // 边框
                ),
              ),
              const SizedBox(width: 8), // 水平间距
              Text(DateTimeFormatter.formatRelative(updateTime), // 相对时间
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          if (status == GameCollectionItem.statusPlayed && rating != null) // 已玩状态且有评分时
            Padding(
              // 评分星级
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Row(
                // 星级水平布局
                children: List.generate(5, (index) {
                  // 生成 5 个星级图标
                  double starValue = rating / 2.0; // 计算星级值
                  IconData starIcon; // 星级图标
                  Color starColor = Colors.amber; // 星级颜色
                  if (index < starValue.floor()) {
                    starIcon = Icons.star_rounded; // 满星
                  } else if (index < starValue && (starValue - index) >= 0.25) {
                    starIcon = Icons.star_half_rounded; // 半星
                  } else {
                    starIcon = Icons.star_border_rounded; // 空星
                    starColor = Colors.grey[400]!; // 空星颜色
                  }
                  return Icon(starIcon, size: 16, color: starColor); // 返回星级图标
                }),
              ),
            ),
          if (reviewText != null && reviewText.isNotEmpty) // 有评论文本时
            Padding(
              // 评论文本
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(reviewText,
                  style: TextStyle(
                      // 评论文本样式
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5)),
            ),
          if (notesText != null && notesText.isNotEmpty) // 有笔记文本时
            Padding(
              // 笔记文本
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                userId == currentUser?.id // 判断是否为当前用户的笔记
                    ? "我做的笔记: $notesText"
                    : "笔记: $notesText",
                style: TextStyle(
                    // 笔记文本样式
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
