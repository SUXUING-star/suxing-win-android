// lib/widgets/components/screen/profile/desktop_profile_card.dart
import 'package:flutter/material.dart';
import '../../../../models/user/user.dart';
import '../../../../utils/font/font_config.dart';

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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar section
            GestureDetector(
              onTap: onAvatarTap,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
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
                      radius: 60,
                      backgroundImage: user.avatar != null
                          ? NetworkImage(user.avatar!)
                          : null,
                      child: user.avatar == null
                          ? Icon(Icons.person, size: 60, color: Colors.grey.shade700)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // User info
            Text(
              user.username,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
            SizedBox(height: 8),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
            SizedBox(height: 24),

            // Edit profile button
            ElevatedButton.icon(
              onPressed: onEditProfile,
              icon: Icon(Icons.edit),
              label: Text(
                '编辑资料',
                style: TextStyle(
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 32),

            // User stats

            SizedBox(height: 32),

            // Logout button at bottom
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: Icon(Icons.exit_to_app, color: Colors.red),
              label: Text(
                '退出登录',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
      ],
    );
  }
}