import 'package:flutter/material.dart';
import '../../utils/device/device_utils.dart';
import '../../screens/search/search_screen.dart';
import '../../models/user/user.dart';
import '../../services/main/user/user_service.dart';
import '../../providers/auth/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/logo/star_logo.dart';
import '../../widgets/common/button/update_button.dart';
import '../../widgets/components/screen/message/message_badge.dart';
import '../../widgets/common/image/safe_user_avatar.dart';
import '../../widgets/components/indicators/announcement_indicator.dart';
// 添加网络状态指示器
import '../../widgets/components/indicators/network_status_indicator.dart';

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
        // 添加网络状态指示器
        _buildNetworkStatusIndicator(context, verticalPadding),
        const SizedBox(width: 8),
        // 添加公告指示器
        _buildAnnouncementIndicator(context, verticalPadding),
        const SizedBox(width: 8),
        _buildMessageBadge(context, verticalPadding),
        const SizedBox(width: 8),
        _buildProfileAvatar(context, avatarRadius, verticalPadding),
        const SizedBox(width: 16),
      ],
    );
  }

  // 添加网络状态指示器构建方法
  Widget _buildNetworkStatusIndicator(BuildContext context, double padding) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding),
        child: const NetworkStatusIndicator(
          onReconnect: null, // 可以添加重连回调
        ),
      ),
    );
  }

  // 添加公告指示器构建方法
  Widget _buildAnnouncementIndicator(BuildContext context, double padding) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding),
        child: const AnnouncementIndicator(),
      ),
    );
  }

  Widget _buildLeadingLogo(BuildContext context, double size, double padding) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onLogoTap,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: StarLogo(size: size),
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
    // 添加空值检查
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // If not logged in, show default avatar
        if (!authProvider.isLoggedIn) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: padding),
            child: GestureDetector(
              onTap: onProfileTap,
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
                  child: Icon(
                    Icons.person_rounded,
                    size: radius * 1.3,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          );
        }

        // For logged in users, use StreamBuilder with getCurrentUser
        // instead of SafeUserAvatar which has issues
        return StreamBuilder<User?>(
          stream: _userService.getCurrentUserProfile(),
          builder: (context, snapshot) {
            return Padding(
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
                child: GestureDetector(
                  onTap: onProfileTap,
                  child: snapshot.hasData && snapshot.data?.avatar != null
                      ? ClipOval(
                    child: Image.network(
                      snapshot.data!.avatar!,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return CircleAvatar(
                          radius: radius,
                          backgroundColor: Colors.grey[100],
                          child: Text(
                            snapshot.data?.username?[0].toUpperCase() ?? '?',
                            style: TextStyle(
                              fontSize: radius * 0.8,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                      : CircleAvatar(
                    radius: radius,
                    backgroundColor: Colors.grey[100],
                    child: Icon(
                      Icons.person_rounded,
                      size: radius * 1.3,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}