// lib/widgets/ui/common/error_widget.dart

/// 该文件定义了可定制的错误提示组件 CustomErrorWidget。
/// 该文件还定义了用于特定错误场景的内联和专用错误组件。
library;


import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 导入淡入动画组件
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 导入自定义 AppBar
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 导入功能按钮
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件

/// `CustomErrorWidget` 类：一个可定制的错误提示组件。
///
/// 该组件提供详细的错误信息、图标、标题和重试按钮。
class CustomErrorWidget extends StatelessWidget {
  final String? errorMessage; // 详细的错误信息文本
  final VoidCallback? onRetry; // 点击重试按钮的回调
  final IconData icon; // 显示的图标
  final String title; // 错误标题。当 useScaffold 为 true 时，显示在 AppBar 中；否则显示在内容区域图标下方。
  final String retryText; // 重试按钮的文本
  final double iconSize; // 图标大小
  final Color? iconColor; // 图标颜色
  final bool isNeedLoadingAnimation; // 是否使用加载动画 (FadeInItem)
  final bool useScaffold; // 组件是否包裹在 Scaffold 中

  /// 构造函数。
  ///
  /// [errorMessage]：错误信息。
  /// [onRetry]：重试回调。
  /// [icon]：图标。
  /// [title]：标题。
  /// [retryText]：重试按钮文本。
  /// [iconSize]：图标大小。
  /// [iconColor]：图标颜色。
  /// [isNeedLoadingAnimation]：是否需要加载动画。
  /// [useScaffold]：是否包裹在 Scaffold 中。
  const CustomErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.title = '发生意外错误',
    this.retryText = '重新加载',
    this.iconSize = 48.0,
    this.iconColor = Colors.red,
    this.isNeedLoadingAnimation = true,
    this.useScaffold = false,
  });

  /// 构建错误内容。
  ///
  /// 该方法根据配置生成错误图标、标题、消息和重试按钮。
  Widget _buildErrorContent(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    Widget content = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: iconSize), // 错误图标
          const SizedBox(height: 20),

          if (!useScaffold) // 不使用 Scaffold 时显示标题
            AppText(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (!useScaffold) const SizedBox(height: 12),

          if (errorMessage != null && errorMessage!.isNotEmpty)
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),

          if (onRetry != null) ...[
            // 存在重试回调时显示按钮
            const SizedBox(height: 24),
            FunctionalButton(
              onPressed: onRetry,
              label: retryText,
            ),
          ],
        ],
      ),
    );

    if (isNeedLoadingAnimation) {
      // 如果需要动画，则包裹 FadeInItem
      content = FadeInItem(child: Center(child: content));
    } else {
      content = Center(child: content);
    }

    return content;
  }

  /// 构建 CustomErrorWidget。
  ///
  /// 根据 `useScaffold` 参数决定是否包裹在 Scaffold 中。
  @override
  Widget build(BuildContext context) {
    if (useScaffold) {
      // 如果明确要求使用 Scaffold
      return Scaffold(
        appBar: CustomAppBar(title: title), // 标题放在 AppBar
        body: _buildErrorContent(context),
      );
    } else {
      // 默认情况，直接返回内容
      return _buildErrorContent(context);
    }
  }
}

/// `InlineErrorWidget` 类：用于内联显示错误信息的组件。
///
/// 该组件不包含 Scaffold，适用于嵌入到现有布局中。
class InlineErrorWidget extends StatelessWidget {
  final String? errorMessage; // 显示的错误消息
  final VoidCallback? onRetry; // 重试按钮的回调
  final IconData icon; // 显示的图标
  final String retryText; // 重试按钮的文本
  final double iconSize; // 图标大小
  final Color? iconColor; // 图标颜色

  /// 构造函数。
  ///
  /// [errorMessage]：错误信息。
  /// [onRetry]：重试回调。
  /// [icon]：图标。
  /// [retryText]：重试按钮文本。
  /// [iconSize]：图标大小。
  /// [iconColor]：图标颜色。
  const InlineErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.icon = Icons.warning_amber_rounded,
    this.retryText = '重试',
    this.iconSize = 32.0,
    this.iconColor = Colors.orange,
  });

  /// 构建 InlineErrorWidget。
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: iconSize),
            const SizedBox(height: 12),
            if (errorMessage != null && errorMessage!.isNotEmpty)
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withSafeOpacity(0.7),
                ),
              ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FunctionalButton(
                onPressed: onRetry,
                label: retryText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `NetworkErrorWidget` 类：网络错误提示组件。
///
/// 该组件提供网络连接错误的提示。
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry; // 重试按钮的回调
  final String message; // 显示的错误消息
  final bool useScaffold; // 组件是否包裹在 Scaffold 中

  /// 构造函数。
  ///
  /// [onRetry]：重试回调。
  /// [message]：错误消息。
  /// [useScaffold]：是否包裹在 Scaffold 中。
  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.message = '网络连接错误\n请检查您的网络设置后重试',
    this.useScaffold = false,
  });

  /// 构建 NetworkErrorWidget。
  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      errorMessage: message,
      onRetry: onRetry,
      icon: Icons.signal_wifi_off_rounded,
      title: '网络错误',
      retryText: '重新连接',
      iconColor: Colors.lightBlue,
      useScaffold: useScaffold,
    );
  }
}

/// `NotFoundErrorWidget` 类：资源未找到错误提示组件。
///
/// 该组件提供请求内容未找到的提示。
class NotFoundErrorWidget extends StatelessWidget {
  final VoidCallback? onBack; // 返回按钮的回调
  final String message; // 显示的错误消息
  final bool useScaffold; // 组件是否包裹在 Scaffold 中

  /// 构造函数。
  ///
  /// [onBack]：返回回调。
  /// [message]：错误消息。
  /// [useScaffold]：是否包裹在 Scaffold 中。
  const NotFoundErrorWidget({
    super.key,
    this.onBack,
    this.message = '抱歉，未找到您请求的内容',
    this.useScaffold = false,
  });

  /// 构建 NotFoundErrorWidget。
  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnBack = onBack ??
        (Navigator.canPop(context)
            ? () => Navigator.pop(context)
            : null); // 决定返回按钮回调

    return CustomErrorWidget(
      errorMessage: message,
      onRetry: effectiveOnBack,
      icon: Icons.search_off_rounded,
      title: '页面不存在',
      retryText: effectiveOnBack != null ? '返回上一页' : '确定',
      iconColor: Colors.orangeAccent,
      useScaffold: useScaffold,
    );
  }
}

/// `LoginErrorWidget` 类：登录相关错误提示组件。
///
/// 该组件提供登录过期或需要登录的提示。
class LoginErrorWidget extends StatelessWidget {
  final VoidCallback? onLogin; // 登录按钮的回调
  final String message; // 显示的错误消息
  final bool isUnauthorized; // 是否为未授权状态
  final bool useScaffold; // 组件是否包裹在 Scaffold 中

  /// 构造函数。
  ///
  /// [onLogin]：登录回调。
  /// [message]：错误消息。
  /// [isUnauthorized]：是否未授权。
  /// [useScaffold]：是否包裹在 Scaffold 中。
  const LoginErrorWidget({
    super.key,
    this.onLogin,
    this.message = '您需要登录才能访问此内容',
    this.isUnauthorized = false,
    this.useScaffold = false,
  });

  /// 构建 LoginErrorWidget。
  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      errorMessage: isUnauthorized ? '登录状态已过期，请重新登录' : message,
      onRetry: onLogin,
      icon:
          isUnauthorized ? Icons.lock_clock_rounded : Icons.lock_person_rounded,
      title: isUnauthorized ? '请重新登录' : '需要登录',
      retryText: '前往登录',
      iconColor: Colors.deepPurpleAccent,
      useScaffold: useScaffold,
    );
  }
}
