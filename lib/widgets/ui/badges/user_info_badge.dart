// lib/widgets/ui/badges/user_info_badge.dart

/// 该文件定义了 UserInfoBadge 组件，一个显示用户简要信息的徽章。
/// UserInfoBadge 加载并展示用户头像、用户名、等级、签到统计和关注按钮。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/providers/user/user_info_provider.dart'; // 导入用户信息 Provider
import 'package:suxingchahui/providers/user/user_data_status.dart'; // 导入用户数据状态
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/constants/user/level_constants.dart'; // 导入用户等级常量
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/badges/follow_user_button.dart'; // 导入关注用户按钮
import 'safe_user_avatar.dart'; // 导入安全用户头像组件

/// `UserInfoBadge` 类：显示用户简要信息的徽章组件。
///
/// 该组件根据用户数据加载状态显示加载中、错误或已加载的用户信息，
/// 包括头像、用户名、等级、签到统计和关注按钮。
class UserInfoBadge extends StatelessWidget {
  final UserFollowService followService; // 用户关注服务实例
  final UserInfoProvider infoProvider; // 用户信息 Provider 实例
  final String targetUserId; // 目标用户ID
  final User? currentUser; // 当前登录用户
  final bool showFollowButton; // 是否显示关注按钮
  final bool mini; // 是否为迷你模式
  final bool showLevel; // 是否显示用户等级
  final bool showCheckInStats; // 是否显示签到统计
  final EdgeInsetsGeometry? padding; // 徽章内边距
  final Color? backgroundColor; // 徽章背景色
  final Color? textColor; // 徽章文本颜色

  /// 构造函数。
  ///
  /// [followService]：关注服务。
  /// [infoProvider]：用户信息 Provider。
  /// [targetUserId]：目标用户ID。
  /// [currentUser]：当前用户。
  /// [showFollowButton]：是否显示关注按钮。
  /// [mini]：是否迷你模式。
  /// [showLevel]：是否显示等级。
  /// [showCheckInStats]：是否显示签到统计。
  /// [padding]：内边距。
  /// [backgroundColor]：背景色。
  /// [textColor]：文本颜色。
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

  /// 构建用户徽章组件。
  ///
  /// 该方法通过 StreamBuilder 监听用户数据状态变化，并根据状态显示不同内容。
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserDataStatus>(
      stream: infoProvider.getUserStatusStream(targetUserId), // 监听用户状态流
      initialData: infoProvider.getUserStatus(targetUserId), // 初始数据
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // 无数据时显示加载占位符
          return _buildLoadingPlaceholder(context, mini);
        }

        final UserDataStatus userDataStatus = snapshot.data!; // 获取用户数据状态

        if (userDataStatus.status == LoadStatus.initial ||
            userDataStatus.status == LoadStatus.loading) {
          // 初始或加载中状态
          return _buildLoadingPlaceholder(context, mini);
        }

        if (userDataStatus.status == LoadStatus.error) {
          // 错误状态
          return _buildErrorPlaceholder(context, mini, userDataStatus.error);
        }

        if (userDataStatus.user == null) {
          // 用户数据为空
          return _buildErrorPlaceholder(
              context, mini, userDataStatus.error ?? "用户数据为空");
        }

        return _buildLoadedContent(context, userDataStatus.user!); // 显示已加载内容
      },
    );
  }

  /// 构建加载状态的占位符。
  ///
  /// [context]：Build 上下文。
  /// [isMini]：是否迷你模式。
  /// 返回一个模拟用户徽章布局的加载动画。
  Widget _buildLoadingPlaceholder(BuildContext context, bool isMini) {
    final double avatarRadius = isMini ? 14 : 18; // 头像半径
    final Color placeholderColor = Colors.grey[300]!; // 占位符颜色

    return Container(
      padding: padding ?? EdgeInsets.all(isMini ? 4 : 8), // 容器内边距
      decoration: backgroundColor != null // 容器装饰
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(isMini ? 12 : 16),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
        crossAxisAlignment: CrossAxisAlignment.center, // 交叉轴居中
        children: [
          CircleAvatar(
            radius: avatarRadius, // 头像半径
            backgroundColor: placeholderColor, // 头像背景色
          ),
          const SizedBox(width: 8), // 间距
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴起始对齐
              mainAxisSize: MainAxisSize.min, // 列主轴尺寸最小化
              children: [
                Container(
                  width: isMini ? 60 : 80, // 用户名占位符宽度
                  height: isMini ? 13 : 15, // 用户名占位符高度
                  color: placeholderColor, // 用户名占位符颜色
                ),
                if (showLevel) ...[
                  // 显示等级占位符
                  const SizedBox(height: 3), // 间距
                  Row(
                    mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
                    children: [
                      Container(
                        width: isMini ? 25 : 30, // 等级标签占位符宽度
                        height: isMini ? 10 : 11, // 等级标签占位符高度
                        decoration: BoxDecoration(
                          color: placeholderColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 4), // 间距
                      Container(
                        width: isMini ? 30 : 40, // 经验值占位符宽度
                        height: isMini ? 10 : 11, // 经验值占位符高度
                        color: placeholderColor, // 经验值占位符颜色
                      ),
                    ],
                  ),
                ],
                if (showCheckInStats) ...[
                  // 显示签到统计占位符
                  const SizedBox(height: 3), // 间距
                  Container(
                    width: isMini ? 50 : 70, // 签到统计占位符宽度
                    height: isMini ? 10 : 11, // 签到统计占位符高度
                    color: placeholderColor, // 签到统计占位符颜色
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
  ///
  /// [context]：Build 上下文。
  /// [targetUser]：目标用户数据。
  /// 返回一个包含用户头像、用户名、等级、签到统计和关注按钮的徽章。
  Widget _buildLoadedContent(BuildContext context, User targetUser) {
    final Color defaultTextColor = textColor ??
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.black87; // 默认文本颜色
    final Color secondaryTextColor = Colors.grey[600]!; // 次要文本颜色
    final double avatarRadius = mini ? 14 : 18; // 头像半径
    final double avatarDiameter = avatarRadius * 2; // 头像直径
    final dpr = MediaQuery.of(context).devicePixelRatio; // 设备像素比
    final int calculatedMemCacheWidth = (avatarDiameter * dpr).round(); // 缓存宽度
    final int calculatedMemCacheHeight = (avatarDiameter * dpr).round(); // 缓存高度

    final String username =
        targetUser.username.isNotEmpty ? targetUser.username : "未知用户"; // 用户名
    final String? avatarUrl = targetUser.avatar; // 头像 URL
    final int experience = targetUser.experience; // 经验值
    final int level = targetUser.level; // 等级
    final int consecutiveDays = targetUser.consecutiveCheckIn ?? 0; // 连续签到天数
    final int totalDays = targetUser.totalCheckIn ?? 0; // 总签到天数
    final bool checkedInToday = targetUser.hasCheckedInToday; // 今天是否已签到
    final bool isAdmin = targetUser.isAdmin; // 是否管理员
    final bool isSuperAdmin = targetUser.isSuperAdmin; // 是否超级管理员

    bool iFollowTarget = false; // 当前用户是否关注目标用户
    String? currentUserId = currentUser?.id;
    if (currentUserId != null && currentUser != null) {
      iFollowTarget = currentUser!.following.contains(targetUser.id); // 判断关注状态
    }
    final bool isCurrentUser = currentUserId == targetUserId; // 是否为当前用户
    final bool shouldShowFollowButton =
        showFollowButton && !isCurrentUser; // 是否显示关注按钮

    return Container(
      padding: padding ?? EdgeInsets.all(mini ? 4 : 8), // 容器内边距
      decoration: backgroundColor != null // 容器装饰
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(mini ? 12 : 16),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
        crossAxisAlignment: CrossAxisAlignment.center, // 交叉轴居中
        children: [
          SafeUserAvatar(
            username: username, // 用户名
            avatarUrl: avatarUrl, // 头像 URL
            isAdmin: isAdmin, // 是否管理员
            isSuperAdmin: isSuperAdmin, // 是否超级管理员
            userId: targetUserId, // 用户ID
            radius: avatarRadius, // 半径
            backgroundColor: Colors.grey[100], // 背景色
            enableNavigation: true, // 启用导航
            onTap: () => NavigationUtils.pushNamed(
              context,
              AppRoutes.openProfile, // 导航到用户资料路由
              arguments: targetUserId, // 传递用户ID
            ),
            memCacheWidth: calculatedMemCacheWidth, // 缓存宽度
            memCacheHeight: calculatedMemCacheHeight, // 缓存高度
          ),
          const SizedBox(width: 8), // 间距
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴起始对齐
              mainAxisSize: MainAxisSize.min, // 列主轴尺寸最小化
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
                  crossAxisAlignment: CrossAxisAlignment.center, // 交叉轴居中
                  children: [
                    Flexible(
                      child: Text(
                        username, // 用户名文本
                        style: TextStyle(
                          fontSize: mini ? 13 : 15, // 字体大小
                          color: defaultTextColor, // 字体颜色
                          fontWeight: FontWeight.w500, // 字体粗细
                        ),
                        overflow: TextOverflow.ellipsis, // 文本溢出显示省略号
                        maxLines: 1, // 最大行数
                      ),
                    ),
                  ],
                ),
                if (showLevel) // 显示等级
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0), // 顶部填充
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2), // 内边距
                          decoration: BoxDecoration(
                            color: _getLevelColor(level), // 等级颜色
                            borderRadius: BorderRadius.circular(10), // 圆角
                          ),
                          child: Text(
                            'Lv.$level', // 等级文本
                            style: TextStyle(
                              fontSize: mini ? 10 : 11, // 字体大小
                              color: Colors.white, // 字体颜色
                              fontWeight: FontWeight.bold, // 字体粗细
                            ),
                          ),
                        ),
                        const SizedBox(width: 4), // 间距
                        Flexible(
                          child: Text(
                            '$experience XP', // 经验值文本
                            style: TextStyle(
                              fontSize: mini ? 10 : 11, // 字体大小
                              color: secondaryTextColor, // 字体颜色
                            ),
                            overflow: TextOverflow.ellipsis, // 文本溢出显示省略号
                            maxLines: 1, // 最大行数
                          ),
                        ),
                      ],
                    ),
                  ),
                if (showCheckInStats) // 显示签到统计
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0), // 顶部填充
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
                      children: [
                        if (checkedInToday) ...[
                          // 显示今日签到图标
                          Icon(
                            Icons.check_circle,
                            size: mini ? 11 : 12,
                            color: Colors.green,
                          ),
                          SizedBox(width: mini ? 2 : 4), // 间距
                        ],
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: mini ? 11 : 12,
                          color: consecutiveDays > 0
                              ? Colors.orange
                              : secondaryTextColor, // 火焰图标颜色
                        ),
                        const SizedBox(width: 2), // 间距
                        Text(
                          '$consecutiveDays', // 连续签到天数
                          style: TextStyle(
                            fontSize: mini ? 10 : 11, // 字体大小
                            color: secondaryTextColor, // 字体颜色
                            fontWeight: FontWeight.w500, // 字体粗细
                          ),
                        ),
                        SizedBox(width: mini ? 4 : 6), // 间距
                        Icon(
                          Icons.event_available_rounded,
                          size: mini ? 11 : 12,
                          color: secondaryTextColor, // 事件图标颜色
                        ),
                        const SizedBox(width: 2), // 间距
                        Text(
                          '$totalDays', // 总签到天数
                          style: TextStyle(
                            fontSize: mini ? 10 : 11, // 字体大小
                            color: secondaryTextColor, // 字体颜色
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (shouldShowFollowButton) ...[
            // 显示关注按钮
            const SizedBox(width: 8), // 间距
            FollowUserButton(
              key: ValueKey(
                  '${targetUserId}_${targetUser.id}_$iFollowTarget'), // 按钮唯一键
              currentUser: currentUser, // 当前用户
              targetUserId: targetUserId, // 目标用户ID
              followService: followService, // 关注服务
              mini: mini, // 迷你模式
              showIcon: !mini, // 显示图标
              initialIsFollowing: iFollowTarget, // 初始关注状态
              onFollowChanged: () {
                // 关注状态改变回调
                infoProvider.refreshUserInfo(targetUserId); // 刷新用户信息
              },
            ),
          ],
        ],
      ),
    );
  }

  /// 获取用户等级对应的颜色。
  ///
  /// [level]：用户等级。
  /// 返回等级颜色。
  Color _getLevelColor(int level) {
    return LevelUtils.getLevelColor(level); // 获取等级颜色
  }

  /// 构建错误状态的占位符。
  ///
  /// [context]：Build 上下文。
  /// [isMini]：是否迷你模式。
  /// [error]：错误对象。
  /// 返回一个显示错误图标和消息的占位符。
  Widget _buildErrorPlaceholder(
      BuildContext context, bool isMini, dynamic error) {
    return Container(
      padding: padding ?? EdgeInsets.all(mini ? 4 : 8), // 容器内边距
      child: Row(
        mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
        crossAxisAlignment: CrossAxisAlignment.center, // 交叉轴居中
        children: [
          CircleAvatar(
            radius: isMini ? 14 : 18, // 头像半径
            backgroundColor: Colors.red[100], // 头像背景色
            child: Icon(
              Icons.error_outline_rounded,
              size: isMini ? 14 : 18,
              color: Colors.red[700], // 错误图标颜色
            ),
          ),
          const SizedBox(width: 8), // 间距
          Text(
            '加载失败', // 错误消息文本
            style: TextStyle(
                fontSize: isMini ? 12 : 14, color: Colors.grey[600]), // 字体样式
          ),
        ],
      ),
    );
  }
}
