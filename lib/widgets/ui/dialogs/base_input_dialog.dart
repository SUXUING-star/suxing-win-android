// lib/widgets/ui/dialogs/base_input_dialog.dart

/// 该文件定义了 BaseInputDialog 组件，一个通用的输入/确认对话框。
/// 该对话框支持自定义内容、确认/取消操作，并可选支持拖拽和缩放。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/animation/animated_dialog.dart'; // 导入动画对话框工具
import 'dart:async'; // 异步操作所需
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart'; // 导入功能文本按钮
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件

/// `BaseInputDialog` 类：通用的输入/确认对话框组件。
///
/// 该组件提供可定制的标题、内容、操作按钮，并支持拖拽和缩放。
class BaseInputDialog<T> extends StatefulWidget {
  final String title; // 对话框标题
  final Widget Function(BuildContext context) contentBuilder; // 内容构建器
  final String cancelButtonText; // 取消按钮文本
  final String confirmButtonText; // 确认按钮文本
  final Color confirmButtonColor; // 确认按钮背景色
  final Color confirmButtonTextColor; // 确认按钮文本颜色
  final Future<T?> Function() onConfirm; // 确认操作回调
  final VoidCallback? onCancel; // 取消操作回调
  final IconData? iconData; // 对话框图标
  final Color? iconColor; // 对话框图标颜色
  final bool dismissibleWhenNotProcessing; // 非处理中状态下是否可点击外部关闭
  final bool showCancelButton; // 是否显示取消按钮
  final bool isDraggable; // 是否允许拖拽
  final bool isScalable; // 是否允许缩放
  final double minScale; // 最小缩放比例
  final double maxScale; // 最大缩放比例

  /// 构造函数。
  ///
  /// [title]：标题。
  /// [contentBuilder]：内容构建器。
  /// [onConfirm]：确认回调。
  /// [cancelButtonText]：取消按钮文本。
  /// [confirmButtonText]：确认按钮文本。
  /// [confirmButtonColor]：确认按钮颜色。
  /// [confirmButtonTextColor]：确认按钮文本颜色。
  /// [onCancel]：取消回调。
  /// [iconData]：图标。
  /// [iconColor]：图标颜色。
  /// [dismissibleWhenNotProcessing]：非处理中时是否可关闭。
  /// [showCancelButton]：是否显示取消按钮。
  /// [isDraggable]：是否可拖拽。
  /// [isScalable]：是否可缩放。
  /// [minScale]：最小缩放比例。
  /// [maxScale]：最大缩放比例。
  const BaseInputDialog({
    super.key,
    required this.title,
    required this.contentBuilder,
    required this.onConfirm,
    this.cancelButtonText = '取消',
    this.confirmButtonText = '确认',
    Color? confirmButtonColor,
    this.confirmButtonTextColor = Colors.white,
    this.onCancel,
    this.iconData,
    this.iconColor,
    this.dismissibleWhenNotProcessing = true,
    this.showCancelButton = true,
    this.isDraggable = false,
    this.isScalable = false,
    this.minScale = 0.7,
    this.maxScale = 2.0,
  }) : confirmButtonColor = confirmButtonColor ?? Colors.blue;

  /// 显示 BaseInputDialog。
  ///
  /// [context]：Build 上下文。
  /// [title]：对话框标题。
  /// [contentBuilder]：内容构建器。
  /// [onConfirm]：确认操作回调。
  /// [cancelButtonText]：取消按钮文本。
  /// [confirmButtonText]：确认按钮文本。
  /// [confirmButtonColor]：确认按钮颜色。
  /// [onCancel]：取消回调。
  /// [iconData]：图标。
  /// [iconColor]：图标颜色。
  /// [maxWidth]：对话框最大宽度。
  /// [barrierDismissible]：是否可点击外部关闭。
  /// [allowDismissWhenNotProcessing]：非处理中时是否可关闭。
  /// [showCancelButton]：是否显示取消按钮。
  /// [isDraggable]：是否可拖拽。
  /// [isScalable]：是否可缩放。
  /// [minScale]：最小缩放比例。
  /// [maxScale]：最大缩放比例。
  /// 返回一个 Future，表示对话框关闭时的结果。
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
    bool barrierDismissible = true,
    bool allowDismissWhenNotProcessing = true,
    bool showCancelButton = true,
    bool isDraggable = false,
    bool isScalable = false,
    double minScale = 0.7,
    double maxScale = 2.0,
  }) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor; // 有效图标颜色
    final effectiveConfirmButtonColor =
        confirmButtonColor ?? theme.primaryColor; // 有效确认按钮颜色
    final completer = Completer<T?>(); // 对话框结果 Completer

    AnimatedDialog.showAppAnimatedDialog<T>(
      context: context,
      maxWidth: maxWidth,
      barrierDismissible: barrierDismissible,
      pageBuilder: (BuildContext buildContext) {
        return BaseInputDialog<T>(
          title: title,
          contentBuilder: contentBuilder,
          onConfirm: () async {
            try {
              T? result = await onConfirm(); // 执行确认回调
              return result;
            } catch (e) {
              rethrow;
            }
          },
          cancelButtonText: cancelButtonText,
          confirmButtonText: confirmButtonText,
          confirmButtonColor: effectiveConfirmButtonColor,
          onCancel: () {
            onCancel?.call(); // 执行取消回调
            if (!completer.isCompleted) {
              completer.complete(null); // 完成 Completer
            }
          },
          iconData: iconData,
          iconColor: effectiveIconColor,
          dismissibleWhenNotProcessing: allowDismissWhenNotProcessing,
          showCancelButton: showCancelButton,
          isDraggable: isDraggable,
          isScalable: isScalable,
          minScale: minScale,
          maxScale: maxScale,
        );
      },
    ).then((result) {
      if (!completer.isCompleted) {
        completer.complete(result); // 完成 Completer
      }
    }).catchError((error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace); // 错误完成 Completer
      }
    });

    return completer.future; // 返回 Completer 的 Future
  }

  @override
  State<BaseInputDialog<T>> createState() => _BaseInputDialogState<T>();
}

/// `_BaseInputDialogState` 类：`BaseInputDialog` 的状态管理。
///
/// 管理对话框的处理状态、拖拽和缩放变换。
class _BaseInputDialogState<T> extends State<BaseInputDialog<T>> {
  bool _isProcessing = false; // 是否正在处理中标记
  Offset _offset = Offset.zero; // 对话框偏移量
  double _scale = 1.0; // 对话框缩放比例
  double _baseScale = 1.0; // 基础缩放比例
  final GlobalKey _dialogKey = GlobalKey(); // 对话框的全局键

  /// 处理确认操作。
  ///
  /// 执行确认回调，并根据结果关闭对话框。
  Future<void> _handleConfirm() async {
    if (_isProcessing) return; // 正在处理中时返回
    setState(() {
      _isProcessing = true; // 设置处理状态
    });

    T? result; // 结果
    bool shouldPop = false; // 是否应该关闭对话框
    Object? error; // 错误对象

    try {
      result = await widget.onConfirm(); // 执行确认回调
      shouldPop = true; // 设置为应关闭对话框
    } catch (e) {
      error = e; // 捕获错误
      shouldPop = true; // 发生错误时也关闭对话框
    } finally {
      if (mounted) {
        // 检查组件是否挂载
        setState(() {
          _isProcessing = false; // 取消处理状态
        });
        if (shouldPop && Navigator.canPop(context)) {
          // 如果应关闭且可关闭
          Navigator.pop(context, error == null ? result : null); // 关闭对话框并传递结果
        }
      }
    }
  }

  /// 处理取消操作。
  ///
  /// 调用取消回调，并关闭对话框。
  void _handleCancel() {
    if (_isProcessing) return; // 正在处理中时返回
    widget.onCancel?.call(); // 调用取消回调
    if (mounted && Navigator.canPop(context)) {
      // 如果可关闭
      Navigator.pop(context); // 关闭对话框
    }
  }

  /// 处理缩放手势开始。
  ///
  /// [details]：缩放开始详情。
  void _onScaleStart(ScaleStartDetails details) {
    if (!widget.isDraggable && !widget.isScalable) return; // 不允许拖拽或缩放时返回

    setState(() {
      _baseScale = _scale; // 记录当前缩放比例
    });
  }

  /// 处理缩放手势更新。
  ///
  /// [details]：缩放更新详情。
  /// 根据手势信息更新对话框的缩放和偏移，并限制在屏幕边界内。
  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.isDraggable && !widget.isScalable) return; // 不允许拖拽或缩放时返回

    final screenSize = MediaQuery.of(context).size; // 屏幕尺寸
    if (screenSize.isEmpty) return; // 屏幕尺寸无效时返回

    final RenderBox? renderBox =
        _dialogKey.currentContext?.findRenderObject() as RenderBox?; // 获取对话框渲染盒
    final Size dialogOriginalSize =
        renderBox?.size ?? const Size(300, 200); // 对话框原始尺寸

    if (dialogOriginalSize == Size.zero) return; // 尺寸无效时返回

    double proposedScale = _scale; // 提议缩放比例
    if (widget.isScalable) {
      proposedScale = (_baseScale * details.scale)
          .clamp(widget.minScale, widget.maxScale); // 计算并钳制新比例
    }

    Offset proposedOffset = _offset; // 提议偏移量
    if (widget.isDraggable) {
      proposedOffset += details.focalPointDelta; // 累加焦点移动量
    }

    final double scaledWidth =
        dialogOriginalSize.width * proposedScale; // 缩放后的宽度
    final double scaledHeight =
        dialogOriginalSize.height * proposedScale; // 缩放后的高度

    final Offset initialCenter =
        Offset(screenSize.width / 2, screenSize.height / 2); // 屏幕中心

    final Offset desiredVisualCenter = initialCenter + proposedOffset; // 提议视觉中心

    final double minX = desiredVisualCenter.dx - scaledWidth / 2; // 最小 X 坐标
    final double maxX = desiredVisualCenter.dx + scaledWidth / 2; // 最大 X 坐标
    final double minY = desiredVisualCenter.dy - scaledHeight / 2; // 最小 Y 坐标
    final double maxY = desiredVisualCenter.dy + scaledHeight / 2; // 最大 Y 坐标

    double correctedOffsetX = proposedOffset.dx; // 修正后的 X 偏移
    if (minX < 0) {
      correctedOffsetX += (0 - minX);
    } else if (maxX > screenSize.width) {
      correctedOffsetX += (screenSize.width - maxX);
    }

    double correctedOffsetY = proposedOffset.dy; // 修正后的 Y 偏移
    if (minY < 0) {
      correctedOffsetY += (0 - minY);
    } else if (maxY > screenSize.height) {
      correctedOffsetY += (screenSize.height - maxY);
    }

    setState(() {
      _scale = proposedScale; // 更新缩放比例
      _offset = Offset(correctedOffsetX, correctedOffsetY); // 更新偏移量
    });
  }

  /// 处理缩放手势结束。
  ///
  /// [details]：缩放结束详情。
  void _onScaleEnd(ScaleEndDetails details) {}

  /// 构建对话框界面。
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 当前主题

    Widget dialogContentCore = Material(
      key: _dialogKey, // 全局键
      type: MaterialType.card, // 材料类型
      color: Colors.white, // 背景色
      elevation: 6.0, // 阴影高度
      shadowColor: Colors.black38, // 阴影颜色
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0)), // 形状
      clipBehavior: Clip.antiAlias, // 裁剪行为
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0), // 内边距
        child: Column(
          mainAxisSize: MainAxisSize.min, // 高度自适应内容
          crossAxisAlignment: CrossAxisAlignment.stretch, // 子项宽度撑满
          children: [
            if (widget.iconData != null) ...[
              // 显示图标
              Icon(
                widget.iconData!,
                color: widget.iconColor ?? theme.primaryColor,
                size: 40,
              ),
              const SizedBox(height: 16),
            ],
            AppText(
              widget.title, // 标题
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(), // 滚动物理
                  child: DefaultTextStyle(
                    style: theme.textTheme.bodyMedium ?? const TextStyle(),
                    textAlign: TextAlign.center,
                    child: widget.contentBuilder(context), // 内容
                  )),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: widget.showCancelButton
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.center,
              children: [
                if (widget.showCancelButton) ...[
                  // 显示取消按钮
                  FunctionalTextButton(
                    onPressed: _isProcessing ? null : _handleCancel,
                    label: widget.cancelButtonText,
                    minWidth: 64,
                  ),
                  const SizedBox(width: 8),
                ],
                FunctionalTextButton(
                  label: widget.confirmButtonText, // 确认按钮
                  onPressed: _handleConfirm,
                  isLoading: _isProcessing,
                  isEnabled: !_isProcessing,
                  minWidth: widget.showCancelButton ? 88 : 120,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    Widget dialogContentTransformed = dialogContentCore; // 变换后的对话框内容
    if (widget.isDraggable || widget.isScalable) {
      // 如果允许拖拽或缩放
      dialogContentTransformed = GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: Transform.translate(
          offset: _offset, // 应用位移
          child: Transform.scale(
            scale: _scale, // 应用缩放
            alignment: Alignment.center, // 缩放中心
            child: dialogContentCore, // 核心内容
          ),
        ),
      );
    }

    return PopScope<T>(
      canPop: !_isProcessing && widget.dismissibleWhenNotProcessing, // 是否可弹回
      onPopInvokedWithResult: (bool didPop, T? result) {
        if (!didPop) {
          if (_isProcessing) {
            final messenger = ScaffoldMessenger.maybeOf(context);
            if (messenger != null && mounted) {
              messenger.showSnackBar(const SnackBar(
                content: Text("正在处理中，请稍候。"),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ));
            }
          }
        } else {
          if (!_isProcessing) {
            widget.onCancel?.call(); // 调用取消回调
          }
        }
      },
      child: dialogContentTransformed, // 变换后的对话框内容
    );
  }
}
