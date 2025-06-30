// lib/constants/profile/profile_menu_item.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/preset/super_color_theme.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';

class ProfileMenuItem implements SuperColorThemeExtension {
  final String route;

  ProfileMenuItem({
    required this.route,
  });

  factory ProfileMenuItem.fromRoute(String route) =>
      ProfileMenuItem(route: route);

  // 特殊路由标识，用于没有直接页面路由但有 onTap 回调的项
  static const shareAppRoute = 'share';

  @override
  Color getTextColor() => getMenuTheme(route).textColor;

  @override
  String getTextLabel() => getMenuTheme(route).textLabel;

  @override
  IconData getIconData() => getMenuTheme(route).iconData;

  @override
  Color getBackgroundColor() => getMenuTheme(route).backgroundColor;

  @override
  Color getIconColor() => getMenuTheme(route).iconColor;

  static List<ProfileMenuItem> getProfileMenuItems(bool isAdmin) =>
      fromRoutes(getProfileMenuRoutes(isAdmin));

  static List<ProfileMenuItem> fromRoutes(List<String> routes) =>
      routes.map((r) => ProfileMenuItem.fromRoute(r)).toList();

  static List<String> getProfileMenuRoutes(bool isAdmin) => [
        if (isAdmin) AppRoutes.adminDashboard,
        AppRoutes.userFollows,
        AppRoutes.myGames,
        AppRoutes.myPosts,
        AppRoutes.myCollections,
        AppRoutes.favorites,
        AppRoutes.coinedGames,
        AppRoutes.userActivities,
        AppRoutes.checkin,
        AppRoutes.history,
        shareAppRoute, // 分享应用
        AppRoutes.about,
        AppRoutes.settingPage,
      ];

  /// 根据路由获取菜单项的显示属性
  static SuperColorTheme getMenuTheme(String route) {
    switch (route) {
      case AppRoutes.adminDashboard:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.admin_panel_settings,
            textLabel: '管理员面板',
            iconColor: const Color(0xFF6A5ACD));
      case AppRoutes.userFollows:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.people_outline,
            textLabel: '我的关注',
            iconColor: const Color(0xFF1E90FF));
      case AppRoutes.myGames:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.games_outlined,
            textLabel: '我的游戏',
            iconColor: Colors.redAccent);
      case AppRoutes.myPosts:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.forum_outlined,
            textLabel: '我的帖子',
            iconColor: const Color(0xFF8B4513));
      case AppRoutes.myCollections:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.collections_bookmark_outlined,
            textLabel: '我的收藏',
            iconColor: const Color(0xFFFF69B4));
      case AppRoutes.favorites:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.favorite_border,
            textLabel: '我的喜欢',
            iconColor: const Color(0xFFFF7F50));
      case AppRoutes.coinedGames:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.monetization_on,
            textLabel: '我投币过的游戏',
            iconColor: Colors.amber);
      case AppRoutes.userActivities:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.rocket_launch_outlined,
            textLabel: '我的动态',
            iconColor: const Color(0xFF43C2F9));
      case AppRoutes.checkin:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.calendar_today_outlined,
            textLabel: '签到',
            iconColor: const Color(0xFF3CB371));
      case AppRoutes.history:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.history,
            textLabel: '浏览历史',
            iconColor: const Color(0xFF4169E1));
      case shareAppRoute:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.share_outlined,
            textLabel: '分享应用',
            iconColor: const Color(0xFF008B8B));
      case AppRoutes.about:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.info_outline,
            textLabel: '支持我们',
            iconColor: const Color(0xFFDAA520));
      case AppRoutes.settingPage:
        return SuperColorTheme(
            backgroundColor: Colors.white.withSafeOpacity(0.9),
            textColor: Colors.black87,
            iconData: Icons.settings,
            textLabel: '设置',
            iconColor: Colors.black26);
      default:
        return SuperColorTheme(
            backgroundColor: Colors.red.shade100,
            textColor: Colors.red,
            iconData: Icons.error,
            textLabel: '未知路由',
            iconColor: Colors.red);
    }
  }

  static VoidCallback? getMenuTap(
      String route, BuildContext context, User? currentUser) {
    switch (route) {
      // '我的关注' 需要 currentUser 信息来构造参数
      case AppRoutes.userFollows:
        return () {
          if (currentUser != null) {
            NavigationUtils.pushNamed(context, AppRoutes.userFollows,
                arguments: {
                  'userId': currentUser.id,
                  'username': currentUser.username,
                  'initialShowFollowing': true
                });
          }
        };

      // '我的动态' 需要 currentUser 信息来构造参数
      case AppRoutes.userActivities:
        return () {
          if (currentUser != null) {
            NavigationUtils.pushNamed(
              context,
              AppRoutes.userActivities,
              arguments: currentUser.id,
            );
          } else {
            AppSnackBar.showError('无法加载用户数据');
          }
        };

      // '分享应用' 只有 onTap，没有路由
      case ProfileMenuItem.shareAppRoute:
        return () {
          AppSnackBar.showInfo('分享功能开发中');
        };

      // 其他所有路由都没有特殊的 onTap 逻辑，返回 null，由外部进行标准导航。
      default:
        return null;
    }
  }
}

extension ProfileMenuItemExtension on ProfileMenuItem {
  VoidCallback? onTap(BuildContext context, User? currentUser) =>
      ProfileMenuItem.getMenuTap(route, context, currentUser);
}
