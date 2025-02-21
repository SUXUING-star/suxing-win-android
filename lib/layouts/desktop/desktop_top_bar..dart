// desktop_top_bar.dart
import 'package:flutter/material.dart';
import '../../screens/search_screen.dart';
import '../../services/main/user/user_service.dart';
import '../../widgets/update/update_button.dart';
import '../../widgets/components/screen/message/message_badge.dart';

class DesktopTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogoTap;
  final VoidCallback onProfileTap;
  final UserService _userService = UserService();

  DesktopTopBar({
    Key? key,
    required this.onLogoTap,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 搜索栏
          Expanded(
            child: Container(
              height: 40,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchScreen()),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, color: Colors.grey[400], size: 20),
                      ),
                      Text(
                        '搜索游戏...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 右侧工具栏
          Row(
            children: [
              UpdateButton(),
              SizedBox(width: 16),
              MessageBadge(),
              SizedBox(width: 16),
              _buildProfileAvatar(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _userService.getCurrentUserProfile().map((user) => user?.avatar),
      builder: (context, snapshot) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onProfileTap,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFF2979FF), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[100],
                backgroundImage: snapshot.hasData && snapshot.data != null
                    ? NetworkImage(snapshot.data!)
                    : null,
                child: !snapshot.hasData || snapshot.data == null
                    ? Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: Colors.grey[400],
                )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}