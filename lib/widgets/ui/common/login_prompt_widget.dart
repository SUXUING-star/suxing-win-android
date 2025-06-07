// lib/widgets/ui/common/login_prompt_widget.dart

/// 该文件定义了 LoginPromptWidget 组件，用于显示登录提示界面。
/// 该组件根据设备类型适配移动端和桌面端的布局。
library;


import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 导入功能按钮
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件

/// `LoginPromptWidget` 类：显示登录提示的组件。
///
/// 该组件根据屏幕宽度适配移动端或桌面端的登录提示布局。
class LoginPromptWidget extends StatelessWidget {
  /// 构造函数。
  const LoginPromptWidget({
    super.key,
  });

  /// 构建登录提示组件。
  ///
  /// 根据屏幕宽度选择构建移动端或桌面端布局。
  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.of(context).size.width >= 600; // 判断是否为桌面屏幕

    return isDesktop
        ? _buildDesktopLoginPrompt(context) // 桌面端布局
        : _buildMobileLoginPrompt(context); // 移动端布局
  }

  /// 构建移动端登录提示布局。
  ///
  /// [context]：Build 上下文。
  /// 该布局包含图标、提示文本和登录按钮。
  Widget _buildMobileLoginPrompt(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined, // 账户图标
                size: 80,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              AppText(
                '还未登录', // 提示文本
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              AppText(
                '登录后可以体验更多功能', // 补充提示文本
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              FunctionalButton(
                onPressed: () {
                  NavigationUtils.navigateToLogin(context); // 导航到登录页面
                },
                label: '立即登录', // 登录按钮文本
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建桌面端登录提示布局。
  ///
  /// [context]：Build 上下文。
  /// 该布局包含卡片、图标、提示文本、登录和注册按钮。
  Widget _buildDesktopLoginPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: Card(
          elevation: 3, // 卡片阴影
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)), // 卡片圆角
          child: Container(
            width: 500, // 卡片宽度
            constraints: const BoxConstraints(maxWidth: 500), // 卡片最大宽度
            padding: const EdgeInsets.all(40), // 卡片内边距
            child: Column(
              mainAxisSize: MainAxisSize.min, // 列主轴尺寸最小化以适应内容
              children: [
                Icon(
                  Icons.account_circle_outlined, // 账户图标
                  size: 100,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 32),
                AppText(
                  '您尚未登录', // 提示文本
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                AppText(
                  '登录后即可访问个人资料和更多功能', // 补充提示文本
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化以适应内容
                  children: [
                    FunctionalButton(
                      onPressed: () {
                        NavigationUtils.navigateToLogin(context); // 导航到登录页面
                      },
                      label: '立即登录', // 登录按钮文本
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {
                        NavigationUtils.pushNamed(
                            context, AppRoutes.register); // 导航到注册页面
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: AppText(
                        '注册账号', // 注册按钮文本
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
