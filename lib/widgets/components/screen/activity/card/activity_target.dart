// lib/widgets/components/screen/activity/card/activity_target.dart

/// 该文件定义了 ActivityTarget 组件，用于显示动态中的目标信息。
/// ActivityTarget 根据动态的目标类型（游戏、帖子、用户）渲染不同的内容。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/constants/activity/activity_constants.dart'; // 动态类型常量
import 'package:suxingchahui/models/activity/user_activity.dart'; // 用户动态模型
import 'package:suxingchahui/models/user/user.dart'; // 用户模型
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息 Provider
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章组件
import 'dart:math' as math; // 数学函数
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart'; // 安全缓存图片组件

/// `ActivityTarget` 类：显示动态目标信息的无状态组件。
///
/// 该组件根据 [activity] 的 [targetType] 渲染游戏、帖子或用户等不同类型的目标信息。
class ActivityTarget extends StatelessWidget {
  final UserActivity activity; // 动态数据
  final User? currentUser; // 当前登录用户
  final UserInfoService infoService; // 用户信息 Provider
  final UserFollowService followService; // 用户关注服务
  final bool isAlternate; // 是否使用交替布局样式
  final double cardHeight; // 卡片高度因子

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [activity]：要显示的动态数据。
  /// [currentUser]：当前登录用户。
  /// [followService]：用户关注服务。
  /// [infoProvider]：用户信息 Provider。
  /// [isAlternate]：是否使用交替布局样式。
  /// [cardHeight]：卡片高度因子。
  const ActivityTarget({
    super.key,
    required this.activity,
    required this.currentUser,
    required this.followService,
    required this.infoService,
    this.isAlternate = false,
    this.cardHeight = 1.0,
  });

  /// 构建 Widget。
  ///
  /// 根据 [activity] 的 [targetType] 返回对应的目标 Widget。
  @override
  Widget build(BuildContext context) {
    Widget targetWidget;

    // 根据动态目标类型选择构建不同的 Widget
    switch (activity.targetType) {
      case ActivityTargetTypeConstants.game: // 目标类型为游戏
        targetWidget = _buildGameTarget(context);
        break;
      case ActivityTargetTypeConstants.post: // 目标类型为帖子
        targetWidget = _buildPostTarget(context);
        break;
      case ActivityTargetTypeConstants.user: // 目标类型为用户
        targetWidget = _buildUserTarget(context);
        break;
      default: // 默认情况
        targetWidget = _buildDefaultUser(context);
    }

    return targetWidget;
  }

  /// 构建游戏目标 Widget。
  ///
  /// [context]：Build 上下文。
  /// 显示游戏标题和封面图片。
  Widget _buildGameTarget(BuildContext context) {
    final title = activity.gameTitle ?? '未知游戏'; // 游戏标题
    final coverImage = activity.gameCoverImage; // 游戏封面图片 URL
    final double imageSize = 60 * cardHeight; // 图片尺寸
    final int memCacheWidth = 320;
    final int memCacheHeight = 200;
    final double borderRadiusValue = 4 * math.sqrt(cardHeight); // 边框圆角值

    return Container(
      padding: EdgeInsets.all(12 * cardHeight), // 内边距
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // 背景颜色
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)), // 边框圆角
        border: Border.all(color: Colors.grey.shade200), // 边框
      ),
      child: Row(
        textDirection:
            isAlternate ? TextDirection.rtl : TextDirection.ltr, // 文本方向
        children: [
          coverImage != null && coverImage.isNotEmpty // 检查封面图片 URL 是否有效
              ? SafeCachedImage(
                  imageUrl: coverImage, // 图片 URL
                  width: imageSize, // 图片宽度
                  height: imageSize, // 图片高度
                  memCacheHeight: memCacheHeight,
                  memCacheWidth: memCacheWidth,
                  fit: BoxFit.cover, // 图片填充模式
                  borderRadius:
                      BorderRadius.circular(borderRadiusValue), // 图片圆角
                )
              : _buildPlaceholderImage(
                  ActivityTargetTypeConstants.game), // 无封面图片时显示占位图
          SizedBox(width: 12 * cardHeight), // 间距
          Expanded(
            child: Text(
              title, // 游戏标题文本
              style: TextStyle(
                fontWeight: FontWeight.bold, // 字体粗细
                fontSize: 16 * math.sqrt(cardHeight), // 字体大小
              ),
              textAlign:
                  isAlternate ? TextAlign.right : TextAlign.left, // 文本对齐方式
              maxLines: 2, // 最大行数
              overflow: TextOverflow.ellipsis, // 溢出时显示省略号
            ),
          ),
        ],
      ),
    );
  }

  /// 构建帖子目标 Widget。
  ///
  /// [context]：Build 上下文。
  /// 显示帖子标题和图标。
  Widget _buildPostTarget(BuildContext context) {
    final title = activity.postTitle ?? '未知帖子'; // 帖子标题

    return Container(
      padding: EdgeInsets.all(12 * cardHeight), // 内边距
      decoration: BoxDecoration(
        color: Colors.blue.shade50, // 背景颜色
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)), // 边框圆角
        border: Border.all(color: Colors.blue.shade100), // 边框
      ),
      child: Row(
        textDirection:
            isAlternate ? TextDirection.rtl : TextDirection.ltr, // 文本方向
        children: [
          Icon(Icons.article, // 帖子图标
              color: Colors.blue.shade700, // 图标颜色
              size: 24 * math.sqrt(cardHeight)), // 图标尺寸
          SizedBox(width: 12 * cardHeight), // 间距
          Expanded(
            child: Text(
              title, // 帖子标题文本
              style: TextStyle(
                fontWeight: FontWeight.bold, // 字体粗细
                fontSize: 16 * math.sqrt(cardHeight), // 字体大小
                color: Colors.blue.shade900, // 字体颜色
              ),
              textAlign:
                  isAlternate ? TextAlign.right : TextAlign.left, // 文本对齐方式
              maxLines: 2, // 最大行数
              overflow: TextOverflow.ellipsis, // 溢出时显示省略号
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户目标 Widget。
  ///
  /// [context]：Build 上下文。
  /// 显示用户信息徽章。
  Widget _buildUserTarget(BuildContext context) {
    final targetUserId = activity.targetId; // 目标用户 ID
    if (targetUserId.isEmpty) {
      return const SizedBox.shrink(); // 用户 ID 为空时返回空 Widget
    }

    return Container(
      padding: EdgeInsets.all(12 * cardHeight), // 内边距
      decoration: BoxDecoration(
        color: Colors.purple.shade50, // 背景颜色
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)), // 边框圆角
        border: Border.all(color: Colors.purple.shade100), // 边框
      ),
      child: Align(
        alignment:
            isAlternate ? Alignment.centerRight : Alignment.centerLeft, // 对齐方式
        child: UserInfoBadge(
          key: ValueKey('target_badge_$targetUserId'), // Key
          currentUser: currentUser, // 当前登录用户
          targetUserId: targetUserId, // 目标用户 ID
          infoService: infoService, // 用户信息 Provider
          followService: followService, // 用户关注服务
          showFollowButton: true, // 显示关注按钮
          showLevel: true, // 显示用户等级
          mini: cardHeight < 1.0, // 根据卡片高度判断是否为迷你模式
        ),
      ),
    );
  }

  /// 构建默认用户目标 Widget。
  ///
  /// [context]：Build 上下文。
  /// 显示用户信息徽章。
  Widget _buildDefaultUser(BuildContext context) {
    final userId = activity.userId; // 用户 ID
    return Container(
      padding: EdgeInsets.all(12 * cardHeight), // 内边距
      decoration: BoxDecoration(
        color: Colors.green.shade50, // 背景颜色
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)), // 边框圆角
        border: Border.all(color: Colors.green.shade100), // 边框
      ),
      child: Align(
        alignment:
            isAlternate ? Alignment.centerRight : Alignment.centerLeft, // 对齐方式
        child: UserInfoBadge(
          key: ValueKey('default_$userId'), // Key
          currentUser: currentUser, // 当前登录用户
          targetUserId: userId, // 目标用户 ID
          infoService: infoService, // 用户信息 Provider
          followService: followService, // 用户关注服务
          showFollowButton: true, // 显示关注按钮
          showLevel: true, // 显示用户等级
          mini: cardHeight < 1.0, // 根据卡片高度判断是否为迷你模式
        ),
      ),
    );
  }

  /// 构建占位图片 Widget。
  ///
  /// [type]：目标类型。
  /// 返回一个带有图标的占位图片。
  Widget _buildPlaceholderImage(String type) {
    final double size = 60 * cardHeight; // 尺寸
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300, // 背景颜色
        borderRadius: BorderRadius.circular(4 * math.sqrt(cardHeight)), // 圆角
      ),
      child: Icon(
        type == ActivityTargetTypeConstants.game // 根据类型选择图标
            ? Icons.videogame_asset_outlined
            : Icons.image_not_supported_outlined,
        size: 24 * math.sqrt(cardHeight), // 图标尺寸
        color: Colors.grey.shade600, // 图标颜色
      ),
    );
  }
}
