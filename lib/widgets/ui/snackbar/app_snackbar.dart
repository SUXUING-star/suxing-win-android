// lib/widgets/ui/snackbar/app_snackbar.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';

// _CustomSnackBarWidget - 添加 action 支持
class _CustomSnackBarWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData iconData;
  final Duration duration;
  final VoidCallback onDismissed;
  final double maxWidth;
  final String? actionLabel; // <-- 新增：操作按钮文字
  final VoidCallback? onActionPressed; // <-- 新增：操作按钮回调

  const _CustomSnackBarWidget({
    Key? key,
    required this.message,
    required this.backgroundColor,
    required this.iconData,
    required this.duration,
    required this.onDismissed,
    required this.maxWidth,
    this.actionLabel, // <-- 设为可选
    this.onActionPressed, // <-- 设为可选
  }) : super(key: key);

  @override
  _CustomSnackBarWidgetState createState() => _CustomSnackBarWidgetState();
}

class _CustomSnackBarWidgetState extends State<_CustomSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.1, 0.0), // 从右侧稍微偏外的位置开始
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // 使用 addPostFrameCallback 确保 BuildContext 可用且 Widget 已构建
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
        // 只有在没有 Action 或者 Action 不需要手动关闭时才启动自动关闭计时器
        // 如果有 Action，通常希望用户点击 Action 后再关闭，或者超时后关闭
        // 这里我们保持原来的逻辑：无论有无Action，都按duration自动关闭
        _startDismissTimer();
      }
    });
  }

  void _startDismissTimer() {
    // 先取消可能存在的旧计时器
    _dismissTimer?.cancel();
    // 设置新的自动关闭计时器
    _dismissTimer = Timer(widget.duration, _startDismissAnimation);
  }

  void _startDismissAnimation() {
    if (mounted && !_controller.isAnimating) {
      // 检查是否正在动画中
      _controller.reverse().then((_) {
        // 等动画结束后再调用 onDismissed
        if (mounted) {
          widget.onDismissed();
        }
      }).catchError((e) {
        // 如果 reverse 过程中 widget 被 dispose，可能会出错
        print("Error during reverse animation: $e");
        if (mounted) {
          widget.onDismissed(); // 确保即使动画出错也调用
        }
      });
    } else if (!mounted) {
      widget.onDismissed(); // 如果已经 unmounted，直接调用
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleActionPressed() {
    // 1. 取消自动关闭计时器 (如果存在)
    _dismissTimer?.cancel();
    // 2. 执行传入的回调
    widget.onActionPressed?.call();
    // 3. 立即开始关闭动画
    _startDismissAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final bool isDesktop = !kIsWeb &&
        (platform == TargetPlatform.windows ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.linux);

    final double fontSize = isDesktop ? 16.0 : 14.0;
    final double iconSize = isDesktop ? 22.0 : 20.0;
    final EdgeInsets padding = isDesktop
        ? EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0)
        : EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    final double effectiveMaxWidth = isDesktop
        ? (widget.maxWidth > 450.0 ? widget.maxWidth : 450.0)
        : widget.maxWidth;
    final double spacing = isDesktop ? 12.0 : 10.0;

    // --- 构建 Action Button (如果提供了 label 和 onPressed) ---
    Widget? actionButton;
    if (widget.actionLabel != null && widget.onActionPressed != null) {
      actionButton = Padding(
        // 给按钮和消息文本之间加点间距
        padding: EdgeInsets.only(left: spacing * 1.5), // 稍微加大间距
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white, // 按钮文字颜色
            padding:
                EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // 按钮内边距
            minimumSize: Size(0, 36), // 最小点击区域
            visualDensity: VisualDensity.compact, // 更紧凑
            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 点击区域适应内容
          ),
          // onPressed: widget.onActionPressed, // <-- 直接调用外部传入的回调
          onPressed: _handleActionPressed, // <-- 调用封装好的处理函数
          child: Text(
            widget.actionLabel!.toUpperCase(), // 类似原生，用大写
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize * 0.95), // 字体加粗稍微小一点
          ),
        ),
      );
    }

    return SlideTransition(
      position: _offsetAnimation,
      child: Material(
        elevation: isDesktop ? 6.0 : 4.0,
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(isDesktop ? 12.0 : 10.0),
        child: Container(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min, // 让 Row 包裹内容
            children: [
              Icon(widget.iconData, color: Colors.white, size: iconSize),
              SizedBox(width: spacing),
              Flexible(
                // 让文本可以换行
                child: Text(
                  widget.message,
                  style: TextStyle(color: Colors.white, fontSize: fontSize),
                ),
              ),
              // --- 条件渲染 Action Button ---
              if (actionButton != null) actionButton,
            ],
          ),
        ),
      ),
    );
  }
}

/// 应用内全局 SnackBar 通知工具类 (接口不变，内部Widget已适配平台)
class AppSnackBar {
  AppSnackBar._();

  static OverlayEntry? _currentOverlayEntry;
  static Timer? _removeTimer;
  static const double _defaultMaxWidth = 450.0;

  /// 核心显示方法 - 使用 Overlay
  static void _showOverlaySnackBar(
      BuildContext context,
      String message,
      Color backgroundColor,
      IconData iconData, {
        Duration duration = const Duration(seconds: 3),
        double maxWidth = _defaultMaxWidth,
        String? actionLabel, // <-- 新增: Action 文字
        VoidCallback? onActionPressed, // <-- 新增: Action 回调
      }) {
    // 如果 context 不再可用，直接返回
    if (!context.mounted) {
      print("AppSnackBar Error: BuildContext is not mounted. Cannot show SnackBar.");
      return;
    }

    // 获取 OverlayState
    final overlayState = Overlay.of(context);
    if (overlayState == null) {
      print("AppSnackBar Error: Could not find OverlayState. Make sure you have a MaterialApp/WidgetsApp parent.");
      return;
    }

    // 如果已有 SnackBar 显示，先移除旧的
    _removeTimer?.cancel(); // 取消可能存在的移除计时器
    if (_currentOverlayEntry != null) {
      try {
        _currentOverlayEntry!.remove();
      } catch (e) {
        print("Error removing previous OverlayEntry: $e");
      } finally {
        _currentOverlayEntry = null; // 确保置空
      }
    }


    OverlayEntry? entry; // 先声明 entry 变量
    entry = OverlayEntry(
      builder: (context) {
        // 在 builder 内部再次检查 context 的有效性（虽然理论上此时应该有效）
        if (!context.mounted) {
          // 如果在此期间 context 失效，则不构建任何东西
          // 或者可以返回一个空的 Container
          print("AppSnackBar Warning: BuildContext became unmounted during OverlayEntry build.");
          // 尝试移除自身？但这比较复杂，因为 entry 可能还没插入
          // 最好是外部调用前就确保 context 有效
          return const SizedBox.shrink(); // 返回空 Widget
        }

        // 使用 MediaQuery.of(context) 获取安全边距
        final mediaQuery = MediaQuery.of(context);
        final double bottomPadding = mediaQuery.padding.bottom;
        final double rightPadding = mediaQuery.padding.right; // 考虑右侧安全区域
        // 定义 SnackBar 的位置
        final double bottomPosition = bottomPadding + 16.0; // 距离底部安全区 16px
        final double rightPosition = rightPadding + 16.0; // 距离右侧安全区 16px

        return Positioned(
          bottom: bottomPosition,
          right: rightPosition,
          child: _CustomSnackBarWidget(
            message: message,
            backgroundColor: backgroundColor,
            iconData: iconData,
            duration: duration,
            maxWidth: maxWidth,
            actionLabel: actionLabel,         // <-- 传递 actionLabel
            onActionPressed: onActionPressed, // <-- 传递 onActionPressed
            onDismissed: () {
              // _removeTimer = Timer(const Duration(milliseconds: 50), () {
              //   // 确保我们移除的是当前的 entry，防止快速连续调用导致移除错误的 entry
              //   if (_currentOverlayEntry == entry) {
              //     try {
              //       entry?.remove(); // 使用 entry 变量
              //     } catch (e) {
              //       print("Error removing OverlayEntry in onDismissed: $e");
              //     } finally {
              //       _currentOverlayEntry = null; // 清理引用
              //     }
              //   }
              // });
              // --- 改进 onDismissed 逻辑 ---
              // 动画结束后，立即尝试移除，不需要 Timer
              // 检查 entry 是否仍然是当前的 _currentOverlayEntry
              if (_currentOverlayEntry == entry) {
                try {
                  // 再次检查 entry 是否还在树上 (虽然理论上此时应该在)
                  // Flutter 3.7+ overlayEntry.mounted
                  // if (entry?.mounted ?? false) { // Requires Flutter 3.7+
                  entry?.remove();
                  // }
                } catch (e) {
                  print("Error removing OverlayEntry in onDismissed: $e");
                } finally {
                  // 只有当成功移除的是当前 entry 时才清空引用
                  if (_currentOverlayEntry == entry) {
                    _currentOverlayEntry = null;
                  }
                }
              }
            },
          ),
        );
      },
    );

    _currentOverlayEntry = entry; // 保存当前 entry 的引用
    overlayState.insert(entry); // 插入到 Overlay 中显示
  }

  // --- 修改公共方法以接收 Action 参数 ---

  static void showSuccess(
      BuildContext context,
      String message, {
        double? maxWidth,
        Duration duration = const Duration(seconds: 3),
        String? actionLabel,
        VoidCallback? onActionPressed,
      }) {
    _showOverlaySnackBar(
      context,
      message,
      Colors.green.shade600,
      Icons.check_circle_outline,
      maxWidth: maxWidth ?? _defaultMaxWidth,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  static void showError(
      BuildContext context,
      String message, {
        double? maxWidth,
        Duration duration = const Duration(seconds: 4), // 错误信息通常显示长一点
        String? actionLabel,
        VoidCallback? onActionPressed,
      }) {
    _showOverlaySnackBar(
      context,
      message,
      Colors.red.shade600,
      Icons.error_outline,
      maxWidth: maxWidth ?? _defaultMaxWidth,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  static void showWarning(
      BuildContext context,
      String message, {
        double? maxWidth,
        Duration duration = const Duration(seconds: 3),
        String? actionLabel,
        VoidCallback? onActionPressed,
      }) {
    _showOverlaySnackBar(
      context,
      message,
      Colors.orange.shade700,
      Icons.warning_amber_rounded,
      maxWidth: maxWidth ?? _defaultMaxWidth,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  static void showInfo(
      BuildContext context,
      String message, {
        double? maxWidth,
        Duration duration = const Duration(seconds: 3),
        String? actionLabel,
        VoidCallback? onActionPressed,
      }) {
    _showOverlaySnackBar(
      context,
      message,
      Colors.blue.shade600,
      Icons.info_outline,
      maxWidth: maxWidth ?? _defaultMaxWidth,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  static void hideCurrentSnackBar() {
    _removeTimer?.cancel();
    if (_currentOverlayEntry != null) {
      try {
        _currentOverlayEntry!.remove();
      } catch (e) {
        print("Error removing OverlayEntry manually: $e");
      } finally {
        _currentOverlayEntry = null;
      }
    }
  }
  static void showLoginRequiredSnackBar(BuildContext context) {
    // 你可以选择使用 showError 或 showWarning 作为基础样式
    // 这里使用 showWarning 感觉更合适一点（警告用户需要先完成某个操作）
    showWarning( // 或者用 showError(...)
      context,
      '请先登录', // 固定消息文本
      actionLabel: '去登录', // 固定按钮文本
      onActionPressed: () { // 固定按钮操作
        // 调用你封装好的导航函数
        NavigationUtils.navigateToLogin(context);
        // 点击后 SnackBar 会自动开始消失动画，无需手动隐藏
      },
      // 可以考虑给需要用户操作的提示稍微长一点的显示时间
      duration: const Duration(seconds: 5),
    );
  }
}
