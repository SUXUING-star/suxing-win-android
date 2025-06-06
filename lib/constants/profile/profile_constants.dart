// lib/constants/profile/profile_constants.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/profile/profile_menu_item.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

class ProfileConstants {
  static List<ProfileMenuItem> getProfileMenuItems(
      BuildContext context, bool isAdmin, User? currentUser) {
    return [
      if (isAdmin)
        ProfileMenuItem(
            icon: Icons.admin_panel_settings,
            title: '管理员面板',
            route: AppRoutes.adminDashboard),
      ProfileMenuItem(
        icon: Icons.people_outline,
        title: '我的关注',
        route: '',
        onTap: () {
          if (currentUser != null) {
            NavigationUtils.pushNamed(context, AppRoutes.userFollows,
                arguments: {
                  'userId': currentUser.id,
                  'username': currentUser.username,
                  'initialShowFollowing': true
                });
          }
        },
      ),
      ProfileMenuItem(
          icon: Icons.games_outlined, title: '我的游戏', route: AppRoutes.myGames),
      ProfileMenuItem(
          icon: Icons.forum_outlined, title: '我的帖子', route: AppRoutes.myPosts),
      ProfileMenuItem(
          icon: Icons.collections_bookmark_outlined,
          title: '我的收藏',
          route: AppRoutes.myCollections),
      ProfileMenuItem(
          icon: Icons.favorite_border,
          title: '我的喜欢',
          route: AppRoutes.favorites),
      ProfileMenuItem(
        icon: Icons.rocket_launch_outlined,
        title: '我的动态',
        route: '',
        onTap: () {
          if (currentUser != null) {
            NavigationUtils.pushNamed(
              context,
              AppRoutes.userActivities,
              arguments: currentUser.id,
            );
          } else {
            if (context.mounted) AppSnackBar.showError(context, '无法加载用户数据');
          }
        },
      ),
      ProfileMenuItem(
          icon: Icons.calendar_today_outlined,
          title: '签到',
          route: AppRoutes.checkin),
      ProfileMenuItem(
          icon: Icons.history, title: '浏览历史', route: AppRoutes.history),
      ProfileMenuItem(
          icon: Icons.share_outlined,
          title: '分享应用',
          route: '',
          onTap: () {
            if (context.mounted) AppSnackBar.showInfo(context, '分享功能开发中');
          }),
      ProfileMenuItem(
          icon: Icons.info_outline, title: '支持我们', route: AppRoutes.about),
      ProfileMenuItem(
          icon: Icons.settings, title: '设置', route: AppRoutes.settingPage),
    ];
  }

  static Map<String, Map<String, Color>> getProfileMenuColorScheme = {
    '管理员面板': {
      'background': Colors.white.withSafeOpacity(0.9), // 淡紫色
      'icon': Color(0xFF6A5ACD), // 深紫色
    },
    '我的关注': {
      'background': Colors.white.withSafeOpacity(0.9), // 淡蓝色
      'icon': Color(0xFF1E90FF), // 道奇蓝
    },
    '我的游戏': {
      'background': Colors.white.withSafeOpacity(0.9), // 淡蓝色
      'icon': Colors.redAccent, // 红
    },
    '我的收藏': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFFFF69B4), // 热粉色
    },
    '我的喜欢': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFFFF7F50), // 珊瑚色
    },
    '我的动态': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF43C2F9),
    },
    '签到': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF3CB371), // 中海绿
    },
    '浏览历史': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF4169E1), // 皇家蓝
    },
    '我的帖子': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF8B4513), // 马鞍棕
    },
    '分享应用': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF008B8B), // 深青色
    },
    '帮助与反馈': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFFDAA520), // 金杆色
    },
    '设置': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Colors.black26, // 金杆色
    },
  };
}
