// lib/widgets/ui/badges/user_info_badge.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/user/user_data_status.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/follow_user_button.dart';
import 'safe_user_avatar.dart';

class UserInfoBadge extends StatelessWidget {
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  final String targetUserId;
  final User? currentUser;
  final bool showFollowButton;
  final bool mini;
  final bool showLevel;
  final bool showCheckInStats;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? textColor;

  const UserInfoBadge({
    super.key,
    required this.followService,
    required this.infoProvider,
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
    return StreamBuilder<UserDataStatus>(
      stream: infoProvider.getUserStatusStream(targetUserId),
      initialData: infoProvider.getUserStatus(targetUserId),
      builder: (context, snapshot) {
        final UserDataStatus userDataStatus = snapshot.data!;

        if (userDataStatus.status == LoadStatus.error) {
          return _buildErrorPlaceholder(context, mini, userDataStatus.error);
        }

        // 对于 initial, loading, loaded 状态:
        // 直接使用 userDataStatus.user (可能为 null 或包含旧/新数据)
        // _buildLoadedContent 内部会处理 user 为 null 的情况，显示加载文本或默认值
        // SafeUserAvatar 会自己处理图片加载
        return _buildLoadedContent(context, userDataStatus.user);
      },
    );
  }

  Widget _buildLoadedContent(BuildContext context, User? targetUser) {
    // 判断是否正在初次加载用户数据（targetUser 为 null 且 provider 状态为 initial/loading）
    final bool isUserDataLoading = targetUser == null &&
        (infoProvider.getUserStatus(targetUserId).status ==
                LoadStatus.initial ||
            infoProvider.getUserStatus(targetUserId).status ==
                LoadStatus.loading);

    final Color defaultTextColor = textColor ??
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.black87;
    final Color secondaryTextColor = Colors.grey[600]!;
    final double avatarRadius = mini ? 14 : 18;
    final double avatarDiameter = avatarRadius * 2;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final int calculatedMemCacheWidth = (avatarDiameter * dpr).round();
    final int calculatedMemCacheHeight = (avatarDiameter * dpr).round();

    final String username = isUserDataLoading
        ? "加载中..."
        : (targetUser?.username.isNotEmpty ?? false
            ? targetUser!.username
            : "未知用户");
    final String? avatarUrl = targetUser?.avatar;
    final int experience = targetUser?.experience ?? 0;
    final int level = targetUser?.level ?? 0;
    final int consecutiveDays = targetUser?.consecutiveCheckIn ?? 0;
    final int totalDays = targetUser?.totalCheckIn ?? 0;
    final bool checkedInToday = targetUser?.hasCheckedInToday ?? false;
    final bool isAdmin = targetUser?.isAdmin ?? false;
    final bool isSuperAdmin = targetUser?.isSuperAdmin ?? false;

    bool iFollowTarget = false;
    String? currentUserId = currentUser?.id;
    if (currentUserId != null && currentUser != null && targetUser != null) {
      iFollowTarget = currentUser!.following.contains(targetUser.id);
    }
    final bool isCurrentUser = currentUserId == targetUserId;
    // 只有当目标用户信息已加载时才考虑显示关注按钮
    final bool shouldShowFollowButton =
        showFollowButton && !isCurrentUser && targetUser != null;

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
            username: username, // SafeUserAvatar 可能会用 username 做 fallback
            avatarUrl: avatarUrl, // SafeUserAvatar 自己处理 null 和加载
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
                if (showLevel && !isUserDataLoading) // 数据加载中时不显示等级信息
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
                if (showCheckInStats && !isUserDataLoading) // 数据加载中时不显示签到信息
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
            // 确保 targetUser 不是 null
            const SizedBox(width: 8),
            FollowUserButton(
              key: ValueKey(
                  '${targetUserId}_${targetUser.id}_$iFollowTarget'), // 确保 key 唯一
              currentUser: currentUser,
              targetUserId: targetUserId, // 总是 targetUserId
              followService: followService,
              mini: mini,
              showIcon: !mini,
              initialIsFollowing: iFollowTarget,
              onFollowChanged: () {
                infoProvider.refreshUserInfo(targetUserId); // 关注后刷新用户信息
              },
            ),
          ],
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    return LevelUtils.getLevelColor(level);
  }

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
