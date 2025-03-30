// lib/widgets/components/screen/profile/layout/mobile/mobile_profile_header.dart

import 'package:flutter/material.dart';
// Import the new button types
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/warning_button.dart';
import '../../../../../../models/user/user.dart';
import '../../../../../../utils/font/font_config.dart';
import '../../../../../ui/image/safe_user_avatar.dart';
import '../../experience/exp_progress_badge.dart';
import '../../level/level_progress_bar.dart'; // 引入等级进度条

class MobileProfileHeader extends StatelessWidget {
  final User user;
  final VoidCallback onEditProfile;
  final VoidCallback onAvatarTap;
  final VoidCallback onLogout; // Make sure this is passed

  const MobileProfileHeader({
    Key? key,
    required this.user,
    required this.onEditProfile,
    required this.onAvatarTap,
    required this.onLogout, // Add required for logout callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define button style parameters for mobile consistency
    final double buttonIconSize = 18;
    final double buttonFontSize = 14;
    final EdgeInsets buttonPadding =
    EdgeInsets.symmetric(horizontal: 20, vertical: 10); // Adjust padding as needed

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // --- Avatar and badge section (unchanged) ---
          Stack(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Stack(
                  children: [
                    SafeUserAvatar(
                      userId: user.id,
                      avatarUrl: user.avatar,
                      username: user.username,
                      radius: 50,
                      enableNavigation: false,
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
                        child: Icon(Icons.camera_alt,
                            color: Colors.black54, size: 18),
                      ),
                    )
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: ExpProgressBadge(
                  size: 28,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // --- User Info (unchanged) ---
          Text(
            user.username,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.grey,
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16), // Increased spacing before buttons

          // --- Buttons Section (Updated) ---
          // Use FunctionalButton for Edit Profile
          FunctionalButton(
            onPressed: onEditProfile,
            icon: Icons.edit,
            label: '编辑资料',
            iconSize: buttonIconSize,
            fontSize: buttonFontSize,
            padding: buttonPadding,
          ),
          SizedBox(height: 12), // Spacing between buttons

          // Use WarningButton for Logout
          WarningButton(
            onPressed: onLogout, // Use the passed callback
            icon: Icons.exit_to_app,
            label: '退出登录',
            iconSize: buttonIconSize,
            fontSize: buttonFontSize,
            padding: buttonPadding,
          ),

          SizedBox(height: 16), // Spacing after buttons, before progress bar

          // --- Level Progress Bar (unchanged) ---
          LevelProgressBar(
            user: user,
            width: MediaQuery.of(context).size.width - 200, // 屏幕宽度减去边距
          ),
        ],
      ),
    );
  }
}