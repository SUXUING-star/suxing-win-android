// Updated version of desktop_profile_card.dart

import 'package:flutter/material.dart';
import '../../../../../../models/user/user.dart';
import '../../../../../../utils/font/font_config.dart';
import '../../experience/exp_progress_badge.dart'; // Import the badge widget

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
    // Adjust sizes based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1000;

    // Adjust avatar size based on screen size
    final avatarSize = isSmallScreen ? 100.0 : 120.0;
    final iconSize = isSmallScreen ? 16.0 : 20.0;
    final badgeSize = isSmallScreen ? 32.0 : 38.0; // Badge size for experience progress

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView( // Use SingleChildScrollView to prevent content overflow
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Ensure column only takes up needed space
            children: [
              // Avatar section with experience badge
              Stack(
                children: [
                  // Main avatar container
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
                        // Camera icon for avatar update
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

                  // Experience progress badge - positioned in top-right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: ExpProgressBadge(
                      size: badgeSize,
                      backgroundColor: Theme.of(context).primaryColor,
                      isDesktop: true,
                    ),
                  ),
                ],
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
                padding: EdgeInsets.only(bottom: 8.0), // Add bottom padding to prevent overflow
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