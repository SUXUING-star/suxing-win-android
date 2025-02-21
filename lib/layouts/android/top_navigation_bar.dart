import 'package:flutter/material.dart';
import '../../utils/device/device_utils.dart';
import '../../screens/search_screen.dart';
import '../../services/main/user/user_service.dart';
import '../../providers/auth/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/logo/app_logo.dart';
import '../../widgets/update/update_button.dart';
import '../../widgets/components/screen/message/message_badge.dart';

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
  Size get preferredSize {
    return DeviceUtils.isAndroid &&
        WidgetsBinding.instance.window.physicalSize.width >
            WidgetsBinding.instance.window.physicalSize.height
        ? Size.fromHeight(kToolbarHeight * 0.8)
        : Size.fromHeight(kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAndroidLandscape = DeviceUtils.isAndroid && DeviceUtils.isLandscape(context);

    final double verticalPadding = isAndroidLandscape ? 4.0 : 8.0;
    final double iconSize = isAndroidLandscape ? 18.0 : 20.0;
    final double logoSize = isAndroidLandscape ? 36.0 : 48.0;
    final double searchBarHeight = isAndroidLandscape ? 32.0 : 40.0;
    final double avatarRadius = isAndroidLandscape ? 12.0 : 14.0;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.grey[700]),
      leading: _buildLeadingLogo(context, logoSize, verticalPadding),
      title: _buildSearchBar(context, searchBarHeight, iconSize),
      titleSpacing: 8.0,
      actions: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: UpdateButton(),
          ),
        ),
        const SizedBox(width: 8),
        _buildMessageBadge(context, verticalPadding),
        const SizedBox(width: 8),
        _buildProfileAvatar(context, avatarRadius, verticalPadding),
        const SizedBox(width: 16),
      ],
    );
  }

  // ... 其他辅助方法保持不变，但需要接收并使用新的尺寸参数 ...

  Widget _buildLeadingLogo(BuildContext context, double size, double padding) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onLogoTap,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: AppLogo(size: size),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, double height, double iconSize) {
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
            height: height,
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
                    size: iconSize,
                  ),
                ),
                Expanded(
                  child: Text(
                    '搜索游戏...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: iconSize * 0.7,
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

  Widget _buildMessageBadge(BuildContext context, double padding) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.isLoggedIn) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: padding),
          child: MessageBadge(),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildProfileAvatar(BuildContext context, double radius, double padding) {
    return StreamBuilder<String?>(
      stream: _userService.getCurrentUserProfile().map((user) => user?.avatar),
      builder: (context, snapshot) {
        final authProvider = Provider.of<AuthProvider>(context);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onProfileTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: padding),
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
                  radius: radius,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: snapshot.hasData && snapshot.data != null
                      ? NetworkImage(snapshot.data!)
                      : null,
                  child: !snapshot.hasData || snapshot.data == null
                      ? Icon(
                    Icons.person_rounded,
                    size: radius * 1.3,
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