// lib/widgets/components/screen/activity/card/activity_target.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/activity/activity_constants.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'dart:math' as math;
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';

class ActivityTarget extends StatelessWidget {
  final UserActivity activity;
  final User? currentUser;
  final UserInfoProvider infoProvider;
  final UserFollowService followService;
  final bool isAlternate;
  final double cardHeight;

  const ActivityTarget({
    super.key,
    required this.activity,
    required this.currentUser,
    required this.followService,
    required this.infoProvider,
    this.isAlternate = false,
    this.cardHeight = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget targetWidget;

    // --- 直接用 activity.targetType ---
    switch (activity.targetType) {
      case ActivityTargetTypeConstants.game:
        targetWidget = _buildGameTarget(context);
        break;
      case ActivityTargetTypeConstants.post:
        targetWidget = _buildPostTarget(context);
        break;
      case ActivityTargetTypeConstants.user:
        targetWidget = _buildUserTarget(context); // 目标是用户
        break;
      default:
        targetWidget = _buildDefaultUser(context);
    }

    return targetWidget;
  }

  Widget _buildGameTarget(BuildContext context) {
    // --- 使用 helper getter ---
    final title = activity.gameTitle ?? '未知游戏';
    final coverImage = activity.gameCoverImage; // 使用 helper getter
    final double imageSize = 60 * cardHeight;
    final double borderRadiusValue = 4 * math.sqrt(cardHeight);

    return Container(
      padding: EdgeInsets.all(12 * cardHeight),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          coverImage != null && coverImage.isNotEmpty // 增加非空判断
              ? SafeCachedImage(
                  imageUrl: coverImage,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(borderRadiusValue),
                )
              : _buildPlaceholderImage(ActivityTargetTypeConstants
                  .game), // Fallback if no cover image URL
          SizedBox(width: 12 * cardHeight),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16 * math.sqrt(cardHeight),
              ),
              textAlign: isAlternate ? TextAlign.right : TextAlign.left,
              maxLines: 2, // 允许标题显示两行
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTarget(BuildContext context) {
    // --- 使用 helper getter ---
    final title = activity.postTitle ?? '未知帖子';

    return Container(
      padding: EdgeInsets.all(12 * cardHeight),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Icon(Icons.article,
              color: Colors.blue.shade700, size: 24 * math.sqrt(cardHeight)),
          SizedBox(width: 12 * cardHeight),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16 * math.sqrt(cardHeight),
                color: Colors.blue.shade900,
              ),
              textAlign: isAlternate ? TextAlign.right : TextAlign.left,
              maxLines: 2, // 允许标题显示两行
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTarget(BuildContext context) {
    final targetUserId = activity.targetId;
    if (targetUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    // 如果 metadata 里没有 targetUsername，UserInfoBadge 会自己去获取
    // 所以这里直接传递 targetUserId 即可
    // 返回外部容器 (紫色背景)
    return Container(
      padding: EdgeInsets.all(12 * cardHeight),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)),
        border: Border.all(color: Colors.purple.shade100),
      ),
      // 使用 Align 控制内部 UserInfoBadge 的对齐
      child: Align(
        alignment: isAlternate ? Alignment.centerRight : Alignment.centerLeft,
        // --- 直接使用未修改的 UserInfoBadge ---
        child: UserInfoBadge(
          key: ValueKey('target_badge_$targetUserId'), // 给 Badge 一个 Key
          currentUser: currentUser,
          targetUserId: targetUserId, // 传递目标用户 ID
          infoProvider: infoProvider,
          followService: followService,
          showFollowButton: true, // 在 Target 显示时通常需要关注按钮
          showLevel: true,
          mini: cardHeight < 1.0, // 根据外部尺寸判断是否 mini
        ),
      ),
    );
  }

  Widget _buildDefaultUser(BuildContext context) {
    final userId = activity.userId;
    return Container(
      padding: EdgeInsets.all(12 * cardHeight),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Align(
        alignment: isAlternate ? Alignment.centerRight : Alignment.centerLeft,
        child: UserInfoBadge(
          key: ValueKey('default_$userId'), // 给 Badge 一个 Key
          currentUser: currentUser,
          targetUserId: userId, // 传递目标用户 ID
          infoProvider: infoProvider,
          followService: followService,
          showFollowButton: true, // 在 Target 显示时通常需要关注按钮
          showLevel: true,
          mini: cardHeight < 1.0, // 根据外部尺寸判断是否 mini
        ),
      ),
    );
  }

  // Placeholder image (保持不变)
  Widget _buildPlaceholderImage(String type) {
    final double size = 60 * cardHeight;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4 * math.sqrt(cardHeight)),
      ),
      child: Icon(
        type == ActivityTargetTypeConstants.game
            ? Icons.videogame_asset_outlined
            : Icons.image_not_supported_outlined,
        size: 24 * math.sqrt(cardHeight),
        color: Colors.grey.shade600,
      ),
    );
  }
}
