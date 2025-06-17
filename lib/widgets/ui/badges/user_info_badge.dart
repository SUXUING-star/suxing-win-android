// lib/widgets/ui/badges/user_info_badge.dart

/// 定义了 [UserInfoBadge] 组件，一个使用 [FutureBuilder] 直接加载并展示用户简要信息的徽章。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/badges/follow_user_button.dart';
import 'safe_user_avatar.dart';

/// 显示用户简要信息的徽章组件。
///
/// 该组件通过 [FutureBuilder] 直接调用 [UserInfoService] (过渡性名称)
/// 来异步获取用户数据，并根据加载状态显示相应UI。
class UserInfoBadge extends StatelessWidget {
  /// 用于处理关注/取关逻辑的服务。
  final UserFollowService followService;

  /// 用于获取任何用户信息的服务。
  final UserInfoService infoService;

  /// 要显示信息的目标用户的ID。
  final String targetUserId;

  /// 当前登录的用户对象，用于判断关注状态等。
  final User? currentUser;

  /// 是否显示关注/取关按钮。
  final bool showFollowButton;

  /// 是否为迷你模式，布局更紧凑。
  final bool mini;

  /// 是否显示用户等级和经验值。
  final bool showLevel;

  /// 是否显示签到统计信息。
  final bool showCheckInStats;

  /// 自定义内边距。
  final EdgeInsetsGeometry? padding;

  /// 自定义背景色。
  final Color? backgroundColor;

  /// 自定义文本颜色。
  final Color? textColor;

  /// 创建一个 [UserInfoBadge] 实例。
  const UserInfoBadge({
    super.key,
    required this.followService,
    required this.infoService,
    required this.targetUserId,
    required this.currentUser,
    this.showFollowButton = true,
    this.mini = false,
    this.showLevel = true,
    this.showCheckInStats = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: infoService.getUserInfoById(targetUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingPlaceholder(context, mini);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorPlaceholder(context, mini, snapshot.error);
        }

        return _buildLoadedContent(context, snapshot.data!);
      },
    );
  }

  /// 构建加载状态的占位符。
  Widget _buildLoadingPlaceholder(BuildContext context, bool isMini) {
    final double avatarRadius = isMini ? 14 : 18;
    final Color placeholderColor = Colors.grey[300]!;

    return Container(
      padding: padding ?? EdgeInsets.all(isMini ? 4 : 8),
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(isMini ? 12 : 16),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: placeholderColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isMini ? 60 : 80,
                  height: isMini ? 13 : 15,
                  color: placeholderColor,
                ),
                if (showLevel) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isMini ? 25 : 30,
                        height: isMini ? 10 : 11,
                        decoration: BoxDecoration(
                          color: placeholderColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: isMini ? 30 : 40,
                        height: isMini ? 10 : 11,
                        color: placeholderColor,
                      ),
                    ],
                  ),
                ],
                if (showCheckInStats) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: isMini ? 50 : 70,
                    height: isMini ? 10 : 11,
                    color: placeholderColor,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建已加载的用户信息内容。
  Widget _buildLoadedContent(BuildContext context, User targetUser) {
    final Color defaultTextColor = textColor ??
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.black87;
    final Color secondaryTextColor = Colors.grey[600]!;
    final double avatarRadius = mini ? 14 : 18;
    final double avatarDiameter = avatarRadius * 2;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final int calculatedMemCacheWidth = (avatarDiameter * dpr).round();
    final int calculatedMemCacheHeight = (avatarDiameter * dpr).round();

    final String username =
        targetUser.username.isNotEmpty ? targetUser.username : "未知用户";
    final String? avatarUrl = targetUser.avatar;
    final int experience = targetUser.experience;
    final int level = targetUser.level;
    final int consecutiveDays = targetUser.consecutiveCheckIn ?? 0;
    final int totalDays = targetUser.totalCheckIn ?? 0;
    final bool checkedInToday = targetUser.hasCheckedInToday;
    final bool isAdmin = targetUser.isAdmin;
    final bool isSuperAdmin = targetUser.isSuperAdmin;

    bool isFollowedTarget = false;
    String? currentUserId = currentUser?.id;
    if (currentUserId != null && currentUser != null) {
      isFollowedTarget = currentUser!.following.contains(targetUser.id);
    }
    final bool isCurrentUser = currentUserId == targetUserId;
    final bool shouldShowFollowButton = showFollowButton && !isCurrentUser;

    return Container(
      padding: padding ?? EdgeInsets.all(mini ? 4 : 8),
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(mini ? 12 : 16),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SafeUserAvatar(
            username: username,
            avatarUrl: avatarUrl,
            isAdmin: isAdmin,
            isSuperAdmin: isSuperAdmin,
            userId: targetUserId,
            radius: avatarRadius,
            backgroundColor: Colors.grey[100],
            enableNavigation: true,
            onTap: () => NavigationUtils.pushNamed(
              context,
              AppRoutes.openProfile,
              arguments: targetUserId,
            ),
            memCacheWidth: calculatedMemCacheWidth,
            memCacheHeight: calculatedMemCacheHeight,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: mini ? 13 : 15,
                          color: defaultTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                if (showLevel)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getLevelColor(level),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Lv.$level',
                            style: TextStyle(
                              fontSize: mini ? 10 : 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$experience XP',
                            style: TextStyle(
                              fontSize: mini ? 10 : 11,
                              color: secondaryTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (showCheckInStats)
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (checkedInToday) ...[
                          Icon(
                            Icons.check_circle,
                            size: mini ? 11 : 12,
                            color: Colors.green,
                          ),
                          SizedBox(width: mini ? 2 : 4),
                        ],
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: mini ? 11 : 12,
                          color: consecutiveDays > 0
                              ? Colors.orange
                              : secondaryTextColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$consecutiveDays',
                          style: TextStyle(
                            fontSize: mini ? 10 : 11,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: mini ? 4 : 6),
                        Icon(
                          Icons.event_available_rounded,
                          size: mini ? 11 : 12,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$totalDays',
                          style: TextStyle(
                            fontSize: mini ? 10 : 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (shouldShowFollowButton) ...[
            const SizedBox(width: 8),
            FollowUserButton(
              key: ValueKey(
                  '${targetUserId}_${targetUser.id}_$isFollowedTarget'),
              currentUser: currentUser,
              targetUserId: targetUserId,
              followService: followService,
              mini: mini,
              showIcon: !mini,
              initialIsFollowing: isFollowedTarget,
            ),
          ],
        ],
      ),
    );
  }

  /// 获取用户等级对应的颜色。
  Color _getLevelColor(int level) {
    return LevelUtils.getLevelColor(level);
  }

  /// 构建错误状态的占位符。
  Widget _buildErrorPlaceholder(
      BuildContext context, bool isMini, dynamic error) {
    return Container(
      padding: padding ?? EdgeInsets.all(mini ? 4 : 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: isMini ? 14 : 18,
            backgroundColor: Colors.red[100],
            child: Icon(
              Icons.error_outline_rounded,
              size: isMini ? 14 : 18,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '加载失败',
            style:
                TextStyle(fontSize: isMini ? 12 : 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
