// lib/widgets/ui/snackbar/app_snackBar.dart

/// 该文件定义了应用内的 SnackBar 通知组件和管理工具。
/// SnackBar 组件支持自定义内容、背景色、图标和操作按钮。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'dart:async'; // 导入 Timer
import 'package:flutter/foundation.dart'; // 导入平台判断功能
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 应用文本组件

/// `_CustomSnackBarWidget` 类：自定义 SnackBar 显示组件。
///
/// 该组件支持消息文本、背景色、图标、持续时间、最大宽度和可选的操作按钮。
class _CustomSnackBarWidget extends StatefulWidget {
  final String message; // 显示的消息文本
  final Color backgroundColor; // SnackBar 背景色
  final IconData iconData; // 显示的图标
  final Duration duration; // SnackBar 显示持续时间
  final VoidCallback onDismissed; // SnackBar 消失时的回调
  final double maxWidth; // SnackBar 最大宽度
  final String? actionLabel; // 操作按钮文本
  final VoidCallback? onActionPressed; // 操作按钮点击回调

  const _CustomSnackBarWidget({
    required this.message,
    required this.backgroundColor,
    required this.iconData,
    required this.duration,
    required this.onDismissed,
    required this.maxWidth,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  _CustomSnackBarWidgetState createState() => _CustomSnackBarWidgetState();
}

/// `_CustomSnackBarWidgetState` 类：`_CustomSnackBarWidget` 的状态管理。
///
/// 管理 SnackBar 的动画、计时器和交互逻辑。
class _CustomSnackBarWidgetState extends State<_CustomSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // 动画控制器
  late Animation<Offset> _offsetAnimation; // 位移动画
  Timer? _dismissTimer; // 自动关闭计时器

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.1, 0.0), // 动画起始位置
      end: Offset.zero, // 动画结束位置
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward(); // 启动进入动画
        _startDismissTimer(); // 启动自动关闭计时器
      }
    });
  }

  /// 启动自动关闭计时器。
  void _startDismissTimer() {
    _dismissTimer?.cancel(); // 取消现有计时器
    _dismissTimer = Timer(widget.duration, _startDismissAnimation); // 设置新的计时器
  }

  /// 启动消失动画。
  void _startDismissAnimation() {
    if (mounted && !_controller.isAnimating) {
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onDismissed(); // 动画结束后调用消失回调
        }
      }).catchError((e) {
        if (mounted) {
          widget.onDismissed(); // 即使动画出错也调用消失回调
        }
      });
    } else if (!mounted) {
      widget.onDismissed(); // 组件未挂载时直接调用消失回调
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel(); // 取消计时器
    _controller.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 处理操作按钮点击事件。
  void _handleActionPressed() {
    _dismissTimer?.cancel(); // 取消自动关闭计时器
    widget.onActionPressed?.call(); // 执行操作按钮回调
    _startDismissAnimation(); // 立即启动关闭动画
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final bool isDesktop = !kIsWeb &&
        (platform == TargetPlatform.windows ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.linux);

    final double fontSize = isDesktop ? 16.0 : 14.0; // 字体大小
    final double iconSize = isDesktop ? 22.0 : 20.0; // 图标大小
    final EdgeInsets padding = isDesktop
        ? EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0)
        : EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0); // 内边距
    final double effectiveMaxWidth = isDesktop
        ? (widget.maxWidth > 450.0 ? widget.maxWidth : 450.0)
        : widget.maxWidth; // 有效最大宽度
    final double spacing = isDesktop ? 12.0 : 10.0; // 元素间距

    Widget? actionButton; // 操作按钮组件
    if (widget.actionLabel != null && widget.onActionPressed != null) {
      actionButton = Padding(
        padding: EdgeInsets.only(left: spacing * 1.5), // 左侧填充
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white, // 按钮文字颜色
            padding:
                EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // 按钮内边距
            minimumSize: Size(0, 36), // 按钮最小尺寸
            visualDensity: VisualDensity.compact, // 视觉密度
            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 点击区域
          ),
          onPressed: _handleActionPressed, // 按钮点击回调
          child: AppText(widget.actionLabel!.toUpperCase(), // 按钮文本
              fontWeight: FontWeight.bold,
              fontSize: fontSize * 0.95), // 按钮字体大小
        ),
      );
    }

    return SlideTransition(
      position: _offsetAnimation, // 应用位移动画
      child: Material(
        elevation: isDesktop ? 6.0 : 4.0, // 阴影高度
        color: widget.backgroundColor, // 背景色
        borderRadius: BorderRadius.circular(isDesktop ? 12.0 : 10.0), // 圆角
        child: Container(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth), // 容器最大宽度
          padding: padding, // 容器内边距
          child: Row(
            mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化以适应内容
            children: [
              Icon(widget.iconData, color: Colors.white, size: iconSize), // 图标
              SizedBox(width: spacing), // 图标与文本间距
              Flexible(
                child: Text(
                  widget.message, // 消息文本
                  style: TextStyle(color: Colors.white, fontSize: fontSize),
                ),
              ),
              if (actionButton != null) actionButton, // 条件渲染操作按钮
            ],
          ),
        ),
      ),
    );
  }
}

/// `AppSnackBar` 类：应用内全局 SnackBar 通知工具类。
///
/// 提供多种类型的 SnackBar 显示方法，支持消息、成功、错误、警告、信息提示。
class AppSnackBar {
  AppSnackBar._(); // 私有构造函数，阻止外部实例化

  static OverlayEntry? _currentOverlayEntry; // 当前显示的 OverlayEntry
  static Timer? _removeTimer; // 移除 SnackBar 的计时器
  static const double _defaultMaxWidth = 450.0; // 默认最大宽度

  /// 核心显示方法：通过 Overlay 显示 SnackBar。
  ///
  /// [dialogContext]：Build 上下文。
  /// [message]：显示的消息文本。
  /// [backgroundColor]：背景色。
  /// [iconData]：图标。
  /// [duration]：持续时间。
  /// [maxWidth]：最大宽度。
  /// [actionLabel]：操作按钮文本。
  /// [onActionPressed]：操作按钮点击回调。
  static void _showOverlaySnackBar(
    String message,
    Color backgroundColor,
    IconData iconData, {
    Duration duration = const Duration(seconds: 3),
    double maxWidth = _defaultMaxWidth,
    String? actionLabel,
    VoidCallback? onActionPressed,
    BuildContext? uiContext,
  }) {
    final BuildContext context =
        uiContext ?? NavigationUtils.getTopmostContext();

    final overlayState = Overlay.of(context); // 获取 OverlayState

    _removeTimer?.cancel(); // 取消旧的移除计时器
    if (_currentOverlayEntry != null) {
      // 移除旧的 SnackBar
      try {
        _currentOverlayEntry!.remove();
      } finally {
        _currentOverlayEntry = null; // 清空引用
      }
    }

    OverlayEntry? entry; // 声明新的 OverlayEntry
    entry = OverlayEntry(
      builder: (context) {
        if (!context.mounted) {
          return const SizedBox.shrink(); // 上下文未挂载时返回空 Widget
        }

        final mediaQuery = MediaQuery.of(context); // 获取 MediaQuery
        final double bottomPadding = mediaQuery.padding.bottom; // 底部安全区
        final double rightPadding = mediaQuery.padding.right; // 右侧安全区

        final double bottomPosition = bottomPadding + 16.0; // SnackBar 底部位置
        final double rightPosition = rightPadding + 16.0; // SnackBar 右侧位置

        return Positioned(
          bottom: bottomPosition,
          right: rightPosition,
          child: _CustomSnackBarWidget(
            message: message,
            backgroundColor: backgroundColor,
            iconData: iconData,
            duration: duration,
            maxWidth: maxWidth,
            actionLabel: actionLabel,
            onActionPressed: onActionPressed,
            onDismissed: () {
              if (_currentOverlayEntry == entry) {
                // 确认是当前显示的 SnackBar
                try {
                  entry?.remove(); // 移除 SnackBar
                } finally {
                  if (_currentOverlayEntry == entry) {
                    _currentOverlayEntry = null; // 清空引用
                  }
                }
              }
            },
          ),
        );
      },
    );

    _currentOverlayEntry = entry; // 保存当前 OverlayEntry 引用
    overlayState.insert(entry); // 插入到 Overlay 中显示
  }

  /// 显示成功消息的 SnackBar。
  ///
  /// [dialogContext]：Build 上下文。
  /// [message]：消息文本。
  /// [maxWidth]：最大宽度。
  /// [duration]：持续时间。
  /// [actionLabel]：操作按钮文本。
  /// [onActionPressed]：操作按钮点击回调。
  static void showSuccess(
    String message, {
    double? maxWidth,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
    BuildContext? uiContext,
  }) {
    _showOverlaySnackBar(
      message,
      Colors.green.shade600,
      Icons.check_circle_outline,
      maxWidth: maxWidth ?? _defaultMaxWidth,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      uiContext: uiContext,
    );
  }

  /// 显示错误消息的 SnackBar。
  ///
  /// [uiContext]：Build 上下文。
  /// [message]：消息文本。
  /// [maxWidth]：最大宽度。
  /// [duration]：持续时间。
  /// [actionLabel]：操作按钮文本。
  /// [onActionPressed]：操作按钮点击回调。
  static void showError(
    String message, {
    double? maxWidth,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    BuildContext? uiContext,
  }) {
    _showOverlaySnackBar(
      message,
      Colors.red.shade600,
      Icons.error_outline,
      maxWidth: maxWidth ?? _defaultMaxWidth,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      uiContext: uiContext,
    );
  }

  /// 显示警告消息的 SnackBar。
  ///
  /// [uiContext]：Build 上下文。
  /// [message]：消息文本。
  /// [maxWidth]：最大宽度。
  /// [duration]：持续时间。
  /// [actionLabel]：操作按钮文本。
  /// [onActionPressed]：操作按钮点击回调。
  static void showWarning(
    String message, {
    double? maxWidth,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
    BuildContext? uiContext,
  }) {
    _showOverlaySnackBar(
      message,
      Colors.orange.shade700,
      Icons.warning_amber_rounded,
      maxWidth: maxWidth ?? _defaultMaxWidth,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      uiContext: uiContext,
    );
  }

  /// 显示信息提示的 SnackBar。
  ///
  /// [uiContext]：Build 上下文。
  /// [message]：消息文本。
  /// [maxWidth]：最大宽度。
  /// [duration]：持续时间。
  /// [actionLabel]：操作按钮文本。
  /// [onActionPressed]：操作按钮点击回调。
  static void showInfo(
    String message, {
    double? maxWidth,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
    BuildContext? uiContext,
  }) {
    _showOverlaySnackBar(
      message,
      Colors.blue.shade600,
      Icons.info_outline,
      maxWidth: maxWidth ?? _defaultMaxWidth,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      uiContext: uiContext,
    );
  }

  /// 隐藏当前显示的 SnackBar。
  static void hideCurrentSnackBar() {
    _removeTimer?.cancel(); // 取消移除计时器
    if (_currentOverlayEntry != null) {
      try {
        _currentOverlayEntry!.remove(); // 移除 SnackBar
      } finally {
        _currentOverlayEntry = null; // 清空引用
      }
    }
  }

  /// 显示提示登录的 SnackBar。
  ///
  /// [context]：Build 上下文。
  static void showLoginRequiredSnackBar(BuildContext context) {
    showWarning(
      '请先登录',
      actionLabel: '去登录',
      onActionPressed: () {
        NavigationUtils.navigateToLogin(context); // 导航到登录页面
      },
      duration: const Duration(seconds: 5),
    );
  }

  /// 显示帖子删除成功的 SnackBar。
  ///
  /// [dialogContext]：Build 上下文。
  static void showPostDeleteSuccessfullySnackBar() {
    showSuccess(
      "你成功删除帖子",
    );
  }

  /// 显示帖子编辑成功的 SnackBar。
  ///
  /// [dialogContext]：Build 上下文。
  static void showPostEditSuccessfullySnackBar() {
    showSuccess(
      "你成功编辑帖子",
    );
  }

  /// 显示游戏删除成功的 SnackBar。
  ///
  /// [dialogContext]：Build 上下文。
  static void showGameDeleteSuccessfullySnackBar() {
    showSuccess(
      "你成功删除游戏",
    );
  }

  /// 显示游戏编辑成功的 SnackBar。
  ///
  /// [dialogContext]：Build 上下文。
  static void showGameEditSuccessfullySnackBar() {
    showSuccess(
      "你成功编辑游戏",
    );
  }

  /// 显示评论编辑成功的 SnackBar。
  ///
  /// [dialogContext]：Build 上下文。
  static void showCommentEditSuccessfullySnackBar() {
    showSuccess(
      "你成功编辑评论",
    );
  }

  /// 显示评论添加成功的 SnackBar。
  ///
  /// [dialogContext]：Build 上下文。
  static void showCommentAddSuccessfullySnackBar() {
    showSuccess(
      "你成功添加评论",
    );
  }

  /// 显示评论删除成功的 SnackBar。
  ///
  /// [dialogContext]：Build 上下文。
  static void showCommentDeleteSuccessfullySnackBar() {
    showSuccess(
      "你成功删除评论",
    );
  }

  /// 显示权限不足的 SnackBar。
  ///
  /// [dialogContext]：Build 上下文。
  static void showPermissionDenySnackBar() {
    showWarning(
      "你没有权限操作",
    );
  }
}
