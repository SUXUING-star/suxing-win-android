// lib/widgets/ui/badges/user_info_badge.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/level/level_color.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
// 确保路径是相对 lib 目录或者使用了正确的包导入
import '../../../../services/main/user/user_service.dart';
import '../../../../screens/profile/open_profile_screen.dart';
// 确保这些路径也正确
import 'safe_user_avatar.dart';
import '../buttons/follow_user_button.dart';


class UserInfoBadge extends StatelessWidget {
  final String userId;
  final bool showFollowButton;
  final bool mini;
  final bool showLevel;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? textColor;

  final UserService _userService = UserService();

  UserInfoBadge({
    super.key,
    required this.userId,
    this.showFollowButton = true,
    this.mini = false,
    this.showLevel = true,
    this.padding,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      // 优化：可以考虑将 Future 提取到 StatefulWidget 的 initState 或使用 Provider/Riverpod 管理状态，避免重复请求
      // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
      // 别你妈多管闲事，我她妈这个↓接口里面是加有本地缓存的，本身就是全局的
      // 每个用户都是不同的没必要放状态里，当前用户才需要authprovider
      future: _userService.getUserInfoById(userId),
      builder: (context, snapshot) {
        // 处理加载和错误状态会更健壮
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          // 可以显示一个占位符或加载指示器
          // return const SizedBox(height: 40); // 示例：返回一个固定高度的空盒子
        }
        if (snapshot.hasError) {
          return Text('错误', style: TextStyle(color: Colors.red, fontSize: mini ? 13: 15));
        }

        // 安全地获取数据，提供默认值
        final userInfo = snapshot.data ?? {};
        final username = userInfo['username'] ?? '未知用户';
        final avatarUrl = userInfo['avatar'];
        final experience = userInfo['experience'] ?? 0;
        final level = userInfo['level'] ?? 1;
        final bool? initialIsFollowing = userInfo['isFollowing'] as bool?; // 可能为 null

        return FutureBuilder<String?>(
            future: _userService.currentUserId, // 这个 Future 也可能重复执行
            builder: (context, currentUserSnapshot) {
              final bool isCurrentUser = currentUserSnapshot.data == userId;
              final bool shouldShowFollowButton = showFollowButton && !isCurrentUser;

              return Container(
                padding: padding,
                decoration: backgroundColor != null
                    ? BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(mini ? 12 : 16),
                )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min, // 让 Row 包裹内容
                  children: [
                    // 头像部分保持不变
                    SafeUserAvatar(
                      userId: userId,
                      avatarUrl: avatarUrl,
                      username: username,
                      radius: mini ? 14 : 18,
                      backgroundColor: Colors.grey[100],
                      enableNavigation: true,
                      onTap: () => NavigationUtils.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OpenProfileScreen(userId: userId),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // --- 修改这里：用 Flexible 包裹包含用户名的 Column ---
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Column 也包裹内容
                        children: [
                          // --- 给用户名的 Text 添加 overflow 和 maxLines ---
                          Text(
                            username,
                            style: TextStyle(
                              fontSize: mini ? 13 : 15,
                              color: textColor ?? Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis, // 超出部分显示省略号
                            maxLines: 1,                    // 最多显示一行
                          ),
                          // 等级信息部分保持不变
                          if (showLevel)
                            Padding( // 加一点上边距，避免和用户名贴太近
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                  // 经验值文本也可能过长，虽然概率小，加上 Flexible 保险
                                  Flexible(
                                    child: Text(
                                      '$experience XP',
                                      style: TextStyle(
                                        fontSize: mini ? 10 : 11,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 关注按钮部分保持不变
                    if (shouldShowFollowButton) ...[
                      const SizedBox(width: 8),
                      FollowUserButton(
                        userId: userId,
                        mini: mini,
                        showIcon: !mini,
                        // 传递初始关注状态
                        initialIsFollowing: initialIsFollowing,
                      ),
                    ],
                  ],
                ),
              );
            }
        );
      },
    );
  }

  Color _getLevelColor(int level) {
    return LevelColor.getLevelColor(level);
  }
}