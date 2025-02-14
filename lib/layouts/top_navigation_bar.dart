// lib/layouts/top_navigation_bar.dart
import 'package:flutter/material.dart';
import '../screens/search_screen.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/logo/app_logo.dart';
import '../widgets/update/update_button.dart';
import '../widgets/message/message_badge.dart';  // 新增导入

class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogoTap;
  final VoidCallback onProfileTap;
  final UserService _userService = UserService();

  TopNavigationBar({
    Key? key,
    required this.onLogoTap,
    required this.onProfileTap
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.grey[700]), // 设置默认图标颜色
      leading: _buildLeadingLogo(context),
      title: _buildSearchBar(context),
      titleSpacing: 8.0,
      actions: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: UpdateButton(),
        ),
        const SizedBox(width: 8),
        _buildMessageBadge(context), // 使用新的方法构建消息徽章
        const SizedBox(width: 8),
        _buildProfileAvatar(context),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildMessageBadge(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoggedIn) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: MessageBadge(),  // 添加消息图标
      );
    } else {
      return SizedBox.shrink(); // 如果未登录，则不显示消息图标
    }
  }

  Widget _buildLeadingLogo(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onLogoTap,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: AppLogo(size: 48),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Text(
                    '搜索游戏...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _userService.getCurrentUserProfile().map((user) => user?.avatar),
      builder: (context, snapshot) {
        final authProvider = Provider.of<AuthProvider>(context);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onProfileTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF2979FF),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: snapshot.hasData && snapshot.data != null
                      ? NetworkImage(snapshot.data!)
                      : null,
                  child: !snapshot.hasData || snapshot.data == null
                      ? Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: Colors.grey[400],
                  )
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}