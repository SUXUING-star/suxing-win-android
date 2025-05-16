// lib/widgets/ui/common/error_widget.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 假设你这个动画组件存在
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 假设你的 AppBar 存在
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 假设你的按钮存在

/// 一个可定制的错误提示 Widget。
/// 可以选择是否包裹在 Scaffold 中。
class CustomErrorWidget extends StatelessWidget {
  /// 详细的错误信息文本。
  final String? errorMessage;
  /// 点击重试按钮的回调。
  final VoidCallback? onRetry;
  /// 显示的图标。
  final IconData icon;
  /// 错误标题。
  /// 如果 useScaffold 为 true，显示在 AppBar 中。
  /// 如果 useScaffold 为 false，显示在内容区域图标下方。
  final String title;
  /// 重试按钮的文本。
  final String retryText;
  /// 图标大小。
  final double iconSize;
  /// 图标颜色。
  final Color? iconColor;
  /// 是否需要加载动画（FadeInItem）。
  final bool isNeedLoadingAnimation;
  /// 是否将此 Widget 包裹在一个 Scaffold 中。
  /// **默认为 `false`**，以避免嵌套 Scaffold 导致的问题。
  /// 只有当你需要这个错误组件作为独立页面显示（带 AppBar）时，才设置为 `true`。
  final bool useScaffold;

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
    this.useScaffold = false, // 默认不使用 Scaffold
  });

  Widget _buildErrorContent(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    Widget content = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // 确保文本居中
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          const SizedBox(height: 20), // 稍微增大间距

          // 如果不使用 Scaffold，就在这里显示标题
          if (!useScaffold)
            AppText(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600, // 加粗一点标题
              ),
            ),
          if (!useScaffold) const SizedBox(height: 12), // 标题和错误信息间距

          if (errorMessage != null && errorMessage!.isNotEmpty)
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.error, // 使用主题的错误颜色，更语义化
              ),
            ),

          if (onRetry != null) ...[
            const SizedBox(height: 24),
            FunctionalTextButton(
              onPressed: onRetry,
              label: retryText,
            ),
          ],
        ],
      ),
    );

    // 如果需要动画，包裹 FadeInItem
    if (isNeedLoadingAnimation) {
      content = FadeInItem(child: Center(child: content));
    } else {
      content = Center(child: content);
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    if (useScaffold) {
      // 如果明确要求使用 Scaffold
      return Scaffold(
        appBar: CustomAppBar(title: title), // 标题放在 AppBar
        body: _buildErrorContent(context),
      );
    } else {
      // 默认情况，直接返回内容，方便嵌入
      return _buildErrorContent(context);
    }
  }
}

// --- InlineErrorWidget 保持不变，因为它设计上就是内联的，不需要Scaffold ---
class InlineErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final IconData icon;
  final String retryText;
  final double iconSize;
  final Color? iconColor;

  const InlineErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.icon = Icons.warning_amber_rounded, // 换个稍微柔和点的图标
    this.retryText = '重试', // 简化重试文本
    this.iconSize = 32.0, // 内联的可以小一点
    this.iconColor = Colors.orange, // 内联的用警告色可能更好
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding( // 使用 Padding 代替 Container+Color，更灵活
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
                  color: theme.colorScheme.onSurface.withSafeOpacity(0.7), // 柔和一点的文本色
                ),
              ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FunctionalTextButton( // 可以考虑换成更小的按钮样式，如果 FunctionalTextButton 支持的话
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

// --- 更新专用错误组件，添加 useScaffold 参数 ---

// 网络错误特定版本
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String message;
  /// 是否作为独立页面显示 (带 AppBar)。默认为 true。
  final bool useScaffold;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.message = '网络连接错误\n请检查您的网络设置后重试', // 优化换行
    this.useScaffold = true, // 网络错误通常是全屏，默认带 Scaffold
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      errorMessage: message,
      onRetry: onRetry,
      icon: Icons.signal_wifi_off_rounded, // 使用圆角图标
      title: '网络错误',
      retryText: '重新连接',
      iconColor: Colors.lightBlue, // 换个网络相关的颜色
      useScaffold: useScaffold, // 传递参数
    );
  }
}

// 数据不存在错误版本
class NotFoundErrorWidget extends StatelessWidget {
  final VoidCallback? onBack;
  final String message;
  /// 是否作为独立页面显示 (带 AppBar)。默认为 true。
  final bool useScaffold;

  const NotFoundErrorWidget({
    super.key,
    this.onBack,
    this.message = '抱歉，未找到您请求的内容',
    this.useScaffold = true, // Not Found 通常也是全屏，默认带 Scaffold
  });

  @override
  Widget build(BuildContext context) {
    // 如果没有提供 onBack 回调，尝试自动获取 Navigator 并 pop
    final VoidCallback? effectiveOnBack = onBack ??
        (Navigator.canPop(context) ? () => Navigator.pop(context) : null);

    return CustomErrorWidget(
      errorMessage: message,
      onRetry: effectiveOnBack, // 使用处理过的回调
      icon: Icons.search_off_rounded, // 使用圆角图标
      title: '页面不存在',
      retryText: effectiveOnBack != null ? '返回上一页' : '确定', // 动态按钮文本
      iconColor: Colors.orangeAccent, // 换个稍微柔和的颜色
      useScaffold: useScaffold, // 传递参数
    );
  }
}

// 登录相关错误组件
class LoginErrorWidget extends StatelessWidget {
  final VoidCallback? onLogin;
  final String message;
  final bool isUnauthorized;
  /// 是否作为独立页面显示 (带 AppBar)。默认为 true。
  final bool useScaffold;

  const LoginErrorWidget({
    super.key,
    this.onLogin,
    this.message = '您需要登录才能访问此内容',
    this.isUnauthorized = false,
    this.useScaffold = true, // 登录提示通常也是全屏，默认带 Scaffold
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      errorMessage: isUnauthorized ? '登录状态已过期，请重新登录' : message,
      onRetry: onLogin,
      icon: isUnauthorized ? Icons.lock_clock_rounded : Icons.lock_person_rounded, // 根据场景用不同图标
      title: isUnauthorized ? '请重新登录' : '需要登录',
      retryText: '前往登录',
      iconColor: Colors.deepPurpleAccent, // 换个稍微亮点的颜色
      useScaffold: useScaffold, // 传递参数
    );
  }
}