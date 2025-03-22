// lib/widgets/layouts/desktop/desktop_sidebar_user_profile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../services/main/user/user_service.dart';
import '../../models/user/user.dart';

class DesktopSidebarUserProfile extends StatelessWidget {
  final VoidCallback onProfileTap;
  final UserService _userService = UserService();

  DesktopSidebarUserProfile({
    Key? key,
    required this.onProfileTap,
  }) : super(key: key);

  // 根据等级返回不同的颜色
  Color _getLevelColor(int level) {
    if (level < 5) return Colors.green;
    if (level < 10) return Colors.blue;
    if (level < 20) return Colors.purple;
    if (level < 50) return Colors.orange;
    return Colors.red;
  }

  // 未登录状态的用户头像和登录入口
  Widget _buildLoginPrompt(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/login'),
          hoverColor: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          child: Tooltip(
            message: '登录',
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 已登录状态的用户信息
  Widget _buildLoggedInProfile(BuildContext context, User user) {
    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onProfileTap,
          hoverColor: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          child: Tooltip(
            message: '我的资料',
            child: Column(
              children: [
                Stack(
                  children: [
                    // 用户头像
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: user.avatar != null
                          ? ClipOval(
                        child: Image.network(
                          user.avatar!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _fallbackAvatar(user.username);
                          },
                        ),
                      )
                          : _fallbackAvatar(user.username),
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
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    user.username ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
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

  // 备用头像方法，当无法加载网络头像时
  Widget _fallbackAvatar(String? username) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white.withOpacity(0.2),
      child: Text(
        username?[0].toUpperCase() ?? '?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // 如果未登录，显示默认头像
          if (!authProvider.isLoggedIn) {
            return _buildLoginPrompt(context);
          }

          // 已登录状态 - 获取用户完整信息，包括等级和经验值
          return StreamBuilder<User?>(
            stream: _userService.getCurrentUserProfile(),
            builder: (context, snapshot) {
              // 如果没有数据，显示登录提示
              if (!snapshot.hasData) {
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