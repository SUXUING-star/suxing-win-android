// lib/widgets/layouts/desktop/desktop_sidebar_user_profile.dart

/// 该文件定义了 DesktopSidebarUserProfile 组件，用于桌面侧边栏的用户资料显示。
/// DesktopSidebarUserProfile 根据用户登录状态显示登录提示或已登录用户的信息。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/user/user/user_extension.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/badges/safe_user_avatar.dart'; // 导入安全用户头像组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/models/user/user/user.dart'; // 导入用户模型

/// `DesktopSidebarUserProfile` 类：桌面侧边栏用户资料组件。
///
/// 该组件根据用户登录状态显示登录提示或已登录用户的信息。
class DesktopSidebarUserProfile extends StatelessWidget {
  final VoidCallback onProfileTap; // 点击用户资料时的回调
  final AuthProvider authProvider; // 认证 Provider 实例

  /// 构造函数。
  ///
  /// [onProfileTap]：点击用户资料回调。
  /// [authProvider]：认证 Provider。
  const DesktopSidebarUserProfile({
    super.key,
    required this.onProfileTap,
    required this.authProvider,
  });

  /// 构建未登录状态的用户头像和登录入口。
  ///
  /// [context]：Build 上下文。
  /// 返回一个点击可导航到登录页面的组件。
  Widget _buildLoginPrompt(BuildContext context) {
    return Material(
      color: Colors.transparent, // 背景透明
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
        child: InkWell(
          onTap: () => NavigationUtils.navigateToLogin(context), // 点击导航到登录页
          hoverColor: Colors.white.withSafeOpacity(0.1), // 悬停颜色
          borderRadius: BorderRadius.circular(20), // 圆角
          child: Tooltip(
            message: '登录', // 提示文本
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
              children: [
                Container(
                  width: 40, // 宽度
                  height: 40, // 高度
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, // 形状为圆形
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20, // 半径
                    backgroundColor: Colors.white.withSafeOpacity(0.2), // 背景色
                    child: Icon(
                      Icons.person_rounded, // 图标
                      size: 24, // 大小
                      color: Colors.white, // 颜色
                    ),
                  ),
                ),
                const SizedBox(height: 4), // 间距
                const Text(
                  '点击登录', // 文本
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建已登录状态的用户信息。
  ///
  /// [context]：Build 上下文。
  /// [user]：用户数据。
  /// 返回一个包含用户头像、等级、用户名和经验值的组件。
  Widget _buildLoggedInProfile(BuildContext context, User user) {
    final avatarRadiusInProfile = 50; // 头像半径

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio; // 设备像素比
    final int calculatedMemCacheSize =
        (avatarRadiusInProfile * 2 * devicePixelRatio).round(); // 内存缓存大小

    return Material(
      color: Colors.transparent, // 背景透明
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
        child: InkWell(
          onTap: onProfileTap, // 点击回调
          hoverColor: Colors.white.withSafeOpacity(0.1), // 悬停颜色
          borderRadius: BorderRadius.circular(20), // 圆角
          child: Tooltip(
            message: '我的资料', // 提示文本
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
              children: [
                Stack(
                  alignment: Alignment.center, // 堆栈内容居中
                  children: [
                    Container(
                        width: 40, // 宽度
                        height: 40, // 高度
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, // 形状为圆形
                          border:
                              Border.all(color: Colors.white, width: 1.5), // 边框
                        ),
                        child: SafeUserAvatar(
                          userId: user.id, // 用户ID
                          avatarUrl: user.avatar, // 头像 URL
                          username: user.username, // 用户名
                          radius: 50, // 半径
                          enableNavigation: false, // 禁用导航
                          memCacheWidth: calculatedMemCacheSize, // 内存缓存宽度
                          memCacheHeight: calculatedMemCacheSize, // 内存缓存高度
                        )),
                    Positioned(
                      right: 0, // 右侧对齐
                      bottom: 0, // 底部对齐
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1), // 内边距
                        decoration: BoxDecoration(
                          color: user.enrichLevel.backgroundColor, // 背景色
                          borderRadius: BorderRadius.circular(8), // 圆角
                          border:
                              Border.all(color: Colors.white, width: 1), // 边框
                        ),
                        child: Text(
                          'Lv.${user.level}', // 等级文本
                          style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold), // 字体样式
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // 间距
                Padding(
                  padding: const EdgeInsets.only(top: 2.0), // 顶部填充
                  child: Text(
                    user.username, // 用户名文本
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold), // 字体样式
                    overflow: TextOverflow.ellipsis, // 文本溢出显示省略号
                    maxLines: 1, // 最大行数
                  ),
                ),
                Text(
                  '硬币 ${user.coins}', // 经验值文本
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withSafeOpacity(0.8)), // 字体样式
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建桌面侧边栏用户资料组件。
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 12.0, horizontal: 8.0), // 垂直和水平填充
      child: StreamBuilder<User?>(
        stream: authProvider.currentUserStream, // 监听当前用户流
        initialData: authProvider.currentUser, // 初始当前用户数据
        builder: (context, currentUserSnapshot) {
          final User? currentUser = currentUserSnapshot.data; // 获取当前用户数据

          if (currentUser == null) {
            // 未登录状态
            return _buildLoginPrompt(context); // 显示登录提示
          }

          return _buildLoggedInProfile(context, currentUser); // 显示已登录用户资料
        },
      ),
    );
  }
}
