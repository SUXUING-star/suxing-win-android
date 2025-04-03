import 'package:flutter/material.dart';
import 'dart:async'; // 确保导入 Future 和 VoidCallback

/// 自定义确认对话框 Widget
///
/// 显示一个带有图标、标题、消息以及取消和确认按钮的对话框。
/// 确认操作可以是异步的，并在执行时显示加载指示器。
class CustomConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String cancelButtonText;
  final String confirmButtonText;
  final Color confirmButtonColor;
  final Future<void> Function() onConfirm; // 确认回调，返回 Future
  final VoidCallback? onCancel; // 取消回调
  final IconData iconData; // 图标
  final Color iconColor; // 图标颜色

  const CustomConfirmDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.cancelButtonText = '取消',
    this.confirmButtonText = '确认',
    this.confirmButtonColor = Colors.red, // 默认为红色（适用于删除等危险操作）
    this.onCancel,
    this.iconData = Icons.warning_amber_rounded, // 默认警告图标
    this.iconColor = Colors.orange, // 默认图标颜色
  }) : super(key: key);

  /// 显示自定义确认对话框的静态方法
  ///
  /// 使用 `showGeneralDialog` 实现自定义的过渡动画和外观。
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
    String cancelButtonText = '取消',
    String confirmButtonText = '确认',
    Color confirmButtonColor = Colors.blue, // 默认确认按钮颜色改为蓝色
    VoidCallback? onCancel,
    IconData iconData = Icons.info_outline, // 默认改为信息图标
    Color iconColor = Colors.blue,       // 默认改为蓝色
    bool barrierDismissible = false,      // 控制点击外部是否关闭对话框
    Duration transitionDuration = const Duration(milliseconds: 350), // 动画时长
    Curve transitionCurve = Curves.easeOutBack, // 动画曲线
  }) {
    return showGeneralDialog<void>( // 使用 showGeneralDialog
      context: context,
      barrierDismissible: barrierDismissible, // 使用传入的参数
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54, // 半透明遮罩层
      transitionDuration: transitionDuration, // 过渡动画时间

      pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        // 返回对话框 Widget 实例
        return CustomConfirmDialog(
          title: title,
          message: message,
          onConfirm: onConfirm,
          cancelButtonText: cancelButtonText,
          confirmButtonText: confirmButtonText,
          confirmButtonColor: confirmButtonColor,
          onCancel: onCancel,
          iconData: iconData,
          iconColor: iconColor,
        );
      },

      transitionBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        // 构建动画效果 (缩放 + 淡入)
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: transitionCurve, // 使用传入的曲线
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn, // 淡入效果
            ),
            child: child, // child 就是 pageBuilder 返回的 CustomConfirmDialog 实例
          ),
        );
      },
    );
  }

  @override
  State<CustomConfirmDialog> createState() => _CustomConfirmDialogState();
}

class _CustomConfirmDialogState extends State<CustomConfirmDialog> {
  bool _isProcessing = false; // 标记确认操作是否正在进行

  /// 处理确认按钮点击事件
  Future<void> _handleConfirm() async {
    if (_isProcessing) return; // 防止重复点击
    setState(() { _isProcessing = true; }); // 显示加载状态

    try {
      // 注意：这里不再自动 pop，将关闭对话框的责任交给 onConfirm 回调
      // 调用者可以在 onConfirm 成功执行后或者需要时手动 pop
      await widget.onConfirm(); // 执行传入的异步确认操作

      // 如果 onConfirm 异步操作完成后，此 Widget 仍然挂载（即对话框未被关闭）
      // 并且需要在这里关闭，可以取消下一行的注释。
      // 但通常建议在 onConfirm 回调内部处理导航/关闭逻辑。
      if (mounted) Navigator.pop(context);

    } catch (e) {
      // 如果确认操作抛出异常
      print('CustomConfirmDialog: onConfirm error: $e'); // 打印错误日志
      // 确保在出错时关闭对话框（如果尚未关闭）
      if (mounted) {
        Navigator.pop(context); // 关闭对话框
        // 可以在这里添加一个错误提示，例如使用 Toaster
        // Toaster.error(context, '操作失败: $e');
      }
      rethrow; // 将异常继续抛出，以便调用者也能捕获和处理
    } finally {
      // 无论成功与否，如果 Widget 仍然挂载，则尝试重置处理状态
      // （如果对话框已关闭，setState 会安全地不执行任何操作）
      if (mounted && _isProcessing) {
        setState(() { _isProcessing = false; });
      }
    }
  }

  /// 处理取消按钮点击事件
  void _handleCancel() {
    if (_isProcessing) return; // 如果正在处理确认，不允许取消
    Navigator.pop(context); // 关闭对话框
    widget.onCancel?.call(); // 执行传入的取消回调（如果提供了）
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 使用 Center 将对话框居中显示
    return Center(
      // 使用 ConstrainedBox 限制对话框的最大和最小宽度
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300, // 最大宽度
          minWidth: 280, // 最小宽度
        ),
        // 使用 Material 提供背景、阴影、圆角等基础视觉元素
        child: Material(
          color: Colors.white, // 对话框背景色
          elevation: 6.0,      // 阴影大小
          shadowColor: Colors.black26, // 阴影颜色
          // 设置对话框的形状（圆角矩形）
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // 圆角半径
          ),
          clipBehavior: Clip.antiAlias, // 裁剪超出圆角部分的内容
          // 使用 Padding 设置对话框内部内容的边距
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 20.0), // 上边距稍大
            // 使用 Column 垂直排列对话框内容
            child: Column(
              mainAxisSize: MainAxisSize.min, // 高度自适应内容
              children: [
                // --- 图标 ---
                Icon(
                  widget.iconData,    // 使用传入的图标数据
                  color: widget.iconColor, // 使用传入的图标颜色
                  size: 48,             // 图标大小
                ),
                const SizedBox(height: 16), // 图标和标题之间的间距

                // --- 标题 ---
                Text(
                  widget.title,
                  textAlign: TextAlign.center, // 文本居中对齐
                  style: theme.textTheme.titleLarge?.copyWith( // 使用较大的标题样式
                    fontWeight: FontWeight.bold, // 粗体
                    color: Colors.black87,       // 深灰色文字
                  ),
                ),
                const SizedBox(height: 10), // 标题和消息之间的间距

                // --- 消息内容 ---
                Text(
                  widget.message,
                  textAlign: TextAlign.center, // 文本居中对齐
                  style: theme.textTheme.bodyMedium?.copyWith( // 使用标准正文样式
                    height: 1.5, // 设置行高，提高可读性
                    color: Colors.black54, // 稍浅的灰色文字
                  ),
                ),
                const SizedBox(height: 24), // 消息内容和按钮区域之间的间距

                // --- 动作按钮区域 ---
                Row(
                  // MainAxisAlignment.spaceEvenly 会让按钮均匀分布在行内
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // --- 取消按钮 (使用 Expanded 确保按钮宽度一致性) ---
                    Expanded(
                      child: OutlinedButton(
                        // 如果正在处理确认，禁用取消按钮
                        onPressed: _isProcessing ? null : _handleCancel,
                        style: OutlinedButton.styleFrom(
                          // 设置按钮文字颜色（前景色）
                          foregroundColor: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                          // 设置边框颜色
                          side: BorderSide(color: theme.dividerColor),
                          // 设置按钮形状为圆角矩形
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          // 设置按钮内边距
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(widget.cancelButtonText), // 显示取消按钮文本
                      ),
                    ),
                    const SizedBox(width: 16), // 两个按钮之间的间距

                    // --- 确认按钮 或 加载指示器 (使用 Expanded 确保宽度一致性) ---
                    Expanded(
                      // 根据 _isProcessing 状态决定显示按钮还是加载指示器
                      child: _isProcessing
                          ? Container( // 使用 Container 包裹加载指示器以控制大小和对齐
                        height: 48, // 高度与按钮保持一致，防止布局跳动
                        alignment: Alignment.center, // 指示器居中
                        child: const SizedBox(
                          width: 24,  // 指示器宽度
                          height: 24, // 指示器高度
                          // 圆形加载指示器
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                          : ElevatedButton( // 普通状态下显示确认按钮
                        onPressed: _handleConfirm, // 点击时执行确认处理函数
                        style: ElevatedButton.styleFrom(
                          // 设置按钮背景颜色
                          backgroundColor: widget.confirmButtonColor,
                          // 设置按钮文字颜色（前景色）
                          foregroundColor: Colors.white,
                          // 设置按钮形状为圆角矩形
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          // 设置按钮内边距
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 2, // 按钮轻微阴影
                          // 设置按钮阴影颜色
                          shadowColor: widget.confirmButtonColor.withOpacity(0.4),
                          // 确保按钮有最小高度
                          minimumSize: const Size(0, 48),
                        ),
                        child: Text(widget.confirmButtonText), // 显示确认按钮文本
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