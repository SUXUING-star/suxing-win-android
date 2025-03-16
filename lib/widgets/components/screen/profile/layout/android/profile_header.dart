// lib/widgets/components/screen/profile/profile_header.dart
import 'package:flutter/material.dart';
import '../../../../models/user/user.dart';
import '../../../../utils/font/font_config.dart';
import '../../../common/image/safe_user_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final VoidCallback onEditProfile;
  final VoidCallback onAvatarTap;

  const ProfileHeader({
    Key? key,
    required this.user,
    required this.onEditProfile,
    required this.onAvatarTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                // 使用安全头像组件
                SafeUserAvatar(
                  userId: user.id,
                  avatarUrl: user.avatar,
                  username: user.username,
                  radius: 50,
                  enableNavigation: false, // 禁用导航，因为外层已有onTap
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.black54, size: 18),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            user.username,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
          ),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.grey,
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onEditProfile,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '编辑资料',
              style: TextStyle(
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}