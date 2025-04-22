// lib/widgets/layouts/desktop/desktop_sidebar_user_profile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/level/level_color.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../providers/auth/auth_provider.dart';
import '../../services/main/user/user_service.dart';
import '../../models/user/user.dart';
import '../../widgets/ui/image/safe_cached_image.dart'; // Import the new widget

class DesktopSidebarUserProfile extends StatelessWidget {
  final VoidCallback onProfileTap;
  final UserService _userService = UserService();

  DesktopSidebarUserProfile({
    super.key,
    required this.onProfileTap,
  });

  // 根据等级返回不同的颜色
  Color _getLevelColor(int level) {
    return LevelColor.getLevelColor(level);
  }

  // 未登录状态的用户头像和登录入口
  Widget _buildLoginPrompt(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => NavigationUtils.navigateToLogin(context),
          hoverColor: Colors.white.withOpacity(0.1),
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
                    backgroundColor: Colors.white.withOpacity(0.2),
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
  Widget _buildLoggedInProfile(BuildContext context, User user) {
    // Calculate pixel-aware cache dimensions (optional but good practice)
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int cacheSize = (40 * devicePixelRatio).round();

    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onProfileTap,
          hoverColor: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20), // Consistent radius
          child: Tooltip(
            message: '我的资料',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              children: [
                Stack(
                  alignment: Alignment.center, // Center stack items
                  children: [
                    // 用户头像 - 使用 SafeCachedImage
                    Container(
                      // This container now primarily provides the white border
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: user.avatar != null
                          ? SafeCachedImage(
                        imageUrl: user.avatar!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(20), // Make it circular
                        memCacheWidth: cacheSize, // Optimize cache size
                        memCacheHeight: cacheSize, // Optimize cache size
                        // Use SafeCachedImage's built-in placeholder/error handling
                        // You can still add an onError callback if needed for logging etc.
                        // onError: (url, error) => print("Failed to load avatar: $url, $error"),
                      )
                          : _fallbackAvatar(user.username), // Fallback if no avatar URL
                    ),

                    // 等级徽章 - 右下角
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _getLevelColor(user.level),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Lv.${user.level}',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4),

                // 用户名
                Padding(
                  // Reduced top padding slightly as Stack might add visual space
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    user.username ?? '', // Handle null username gracefully
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1, // Ensure single line
                  ),
                ),

                // 经验值
                Text(
                  '${user.experience} XP',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
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
        color: Colors.white.withOpacity(0.2), // Background color for the circle
      ),
      child: Center( // Center the text within the container
        child: Text(
          // Ensure username is not null and not empty before accessing index 0
          (username != null && username.isNotEmpty) ? username[0].toUpperCase() : '?',
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
      // Adjusted padding for potentially better centering/spacing
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // 如果未登录，显示登录提示
          if (!authProvider.isLoggedIn) {
            return _buildLoginPrompt(context);
          }

          // 已登录状态 - 获取用户完整信息
          // Use FutureBuilder if the profile isn't updated frequently via stream,
          // or keep StreamBuilder if real-time updates (like XP gain) are desired.
          return StreamBuilder<User?>(
            stream: _userService.getCurrentUserProfile(),
            builder: (context, snapshot) {
              // Handle loading state more explicitly (optional)
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                // You could show a simple loading indicator or reuse login prompt temporarily
                return _buildLoginPrompt(context); // Or a dedicated loading widget
              }
              // Handle error state (optional)
              if (snapshot.hasError) {
                print("Error fetching user profile: ${snapshot.error}");
                // Show login prompt or an error indicator
                return _buildLoginPrompt(context);
              }
              // If no data after loading/error check, treat as logged out/error
              if (!snapshot.hasData || snapshot.data == null) {
                // This might happen briefly or if the stream yields null
                return _buildLoginPrompt(context);
              }

              // 显示用户信息
              return _buildLoggedInProfile(context, snapshot.data!);
            },
          );
        },
      ),
    );
  }
}