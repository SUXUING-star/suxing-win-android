// lib/widgets/layouts/desktop/desktop_sidebar_user_profile.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/badges/safe_user_avatar.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/models/user/user.dart';

class DesktopSidebarUserProfile extends StatelessWidget {
  final VoidCallback onProfileTap;
  final AuthProvider authProvider;

  const DesktopSidebarUserProfile({
    super.key,
    required this.onProfileTap,
    required this.authProvider,
  });

  // 根据等级返回不同的颜色
  Color _getLevelColor(int level) {
    return LevelUtils.getLevelColor(level);
  }

  // 未登录状态的用户头像和登录入口
  Widget _buildLoginPrompt(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => NavigationUtils.navigateToLogin(context),
          hoverColor: Colors.white.withSafeOpacity(0.1),
          borderRadius: BorderRadius.circular(20), // Keep consistent radius
          child: Tooltip(
            message: '登录',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              children: [
                Container(
                  width: 40, // Set fixed size for alignment
                  height: 40, // Set fixed size for alignment
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20, // Inner radius matches image size
                    backgroundColor: Colors.white.withSafeOpacity(0.2),
                    child: Icon(
                      Icons.person_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '点击登录',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                // Add empty text widgets to roughly match logged-in height if needed
                // SizedBox(height: 12), // Adjust spacing if alignment differs significantly
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 已登录状态的用户信息
  // 已登录状态的用户信息 (直接从 AuthProvider 获取 User 对象)
  Widget _buildLoggedInProfile(BuildContext context, User user) {
    final avatarRadiusInProfile = 50;

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int calculatedMemCacheSize =
        (avatarRadiusInProfile * 2 * devicePixelRatio).round();

    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onProfileTap,
          hoverColor: Colors.white.withSafeOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          child: Tooltip(
            message: '我的资料',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: user.avatar != null
                          ? SafeUserAvatar(
                              userId: user.id,
                              avatarUrl: user.avatar,
                              username: user.username,
                              radius: 50,
                              enableNavigation: false,
                              memCacheWidth: calculatedMemCacheSize,
                              memCacheHeight: calculatedMemCacheSize,
                            )
                          : _fallbackAvatar(user.username),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _getLevelColor(user.level),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          'Lv.${user.level}',
                          style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    user.username,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(
                  '${user.experience} XP',
                  style: TextStyle(
                      fontSize: 10, color: Colors.white.withSafeOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 备用头像方法，当无法加载网络头像或用户没有设置头像时
  Widget _fallbackAvatar(String? username) {
    // Ensure this fallback also fits within the 40x40 circular space
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white
            .withSafeOpacity(0.2), // Background color for the circle
      ),
      child: Center(
        // Center the text within the container
        child: Text(
          // Ensure username is not null and not empty before accessing index 0
          (username != null && username.isNotEmpty)
              ? username[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: StreamBuilder<User?>(
        stream: authProvider.currentUserStream,
        initialData: authProvider.currentUser,
        builder: (context, currentUserSnapshot) {
          final User? currentUser = currentUserSnapshot.data;

          if (currentUser == null) {
            return _buildLoginPrompt(
                context); // 或者，如果初始化阶段不希望显示 loading，则暂时还是登录提示
          }

          return _buildLoggedInProfile(context, currentUser);
        },
      ),
    );
  }
}
