// lib/widgets/ui/dialogs/base_input_dialog.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_dialog.dart';
import 'dart:async';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

// --- 底层通用输入/确认对话框 (支持拖拽和缩放，带边界限制) ---
class BaseInputDialog<T> extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext context) contentBuilder;
  final String cancelButtonText;
  final String confirmButtonText;
  final Color confirmButtonColor;
  final Color confirmButtonTextColor;
  final Future<T?> Function() onConfirm; // 返回 T?
  final VoidCallback? onCancel;
  final IconData? iconData;
  final Color? iconColor;
  final bool dismissibleWhenNotProcessing;
  final bool showCancelButton;
  final bool isDraggable; // 是否允许拖拽
  final bool isScalable; // 是否允许缩放
  final double minScale; // 最小缩放比例
  final double maxScale; // 最大缩放比例

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
    // --- 初始化交互参数 ---
    this.isDraggable = false, // 默认不允许拖拽
    this.isScalable = false, // 默认不允许缩放
    this.minScale = 0.7, // 默认最小缩放 70%
    this.maxScale = 2.0, // 默认最大缩放 200%
  }) : confirmButtonColor = confirmButtonColor ?? Colors.blue; // 确保有默认值

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext context) contentBuilder,
    required Future<T?> Function() onConfirm, // 返回 T?
    String cancelButtonText = '取消',
    String confirmButtonText = '确认',
    Color? confirmButtonColor,
    VoidCallback? onCancel,
    IconData? iconData,
    Color? iconColor,
    double maxWidth = 300, // 仍然用于初始约束
    bool barrierDismissible = true,
    bool allowDismissWhenNotProcessing = true,
    bool showCancelButton = true,
    // --- 传递交互参数 ---
    bool isDraggable = false,
    bool isScalable = false,
    double minScale = 0.7,
    double maxScale = 2.0,
  }) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;
    final effectiveConfirmButtonColor =
        confirmButtonColor ?? theme.primaryColor;
    final completer = Completer<T?>(); // Completer 的类型是 T?

    // 使用导入的 animatedDialog (假设它包含 showAppAnimatedDialog)
    AnimatedDialog.showAppAnimatedDialog<T>(
      context: context,
      maxWidth: maxWidth,
      barrierDismissible: barrierDismissible,
      pageBuilder: (BuildContext buildContext) {
        // --- 创建 BaseInputDialog 实例，传入所有参数 ---
        return BaseInputDialog<T>(
          title: title,
          contentBuilder: contentBuilder,
          onConfirm: () async {
            // onConfirm 包装逻辑
            try {
              T? result = await onConfirm();
              return result;
            } catch (e) {
              rethrow;
            }
          },
          cancelButtonText: cancelButtonText,
          confirmButtonText: confirmButtonText,
          confirmButtonColor: effectiveConfirmButtonColor,
          onCancel: () {
            // onCancel 包装逻辑
            onCancel?.call();
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
          iconData: iconData,
          iconColor: effectiveIconColor,
          dismissibleWhenNotProcessing: allowDismissWhenNotProcessing,
          showCancelButton: showCancelButton,
          // --- 传递交互参数 ---
          isDraggable: isDraggable,
          isScalable: isScalable,
          minScale: minScale,
          maxScale: maxScale,
        );
      },
    ).then((result) {
      // showGeneralDialog 返回的是 T?
      // 当对话框关闭时 (Navigator.pop(context, result) 被调用)
      if (!completer.isCompleted) {
        // 如果 completer 还没完成（比如通过 barrierDismissible 关闭），
        // 则使用 showGeneralDialog 返回的结果（通常是 null）来完成 completer
        completer.complete(result);
      }
    }).catchError((error, stackTrace) {
      // 处理 showGeneralDialog 可能抛出的错误
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  @override
  State<BaseInputDialog<T>> createState() => _BaseInputDialogState<T>();
}

class _BaseInputDialogState<T> extends State<BaseInputDialog<T>> {
  bool _isProcessing = false;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _baseScale = 1.0;
  // --- 添加 GlobalKey 来获取对话框尺寸 ---
  final GlobalKey _dialogKey = GlobalKey();

  // --- 确认按钮处理逻辑 ---
  Future<void> _handleConfirm() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    T? result;
    bool shouldPop = false;
    Object? error;
    // StackTrace? stackTrace;

    try {
      result = await widget.onConfirm();
      shouldPop = true; // 确认操作完成就应该关闭，无论结果是否为 null
    } catch (e) {
      error = e;
      shouldPop = true; // 出错也尝试关闭
      // 可以在这里添加更详细的错误处理或日志记录
      // print('BaseInputDialog: onConfirm error: $e\n$stackTrace');
    } finally {
      // 确保组件仍然挂载
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        // 只有在需要 pop 且可以 pop 时才执行
        if (shouldPop && Navigator.canPop(context)) {
          // 如果有错误，pop 时不带结果，让 show 方法的 Future 抛出错误
          // 如果没错误，pop 时带上结果 result (可能为 null)
          Navigator.pop(context, error == null ? result : null);
        }
      }
    }
  }

  // --- 取消按钮处理逻辑 ---
  void _handleCancel() {
    if (_isProcessing) return;
    // 先调用外部传入的回调
    widget.onCancel?.call();
    // 再关闭对话框 (如果不处于处理中)
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // 取消不带结果，外部 Future 会 complete(null)
    }
  }

  // --- 手势开始处理 ---
  void _onScaleStart(ScaleStartDetails details) {
    if (!widget.isDraggable && !widget.isScalable) return; // 如果都不允许，直接返回

    // 记录当前的缩放比例作为下一次计算的基础
    setState(() {
      _baseScale = _scale;
    });
  }

  // --- 手势更新处理 (包含边界检查) ---
  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.isDraggable && !widget.isScalable) return; // 如果都不允许，直接返回

    // --- 1. 获取屏幕尺寸 ---
    // 使用 MediaQuery 获取当前 context 下的屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    if (screenSize.isEmpty) return; // 无效屏幕尺寸则不处理

    // --- 2. 获取对话框原始尺寸 ---
    // 尝试使用 GlobalKey 获取对话框渲染后的尺寸
    final RenderBox? renderBox =
        _dialogKey.currentContext?.findRenderObject() as RenderBox?;
    // 提供一个合理的 fallback 尺寸，以防 key 尚未准备好或获取失败
    // 这个 fallback 尺寸应该根据你的 maxWidth 和典型内容高度估算
    final Size dialogOriginalSize =
        renderBox?.size ?? const Size(300, 200); // TODO: 根据实际情况调整 fallback

    if (dialogOriginalSize == Size.zero) return; // 如果尺寸无效 (例如 0x0)，则跳过本次更新

    // --- 3. 计算提议的新缩放和偏移 ---
    double proposedScale = _scale;
    // 如果允许缩放，根据手势计算新比例，并限制在最小最大范围内
    if (widget.isScalable) {
      proposedScale =
          (_baseScale * details.scale).clamp(widget.minScale, widget.maxScale);
    }

    Offset proposedOffset = _offset;
    // 如果允许拖拽，累加手势的焦点移动量
    if (widget.isDraggable) {
      // details.focalPointDelta 是自上次更新以来的位移量
      proposedOffset += details.focalPointDelta;
    }

    // --- 4. 计算边界并修正偏移 ---
    // 计算缩放后的对话框视觉尺寸
    final double scaledWidth = dialogOriginalSize.width * proposedScale;
    final double scaledHeight = dialogOriginalSize.height * proposedScale;

    // 对话框的初始显示中心点近似为屏幕中心 (由 showAppAnimatedDialog 的 Center 决定)
    // 注意：更精确的初始中心可能需要考虑 ConstrainedBox 的影响，但屏幕中心作为基准通常足够
    final Offset initialCenter =
        Offset(screenSize.width / 2, screenSize.height / 2);

    // 计算应用提议偏移后的视觉中心点在屏幕上的坐标
    final Offset desiredVisualCenter = initialCenter + proposedOffset;

    // 计算提议的边界坐标 (左上角和右下角)
    final double minX = desiredVisualCenter.dx - scaledWidth / 2;
    final double maxX = desiredVisualCenter.dx + scaledWidth / 2;
    final double minY = desiredVisualCenter.dy - scaledHeight / 2;
    final double maxY = desiredVisualCenter.dy + scaledHeight / 2;

    // 修正 X 轴偏移量以防止移出屏幕
    double correctedOffsetX = proposedOffset.dx;
    if (minX < 0) {
      // 如果左边界超出了屏幕左边 (x=0)
      // 计算需要向右移动多少才能让左边界回到 0
      correctedOffsetX += (0 - minX);
    } else if (maxX > screenSize.width) {
      // 如果右边界超出了屏幕右边
      // 计算需要向左移动多少才能让右边界回到屏幕宽度
      correctedOffsetX += (screenSize.width - maxX);
    }

    // 修正 Y 轴偏移量以防止移出屏幕
    double correctedOffsetY = proposedOffset.dy;
    if (minY < 0) {
      // 如果上边界超出了屏幕顶边 (y=0)
      // 计算需要向下移动多少才能让上边界回到 0
      correctedOffsetY += (0 - minY);
    } else if (maxY > screenSize.height) {
      // 如果下边界超出了屏幕底边
      // 计算需要向上移动多少才能让下边界回到屏幕高度
      correctedOffsetY += (screenSize.height - maxY);
    }

    // --- 5. 应用最终的缩放和修正后的偏移 ---
    // 使用 setState 更新状态，触发界面重绘
    setState(() {
      _scale = proposedScale;
      _offset = Offset(correctedOffsetX, correctedOffsetY);
    });
  }

  // --- 手势结束处理 ---
  void _onScaleEnd(ScaleEndDetails details) {
    // 手势结束，目前不需要特殊处理
    // 可以考虑在这里添加一个动画，让对话框平滑地回到某个状态，或者重置 _baseScale
    // _baseScale = 1.0; // 如果希望每次开始缩放都是独立的，可以在这里重置
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- 构建核心对话框内容 (添加 key) ---
    // 这部分是对话框的 UI 结构，我们给它加上了 GlobalKey
    Widget dialogContentCore = Material(
      key: _dialogKey, // *** 将 GlobalKey 赋给 Material Widget ***
      type: MaterialType.card,
      color: Colors.white,
      elevation: 6.0,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias, // 抗锯齿裁剪
      child: Padding(
        // 对话框内边距
        padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 高度自适应内容
          crossAxisAlignment: CrossAxisAlignment.stretch, // 子项宽度撑满
          children: [
            // --- 图标 (如果提供了) ---
            if (widget.iconData != null) ...[
              Icon(
                widget.iconData!,
                color: widget.iconColor ?? theme.primaryColor, // 使用传入颜色或主题色
                size: 40, // 图标大小
              ),
              const SizedBox(height: 16), // 图标和标题间距
            ],
            // --- 标题 ---
            AppText(
              widget.title,
              textAlign: TextAlign.center, // 标题居中
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600, // 标题加粗
                color: Colors.black87, // 标题颜色
              ),
            ),
            const SizedBox(height: 16), // 标题和内容间距
            // --- 动态内容区域 ---
            Flexible(
              // 允许内容区域在 Column 中伸缩
              child: SingleChildScrollView(
                  // 内容可滚动
                  // 使用 ClampingScrollPhysics 尝试减少内部滚动与外部拖拽的冲突
                  physics: const ClampingScrollPhysics(),
                  child: DefaultTextStyle(
                    // 为内容提供默认文本样式
                    style: theme.textTheme.bodyMedium ??
                        const TextStyle(), // 使用 bodyMedium 样式
                    textAlign: TextAlign.center, // 内容默认居中
                    child: widget.contentBuilder(context), // 调用外部传入的内容构建函数
                  )),
            ),
            const SizedBox(height: 24), // 内容和按钮间距
            // --- 按钮行 ---
            Row(
              // 根据是否有取消按钮决定按钮对齐方式
              mainAxisAlignment: widget.showCancelButton
                  ? MainAxisAlignment.end // 有两个按钮时靠右
                  : MainAxisAlignment.center, // 只有一个按钮时居中
              children: [
                // --- 取消按钮 (如果需要显示) ---
                if (widget.showCancelButton) ...[
                  FunctionalTextButton(
                    onPressed: _isProcessing ? null : _handleCancel, // 处理中时禁用
                    label: widget.cancelButtonText, // 取消按钮文字
                    minWidth: 64, // 保证最小宽度
                    // 可以传入 foregroundColor 来自定义颜色
                  ),
                  const SizedBox(width: 8), // 按钮间距
                ],
                // --- 确认按钮 ---
                FunctionalButton(
                  label: widget.confirmButtonText, // 确认按钮文字
                  foregroundColor: widget.confirmButtonTextColor,
                  onPressed: _handleConfirm, // 确认按钮回调
                  isLoading: _isProcessing, // 显示加载状态
                  isEnabled: !_isProcessing, // 处理中时禁用
                  backgroundColor: widget.confirmButtonColor, // 使用确认按钮颜色
                  minWidth:
                      widget.showCancelButton ? 88 : 120, // 根据是否有取消按钮调整最小宽度
                  // 可以传入 foregroundColor 来自定义颜色
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // --- 包裹 GestureDetector 和 Transform ---
    // 默认情况下，直接使用核心内容
    Widget dialogContentTransformed = dialogContentCore;
    // 只有在允许拖拽或缩放时，才应用变换
    if (widget.isDraggable || widget.isScalable) {
      dialogContentTransformed = GestureDetector(
        // 绑定手势处理函数
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        // 使用 Transform.translate 和 Transform.scale 来应用计算出的偏移和缩放
        child: Transform.translate(
          offset: _offset, // 应用位移
          child: Transform.scale(
            scale: _scale, // 应用缩放
            alignment: Alignment.center, // 设置缩放中心为 Widget 中心
            child: dialogContentCore, // 将带 key 的核心内容作为变换目标
          ),
        ),
      );
    }

    // --- 最后包裹 PopScope 用于处理系统返回事件 ---
    return PopScope<T>(
      // *** 1. 明确指定泛型 <T> ***
      canPop: !_isProcessing && widget.dismissibleWhenNotProcessing,
      // *** 2. 使用 onPopInvokedWithResult 并更新回调签名 ***
      onPopInvokedWithResult: (bool didPop, T? result) {
        // *** 添加 result 参数 ***
        // *** 3. 内部逻辑保持不变，忽略 result 参数 ***
        if (!didPop) {
          // 如果 pop 被阻止了
          if (_isProcessing) {
            // 如果是因为正在处理中
            // 最好检查 context 是否仍然有效
            final messenger = ScaffoldMessenger.maybeOf(context);
            if (messenger != null && mounted) {
              messenger.showSnackBar(const SnackBar(
                content: Text("正在处理中，请稍候..."),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating, // 悬浮提示更好看
              ));
            } else {
              // print(
              //     "BaseInputDialog PopScope: Cannot show SnackBar, context or messenger invalid.");
            }
          } else if (!widget.dismissibleWhenNotProcessing) {
            // 如果是因为设置了不允许关闭
            // print(
            //     "Pop prevented because dismissibleWhenNotProcessing is false.");
          }
        } else {
          // 如果 pop 成功了 (通过非按钮方式，如 back 键或点击 barrier)
          // 检查是否因为取消操作触发的 pop (即非处理中状态下的 pop)
          if (!_isProcessing) {
            // 视为取消操作，调用 onCancel 回调
            widget.onCancel?.call();
            // completer 会被 show 方法的 .then 正确处理为 null
          }
        }
      },
      // 将可能被 Transform 包裹的 dialogContent 作为 PopScope 的子 Widget
      child: dialogContentTransformed,
    );
  }
}
