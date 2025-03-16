// lib/widgets/components/screen/profile/desktop_profile_card.dart
import 'package:flutter/material.dart';
import '../../../../../../models/user/user.dart';
import '../../../../../../utils/font/font_config.dart';

class DesktopProfileCard extends StatelessWidget {
  final User user;
  final VoidCallback onEditProfile;
  final VoidCallback onAvatarTap;
  final VoidCallback onLogout;

  const DesktopProfileCard({
    Key? key,
    required this.user,
    required this.onEditProfile,
    required this.onAvatarTap,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据屏幕宽度调整尺寸
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1000;

    // 根据屏幕大小调整头像尺寸
    final avatarSize = isSmallScreen ? 100.0 : 120.0;
    final iconSize = isSmallScreen ? 16.0 : 20.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView( // 使用 SingleChildScrollView 防止内容溢出
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // 确保列只占用所需的空间
            children: [
              // Avatar section
              GestureDetector(
                onTap: onAvatarTap,
                child: Stack(
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundImage: user.avatar != null
                            ? NetworkImage(user.avatar!)
                            : null,
                        child: user.avatar == null
                            ? Icon(Icons.person, size: avatarSize / 2, color: Colors.grey.shade700)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: iconSize),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),

              // User info
              Text(
                user.username,
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                user.email,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),

              // Edit profile button
              ElevatedButton.icon(
                onPressed: onEditProfile,
                icon: Icon(Icons.edit, size: isSmallScreen ? 18 : 24),
                label: Text(
                  '编辑资料',
                  style: TextStyle(
                    fontFamily: FontConfig.defaultFontFamily,
                    fontFamilyFallback: FontConfig.fontFallback,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 24,
                      vertical: isSmallScreen ? 8 : 12
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Logout button at bottom
              Padding(
                padding: EdgeInsets.only(bottom: 8.0), // 增加底部内边距防止溢出
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: Icon(Icons.exit_to_app, color: Colors.red, size: isSmallScreen ? 18 : 24),
                  label: Text(
                    '退出登录',
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: FontConfig.defaultFontFamily,
                      fontFamilyFallback: FontConfig.fontFallback,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24,
                        vertical: isSmallScreen ? 8 : 12
                    ),
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}