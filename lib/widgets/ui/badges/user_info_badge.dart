// lib/widgets/ui/badges/user_info_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/user/user.dart'; // 确保 User 模型路径正确
import 'package:suxingchahui/providers/user/user_info_provider.dart'; // 引入 UserInfoProvider
import 'package:suxingchahui/providers/user/user_data_status.dart'; // 引入 UserDataStatus
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/follow_user_button.dart';
import 'safe_user_avatar.dart';

class UserInfoBadge extends StatelessWidget {
  final String targetUserId;
  final UserDataStatus userDataStatus;
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
    required this.targetUserId,
    required this.userDataStatus,
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
    // 定义颜色变量
    final Color defaultTextColor = textColor ??
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.black87;
    final Color secondaryTextColor = Colors.grey[600]!;

    final double avatarRadius = mini ? 14 : 18; // UserInfoBadge 内部定义头像半径
    final double avatarDiameter = avatarRadius * 2;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final int calculatedMemCacheWidth = (avatarDiameter * dpr).round();
    final int calculatedMemCacheHeight = (avatarDiameter * dpr).round();

    // 4. 根据数据状态构建 UI
    switch (userDataStatus.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        // 显示加载占位符
        return _buildPlaceholder(context, mini);

      case LoadStatus.error:
        // 显示错误占位符
        // 可以选择性地使用日志记录错误: Logger.error('Failed to load user $userId: ${userDataStatus.error}');
        return _buildErrorPlaceholder(context, mini);

      case LoadStatus.loaded:
        // 数据加载成功，获取 User 对象
        // 在 loaded 状态下，user 不应为 null，如果为 null 是 provider 的逻辑错误
        final User targetUser = userDataStatus.user!;

        // --- 从 User 对象提取信息 ---
        final String username =
            targetUser.username.isNotEmpty ? targetUser.username : '未知用户';
        final String? avatarUrl = targetUser.avatar;
        final int experience = targetUser.experience;
        final int level = targetUser.level;

        // 获取签到信息
        final int consecutiveDays = targetUser.consecutiveCheckIn ?? 0;
        final int totalDays = targetUser.totalCheckIn ?? 0;
        final bool checkedInToday = targetUser.hasCheckedInToday;

        // --- 获取管理员状态 ---
        final bool isAdmin = targetUser.isAdmin;
        final bool isSuperAdmin = targetUser.isSuperAdmin;

        // --- 计算关注状态 ---
        bool iFollowTarget = false;
        String? currentUserId = currentUser?.id; // 安全获取当前用户ID

        if (currentUserId != null && currentUser != null) {
          // 检查当前用户的关注列表是否包含目标用户的 ID
          iFollowTarget = currentUser!.following.contains(targetUser.id);
        }

        final bool isCurrentUser = currentUserId == targetUserId;
        // 只有当 showFollowButton 为 true 且不是当前用户时，才显示关注按钮
        final bool shouldShowFollowButton = showFollowButton && !isCurrentUser;

        // --- 构建最终的 Badge UI ---
        return Container(
          // 内边距根据 mini 状态和外部传入值调整
          padding: padding ?? EdgeInsets.all(mini ? 4 : 8),
          // 背景颜色和圆角
          decoration: backgroundColor != null
              ? BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(mini ? 12 : 16),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min, // Row 只包裹必要宽度
            crossAxisAlignment: CrossAxisAlignment.center, // 子项垂直居中
            children: [
              // --- 头像 ---
              SafeUserAvatar(
                username: username,
                avatarUrl: avatarUrl,
                isAdmin: isAdmin,
                isSuperAdmin: isSuperAdmin,
                userId: targetUserId, // userId 仍然需要，例如用于导航或 key
                radius: mini ? 14 : 18,
                backgroundColor: Colors.grey[100], // 占位背景色
                enableNavigation: true,
                onTap: () => NavigationUtils.pushNamed(
                  context,
                  AppRoutes.openProfile,
                  arguments: targetUserId, // 导航参数是 userId
                ),
                memCacheWidth: calculatedMemCacheWidth,
                memCacheHeight: calculatedMemCacheHeight,
              ),
              const SizedBox(width: 8), // 头像和信息的间距

              // --- 用户信息区域 (用户名、等级、签到) ---
              Flexible(
                // 使用 Flexible 防止文本溢出
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
                  mainAxisSize: MainAxisSize.min, // Column 包裹内容高度
                  children: [
                    Row(
                      // 将用户名和管理员标识放在一行
                      mainAxisSize: MainAxisSize.min, // 包裹内容
                      crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中对齐
                      children: [
                        // 用户名 (用 Flexible 包裹，允许管理员标识有固定空间)
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

                    // 等级和经验 (如果 showLevel 为 true)
                    if (showLevel)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0), // 与用户名的间距
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 等级徽章
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getLevelColor(level), // 使用辅助函数获取颜色
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
                            const SizedBox(width: 4), // 徽章和经验值间距
                            // 经验值 (Flexible 保证不溢出父 Row)
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

                    // 签到统计 (如果 showCheckInStats 为 true)
                    if (showCheckInStats)
                      Padding(
                        padding: const EdgeInsets.only(top: 3.0), // 与上方元素的间距
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 今日已签图标 (如果 checkedInToday 为 true)
                            if (checkedInToday) ...[
                              Icon(
                                Icons.check_circle,
                                size: mini ? 11 : 12,
                                color: Colors.green,
                              ),
                              SizedBox(width: mini ? 2 : 4),
                            ],
                            // 连续签到图标和天数
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: mini ? 11 : 12,
                              color: consecutiveDays > 0
                                  ? Colors.orange
                                  : secondaryTextColor,
                            ),
                            SizedBox(width: 2),
                            Text(
                              '$consecutiveDays',
                              style: TextStyle(
                                fontSize: mini ? 10 : 11,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: mini ? 4 : 6), // 连续和总计的间隔
                            // 总签到图标和天数
                            Icon(
                              Icons.event_available_rounded,
                              size: mini ? 11 : 12,
                              color: secondaryTextColor,
                            ),
                            SizedBox(width: 2),
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

              // --- 关注按钮 (如果 shouldShowFollowButton 为 true) ---
              if (shouldShowFollowButton) ...[
                const SizedBox(width: 8), // 信息区域和按钮的间距
                FollowUserButton(
                  // 使用 ValueKey 包含 userId 和关注状态，确保状态变化时按钮能正确重建
                  key: ValueKey('${targetUserId}_$iFollowTarget'),
                  currentUser: currentUser,
                  targetUserId: targetUserId,
                  mini: mini,
                  showIcon: !mini, // mini 模式下隐藏图标以节省空间
                  initialIsFollowing: iFollowTarget, // 传递计算好的初始关注状态
                  onFollowChanged: () {
                    context
                        .read<UserInfoProvider>()
                        .refreshUserInfo(targetUserId);
                  },
                ),
              ],
            ],
          ),
        );
    }
  }

  // --- 辅助方法 ---

  // 获取等级对应的颜色
  Color _getLevelColor(int level) {
    return LevelUtils.getLevelColor(level); // 假设 LevelColor 工具类存在且可用
  }

  // 构建加载状态的占位符 UI
  Widget _buildPlaceholder(BuildContext context, bool isMini) {
    return Opacity(
      opacity: 0.6, // 半透明效果模拟加载
      child: Container(
        padding: padding ?? EdgeInsets.all(mini ? 4 : 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: mini ? 14 : 18,
              backgroundColor: Colors.grey[200], // 灰色占位
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 用户名占位符
                  Container(
                    height: mini ? 10 : 12,
                    width: mini ? 60 : 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // 等级/签到信息占位符（如果需要显示的话）
                  if (showLevel || showCheckInStats) SizedBox(height: 4),
                  if (showLevel || showCheckInStats)
                    Container(
                      height: mini ? 8 : 10,
                      width: mini ? 80 : 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            // 如果关注按钮可能显示，也可以加一个占位符，但这会增加复杂性，通常省略
          ],
        ),
      ),
    );
  }

  // 构建错误状态的占位符 UI
  Widget _buildErrorPlaceholder(BuildContext context, bool isMini) {
    return Container(
      padding: padding ?? EdgeInsets.all(mini ? 4 : 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: isMini ? 14 : 18,
            backgroundColor: Colors.red[100], // 使用淡红色背景表示错误
            child: Icon(
              Icons.error_outline_rounded,
              size: isMini ? 14 : 18,
              color: Colors.red[700], // 深红色图标
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '加载失败', // 简洁的错误提示
            style:
                TextStyle(fontSize: isMini ? 12 : 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
