// lib/constants/profile/profile_constants.dart

/// 该文件定义了 ProfileConstants 类，包含用户个人中心界面的菜单项配置。
/// 它提供了一系列 `ProfileMenuItem` 实例，以及对应的颜色方案。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:suxingchahui/constants/profile/profile_menu_item.dart'; // 个人中心菜单项模型
import 'package:suxingchahui/models/user/user.dart'; // 用户模型
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由常量
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart'; // 应用 Snackbar

/// `ProfileConstants` 类：定义用户个人中心界面的常量。
///
/// 该类提供个人中心的菜单项列表及其对应的颜色方案。
class ProfileConstants {
  /// 获取个人中心菜单项列表。
  ///
  /// [context]：Build 上下文。
  /// [isAdmin]：当前用户是否为管理员。
  /// [currentUser]：当前登录用户。
  /// 返回一个 `ProfileMenuItem` 列表。
  static List<ProfileMenuItem> getProfileMenuItems(
      BuildContext context, bool isAdmin, User? currentUser) {
    return [
      if (isAdmin) // 如果是管理员，显示管理员面板
        ProfileMenuItem(
            icon: Icons.admin_panel_settings,
            title: '管理员面板',
            route: AppRoutes.adminDashboard),
      ProfileMenuItem(
        icon: Icons.people_outline,
        title: '我的关注',
        route: '', // 无直接路由
        onTap: () {
          // 点击回调
          if (currentUser != null) {
            // 用户已登录
            NavigationUtils.pushNamed(
                context, AppRoutes.userFollows, // 导航到用户关注页
                arguments: {
                  'userId': currentUser.id,
                  'username': currentUser.username,
                  'initialShowFollowing': true
                });
          }
        },
      ),
      ProfileMenuItem(
        icon: Icons.games_outlined,
        title: '我的游戏',
        route: AppRoutes.myGames,
      ), // 我的游戏
      ProfileMenuItem(
        icon: Icons.forum_outlined,
        title: '我的帖子',
        route: AppRoutes.myPosts,
      ), // 我的帖子
      ProfileMenuItem(
        icon: Icons.collections_bookmark_outlined,
        title: '我的收藏',
        route: AppRoutes.myCollections,
      ), // 我的收藏
      ProfileMenuItem(
        icon: Icons.favorite_border,
        title: '我的喜欢',
        route: AppRoutes.favorites,
      ), // 我的喜欢
      ProfileMenuItem(
        icon: Icons.monetization_on,
        title: '我投币过的游戏',
        route: AppRoutes.coinedGames,
      ), // 我的喜欢
      ProfileMenuItem(
        icon: Icons.rocket_launch_outlined,
        title: '我的动态',
        route: '', // 无直接路由
        onTap: () {
          // 点击回调
          if (currentUser != null) {
            // 用户已登录
            NavigationUtils.pushNamed(
              // 导航到用户动态页
              context,
              AppRoutes.userActivities,
              arguments: currentUser.id,
            );
          } else {
            // 用户未登录
            AppSnackBar.showError('无法加载用户数据'); // 显示错误提示
          }
        },
      ),
      ProfileMenuItem(
          icon: Icons.calendar_today_outlined,
          title: '签到',
          route: AppRoutes.checkin), // 签到
      ProfileMenuItem(
          icon: Icons.history, title: '浏览历史', route: AppRoutes.history), // 浏览历史
      ProfileMenuItem(
        icon: Icons.share_outlined,
        title: '分享应用',
        route: '', // 无直接路由
        onTap: () {
          // 点击回调
          AppSnackBar.showInfo('分享功能开发中'); // 显示提示
        },
      ),
      ProfileMenuItem(
          icon: Icons.info_outline,
          title: '支持我们',
          route: AppRoutes.about), // 支持我们
      ProfileMenuItem(
          icon: Icons.settings,
          title: '设置',
          route: AppRoutes.settingPage), // 设置
    ];
  }

  /// 获取个人中心菜单项的颜色方案。
  ///
  /// 返回一个 Map，键为菜单项标题，值为包含背景色和图标颜色的 Map。
  static Map<String, Map<String, Color>> getProfileMenuColorScheme = {
    '管理员面板': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF6A5ACD),
    },
    '我的关注': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF1E90FF),
    },
    '我的游戏': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Colors.redAccent,
    },
    '我的收藏': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFFFF69B4),
    },
    '我的喜欢': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFFFF7F50),
    },
    "我投币过的游戏": {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Colors.amber,
    },
    '我的动态': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': const Color(0xFF43C2F9),
    },
    '签到': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF3CB371),
    },
    '浏览历史': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF4169E1),
    },
    '我的帖子': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF8B4513),
    },
    '分享应用': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFF008B8B),
    },
    '帮助与反馈': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Color(0xFFDAA520),
    },
    '设置': {
      'background': Colors.white.withSafeOpacity(0.9),
      'icon': Colors.black26,
    },
  };
}
