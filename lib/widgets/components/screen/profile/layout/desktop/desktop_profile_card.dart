import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/warning_button.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import '../../../../../../models/user/user.dart';
import '../../../../../../utils/font/font_config.dart';
import '../../experience/exp_progress_badge.dart';
import '../../level/level_progress_bar.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1000;

    final avatarSize = isSmallScreen ? 100.0 : 120.0;
    final iconSize = isSmallScreen ? 16.0 : 20.0;
    final badgeSize = isSmallScreen ? 32.0 : 38.0;

    final double buttonIconSize = isSmallScreen ? 18 : 20;
    final double buttonFontSize = isSmallScreen ? 14 : 16;
    final EdgeInsets buttonPadding = EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 8 : 12
    );

    // Check if avatar URL is valid and not empty
    final bool hasValidAvatar = user.avatar != null && user.avatar!.trim().isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar section with experience badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Main avatar container with shadow and background
                  GestureDetector(
                    onTap: onAvatarTap, // Keep GestureDetector here for the whole area
                    child: Stack( // Inner Stack for Avatar + Camera Icon
                      children: [
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Keep a background color for placeholder/error state visual consistency
                            color: Colors.grey.shade200,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          // *** Use ClipOval + SafeCachedImage or Icon ***
                          child: ClipOval(
                            child: hasValidAvatar
                                ? SafeCachedImage(
                              // Use a key based on URL to force reload if URL changes
                              key: ValueKey(user.avatar!),
                              imageUrl: user.avatar!,
                              width: avatarSize,
                              height: avatarSize,
                              fit: BoxFit.cover,
                              // Let SafeCachedImage handle placeholder/error
                            )
                                : Center( // Fallback Icon if no valid avatar
                              child: Icon(
                                Icons.person_outline, // Using outline for slightly different look
                                size: avatarSize * 0.6, // Adjust icon size
                                color: Colors.grey.shade500,
                              ),
                            ),
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

                  // Experience progress badge
                  Positioned(
                    top: -badgeSize * 0.2,
                    right: -badgeSize * 0.2,
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
              SizedBox(height: 16),

              // Level progress bar
              LevelProgressBar(
                user: user,
                width: isSmallScreen ? 240 : 280,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Use the new FunctionalButton
              FunctionalButton(
                onPressed: onEditProfile,
                icon: Icons.edit,
                label: '编辑资料',
                iconSize: buttonIconSize,
                fontSize: buttonFontSize,
                padding: buttonPadding,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Use the new WarningButton
              WarningButton(
                onPressed: onLogout,
                icon: Icons.exit_to_app,
                label: '退出登录',
                iconSize: buttonIconSize,
                fontSize: buttonFontSize,
                padding: buttonPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}