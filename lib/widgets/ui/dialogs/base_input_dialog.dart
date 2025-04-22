// lib/widgets/ui/dialogs/base_input_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';

// --- 通用动画显示函数 (可以放在单独的工具类里) ---
Future<T?> showAppAnimatedDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) pageBuilder, // 构建对话框内容的函数
  bool barrierDismissible = true,
  String? barrierLabel,
  Color barrierColor = Colors.black54,
  Duration transitionDuration = const Duration(milliseconds: 350),
  Curve transitionCurve = Curves.easeOutBack, // 动画曲线
  double maxWidth = 300, // 对话框最大宽度
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ??
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      // 直接返回 pageBuilder 构建的 Widget
      return pageBuilder(buildContext);
    },
    transitionBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      // 动画效果 (缩放 + 淡入)
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: transitionCurve,
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeIn,
          ),
          // 使用 Center 和 ConstrainedBox 约束对话框大小和位置
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child, // child 就是 pageBuilder 返回的 Widget
            ),
          ),
        ),
      );
    },
  );
}

// --- 底层通用输入/确认对话框 ---
class BaseInputDialog<T> extends StatefulWidget {
  // ... 属性保持不变 ...
  final String title;
  final Widget Function(BuildContext context) contentBuilder;
  final String cancelButtonText;
  final String confirmButtonText;
  final Color confirmButtonColor;
  final Future<T?> Function() onConfirm;
  final VoidCallback? onCancel;
  final IconData? iconData;
  final Color? iconColor;
  // 新增：允许外部控制是否可以通过点击遮罩层或返回按钮关闭（当非处理中时）
  final bool dismissibleWhenNotProcessing;

  const BaseInputDialog({
    super.key,
    required this.title,
    required this.contentBuilder,
    required this.onConfirm,
    this.cancelButtonText = '取消',
    this.confirmButtonText = '确认',
    Color? confirmButtonColor,
    this.onCancel,
    this.iconData,
    this.iconColor,
    this.dismissibleWhenNotProcessing = true, // 默认为 true
  }) : confirmButtonColor = confirmButtonColor ?? Colors.blue;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext context) contentBuilder,
    required Future<T?> Function() onConfirm,
    String cancelButtonText = '取消',
    String confirmButtonText = '确认',
    Color? confirmButtonColor,
    VoidCallback? onCancel,
    IconData? iconData,
    Color? iconColor,
    double maxWidth = 300,
    // 这个 barrierDismissible 控制 showGeneralDialog 的行为
    bool barrierDismissible = true,
    // 这个控制 BaseInputDialog 内部的 PopScope 行为
    bool allowDismissWhenNotProcessing = true,
  }) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;
    final effectiveConfirmButtonColor =
        confirmButtonColor ?? theme.primaryColor;

    final completer = Completer<T?>();

    showAppAnimatedDialog<void>(
      context: context,
      maxWidth: maxWidth,
      // barrierDismissible 控制点击外部是否 *尝试* 关闭
      // showGeneralDialog 会调用 Navigator.pop，然后我们的 PopScope 会拦截
      barrierDismissible: barrierDismissible,
      pageBuilder: (BuildContext buildContext) {
        return BaseInputDialog<T>(
          title: title,
          contentBuilder: contentBuilder,
          onConfirm: () async {
            // --- onConfirm 逻辑稍微调整 ---
            // 不再需要 BaseInputDialog 自己处理 completer
            // BaseInputDialog 的责任是调用 onConfirm 并根据结果 pop
            // show 方法负责处理 completer
            try {
              T? result = await onConfirm();
              // 如果 onConfirm 返回非 null，BaseInputDialog 内部会 pop
              // 如果返回 null，BaseInputDialog 不会 pop
              return result; // 将结果返回给 BaseInputDialog
            } catch (e) {
              // 如果 onConfirm 抛出异常，BaseInputDialog 内部会 pop
              rethrow; // 继续抛出，让 BaseInputDialog 处理
            }
          },
          cancelButtonText: cancelButtonText,
          confirmButtonText: confirmButtonText,
          confirmButtonColor: effectiveConfirmButtonColor,
          onCancel: () {
            onCancel?.call();
            // 如果取消回调触发 (来自取消按钮)，我们认为应该返回 null
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
          iconData: iconData,
          iconColor: effectiveIconColor,
          dismissibleWhenNotProcessing: allowDismissWhenNotProcessing, // 传递控制参数
        );
      },
    ).then((_) {
      // 当 showGeneralDialog 的 Future 完成时（通常是 Navigator.pop 被调用后）
      // 检查 completer 是否已经由 onConfirm(返回非null) 或 onCancel 完成
      if (!completer.isCompleted) {
        // 如果没有，说明是其他方式关闭（如 barrierDismissible 触发 pop, 或 PopScope 允许 pop）
        // 这种情况下视为取消
        completer.complete(null);
      }
    });

    return completer.future;
  }

  @override
  State<BaseInputDialog<T>> createState() => _BaseInputDialogState<T>();
}

class _BaseInputDialogState<T> extends State<BaseInputDialog<T>> {
  bool _isProcessing = false;

  Future<void> _handleConfirm() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    T? result;
    bool shouldPop = false;
    Object? error; // 存储异常
    StackTrace? stackTrace; // 存储堆栈

    try {
      result = await widget.onConfirm();
      if (result != null) {
        shouldPop = true;
      }
    } catch (e, s) {
      error = e;
      stackTrace = s;
      shouldPop = true; // 出错也尝试关闭
      print('BaseInputDialog: onConfirm error: $e');
    } finally {
      // 状态重置必须在 mounted 检查后
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        // 只有在 mounted 状态下才能 pop
        if (shouldPop && Navigator.canPop(context)) {
          // 如果有错误，pop 时不带结果，让 Future 抛出错误
          // 如果没错误，pop 时带上结果 result (可能为 null，但 shouldPop 为 true 是因为 onConfirm 返回了非 null 值)
          Navigator.pop(context, result);
        }
      }
      // 如果有错误，并且 completer 尚未完成，需要在这里重新抛出
      // 但是 completer 的处理移到了 show 方法中，这里不需要再处理
      if (error != null && mounted == false) {
        // 如果组件卸载了但仍有错误，至少打印出来
        print("BaseInputDialog Error after unmount: $error\n$stackTrace");
      } else if (error != null) {
        // 如果组件还在，将错误继续抛给 showGeneralDialog 的 Future
        // 这会导致 showAppAnimatedDialog(...).then(...) 中的 completer 被拒绝
        // 但这种方式比较隐晦，更好的方式是在 onConfirm 内部处理 completer.completeError
        // 考虑到 onConfirm 是外部传入的，我们假设外部的 onConfirm 已经处理了 completer
        // 所以这里只打印日志
      }
    }
  }

  void _handleCancel() {
    if (_isProcessing) return;
    // 调用 onCancel 回调 *之前* pop
    widget.onCancel?.call();
    // pop 对话框，不带结果
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    // 外部等待的 Future 会 resolve 为 null (由 show 方法的 .then 处理)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- 使用 PopScope 替换 WillPopScope ---
    return PopScope(
      // canPop 决定是否允许通过系统返回手势或按钮关闭
      // 规则：如果正在处理中，不允许关闭；否则，根据外部传入的 dismissibleWhenNotProcessing 决定
      canPop: !_isProcessing && widget.dismissibleWhenNotProcessing,
      onPopInvoked: (didPop) {
        // 当 pop 被尝试时调用 (无论成功与否)
        if (!didPop && !_isProcessing && !widget.dismissibleWhenNotProcessing) {
          // 如果 pop 被阻止了 (因为 dismissibleWhenNotProcessing 为 false)
          // 可以在这里给个提示，比如 SnackBar
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("操作未完成，无法返回")));
          print("Pop prevented because dismissibleWhenNotProcessing is false.");
        } else if (!didPop && _isProcessing) {
          // 如果 pop 被阻止了 (因为正在处理)
          print("Pop prevented because dialog is processing.");
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("正在处理中，请稍候..."),
            duration: Duration(seconds: 1),
          ));
        }
        // 如果 didPop 为 true，说明 pop 成功了，外部的 Future 会被处理
      },
      child: Material(
        // Material Widget 保持不变
        type: MaterialType.card,
        color: Colors.white,
        elevation: 6.0,
        shadowColor: Colors.black38,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- 图标 ---
              if (widget.iconData != null) ...[
                Icon(
                  widget.iconData!,
                  color: widget.iconColor ?? theme.primaryColor,
                  size: 40,
                ),
                const SizedBox(height: 16),
              ],
              // --- 标题 ---
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // --- 动态内容区域 ---
              // 为了让内容区域能滚动，同时限制其最大高度，进行调整
              Flexible(
                // 使用 Flexible 让内容区能在 Column 中伸缩
                child: SingleChildScrollView(
                  // 内容区可滚动
                  child: widget.contentBuilder(context),
                ),
              ),
              const SizedBox(height: 24),
              // --- 按钮行 ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // --- 取消按钮 ---
                  FunctionalTextButton(
                    onPressed: _isProcessing ? null : _handleCancel,
                    label: widget.cancelButtonText,
                  ),
                  const SizedBox(width: 8),
                  // --- 确认按钮 (使用 FunctionalButton) ---
                  FunctionalButton(
                    label: widget.confirmButtonText,
                    onPressed: _handleConfirm, // 直接使用内部处理函数
                    isLoading: _isProcessing, // 传递加载状态
                    isEnabled: !_isProcessing, // 传递启用状态
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 11), // 微调 padding 使其与 TextButton 视觉上更协调
                    // 可以根据需要调整颜色，但 FunctionalButton 通常有自己的主题色
                    // 如果需要强制使用 BaseInputDialog 的颜色，需要修改 FunctionalButton 或在这里用 ElevatedButton
                    // 这里假设 FunctionalButton 的默认样式可接受
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
