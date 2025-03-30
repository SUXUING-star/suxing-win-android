// lib/widgets/components/common/error_widget.dart
import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final IconData icon;
  final String title;
  final String retryText;
  final double iconSize;
  final Color iconColor;

  const CustomErrorWidget({
    Key? key,
    this.errorMessage,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.title = '错误',
    this.retryText = '重新加载',
    this.iconSize = 48.0,
    this.iconColor = Colors.red,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              const SizedBox(height: 16),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(retryText),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// 简化版本，可以嵌入在页面内而不是作为整个页面
class InlineErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final IconData icon;
  final String retryText;
  final double iconSize;
  final Color iconColor;

  const InlineErrorWidget({
    Key? key,
    this.errorMessage,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.retryText = '重新加载',
    this.iconSize = 36.0,
    this.iconColor = Colors.red,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          const SizedBox(height: 12),
          if (errorMessage != null)
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(retryText),
            ),
          ],
        ],
      ),
    );
  }
}

// 网络错误特定版本
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String message;

  const NetworkErrorWidget({
    Key? key,
    this.onRetry,
    this.message = '网络连接错误，请检查您的网络连接后重试',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      errorMessage: message,
      onRetry: onRetry,
      icon: Icons.signal_wifi_off,
      title: '网络错误',
      retryText: '重新连接',
    );
  }
}

// 数据不存在错误版本
class NotFoundErrorWidget extends StatelessWidget {
  final VoidCallback? onBack;
  final String message;

  const NotFoundErrorWidget({
    Key? key,
    this.onBack,
    this.message = '未找到请求的资源',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      errorMessage: message,
      onRetry: onBack,
      icon: Icons.search_off,
      title: '资源不存在',
      retryText: '返回',
      iconColor: Colors.amber,
    );
  }
}

// 登录相关错误组件
class LoginErrorWidget extends StatelessWidget {
  final VoidCallback? onLogin;
  final String message;
  final bool isUnauthorized;

  const LoginErrorWidget({
    Key? key,
    this.onLogin,
    this.message = '您需要登录以继续',
    this.isUnauthorized = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      errorMessage: isUnauthorized
          ? '会话已过期，请重新登录'
          : message,
      onRetry: onLogin,
      icon: Icons.lock_outline,
      title: isUnauthorized ? '会话过期' : '需要登录',
      retryText: '立即登录',
      iconColor: Colors.deepPurple,
    );
  }
}