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
        if (!snapshot.hasData) {
          return _buildLoadingPlaceholder(context, mini);
        }

        final UserDataStatus userDataStatus = snapshot.data!;

        if (userDataStatus.status == LoadStatus.initial ||
            userDataStatus.status == LoadStatus.loading) {
          return _buildLoadingPlaceholder(context, mini);
        }

        if (userDataStatus.status == LoadStatus.error) {
          return _buildErrorPlaceholder(context, mini, userDataStatus.error);
        }

        if (userDataStatus.user == null) {
          return _buildErrorPlaceholder(
              context, mini, userDataStatus.error ?? "用户数据为空");
        }

        return _buildLoadedContent(context, userDataStatus.user!);
      },
    );
  }

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

    bool iFollowTarget = false;
    String? currentUserId = currentUser?.id;
    if (currentUserId != null && currentUser != null) {
      iFollowTarget = currentUser!.following.contains(targetUser.id);
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
              key: ValueKey('${targetUserId}_${targetUser.id}_$iFollowTarget'),
              currentUser: currentUser,
              targetUserId: targetUserId,
              followService: followService,
              mini: mini,
              showIcon: !mini,
              initialIsFollowing: iFollowTarget,
              onFollowChanged: () {
                infoProvider.refreshUserInfo(targetUserId);
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
