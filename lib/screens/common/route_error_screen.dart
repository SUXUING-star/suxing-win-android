// lib/screens/common/route_error_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';

/// A unified screen to handle all route navigation errors
///
/// This screen centralizes error handling for invalid routes or route parameters,
/// providing a consistent user experience when navigation errors occur.
class RouteErrorScreen extends StatelessWidget {
  final String errorTitle;
  final String errorMessage;
  final String buttonText;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onAction;
  final bool showHomeButton;

  const RouteErrorScreen({
    super.key,
    this.errorTitle = '路由错误',
    this.errorMessage = '无法访问请求的页面',
    this.buttonText = '返回首页',
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
    this.onAction,
    this.showHomeButton = true,
  });

  /// Factory constructor for invalid ID error cases
  factory RouteErrorScreen.invalidId({
    String resourceType = '资源',
    VoidCallback? onAction,
    bool showHomeButton = true,
  }) {
    return RouteErrorScreen(
      errorTitle: '无效的ID',
      errorMessage: '无法找到所请求的$resourceType，ID可能无效或已被删除',
      icon: Icons.search_off,
      iconColor: Colors.amber,
      onAction: onAction,
      showHomeButton: showHomeButton,
    );
  }

  /// Factory constructor for missing parameter error cases
  factory RouteErrorScreen.missingParameter({
    String paramName = '参数',
    VoidCallback? onAction,
    bool showHomeButton = true,
  }) {
    return RouteErrorScreen(
      errorTitle: '缺少参数',
      errorMessage: '请求缺少必要的$paramName信息',
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orange,
      onAction: onAction,
      showHomeButton: showHomeButton,
    );
  }

  /// Factory constructor for unauthorized access error cases
  factory RouteErrorScreen.unauthorized({
    String message = '您需要登录才能访问此页面',
    VoidCallback? onLogin,
    bool showHomeButton = true,
  }) {
    return RouteErrorScreen(
      errorTitle: '需要登录',
      errorMessage: message,
      buttonText: '去登录',
      icon: Icons.lock_outline,
      iconColor: Colors.deepPurple,
      onAction: onLogin,
      showHomeButton: showHomeButton,
    );
  }

  /// Factory constructor for resource not found error cases
  factory RouteErrorScreen.notFound({
    String resourceType = '资源',
    VoidCallback? onAction,
    bool showHomeButton = true,
  }) {
    return RouteErrorScreen(
      errorTitle: '未找到',
      errorMessage: '无法找到请求的$resourceType',
      icon: Icons.search_off,
      iconColor: Colors.amber,
      onAction: onAction,
      showHomeButton: showHomeButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: errorTitle),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 64),
              const SizedBox(height: 24),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              if (onAction != null) ...[
                FunctionalButton(
                  onPressed: () => onAction,
                  label: buttonText,
                ),
                const SizedBox(height: 16),
              ],
              if (showHomeButton &&
                  (onAction == null || buttonText != '返回首页')) ...[
                TextButton(
                  onPressed: () {
                    NavigationUtils.navigateToHome(context);
                  },
                  child: const Text('返回首页'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
