// lib/widgets/ui/common/login_prompt_widget.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import '../../../utils/font/font_config.dart';
import '../../../routes/app_routes.dart';

class LoginPromptWidget extends StatelessWidget {
  const LoginPromptWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 600;

    return isDesktop
        ? _buildDesktopLoginPrompt(context)
        : _buildMobileLoginPrompt(context);
  }

  Widget _buildMobileLoginPrompt(BuildContext context) {
    return SingleChildScrollView(
      // 确保内容过多时可以滚动
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                '还未登录',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '登录后可以体验更多功能',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              FunctionalButton(
                onPressed: () {
                  NavigationUtils.navigateToLogin(context);
                },
                label: '立即登录',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLoginPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500, // 桌面端可以给一个固定宽度或者最大宽度
            constraints: const BoxConstraints(maxWidth: 500), // 确保不会过宽
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 高度自适应内容
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 32),
                Text(
                  '您尚未登录',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: FontConfig.defaultFontFamily,
                    fontFamilyFallback: FontConfig.fontFallback,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '登录后即可访问个人资料和更多功能',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: FontConfig.defaultFontFamily,
                    fontFamilyFallback: FontConfig.fontFallback,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisSize: MainAxisSize.min, // 按钮组宽度自适应
                  children: [
                    FunctionalButton(
                      onPressed: () {
                        NavigationUtils.navigateToLogin(context);
                      },
                      label: '立即登录',
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {
                        // 确保 AppRoutes.register 路由已定义
                        NavigationUtils.pushNamed(context, AppRoutes.register);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '注册账号',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: FontConfig.defaultFontFamily,
                          fontFamilyFallback: FontConfig.fontFallback,
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
