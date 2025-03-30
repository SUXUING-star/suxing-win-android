// widgets/ui/dialogs/edit_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async'; // Future 需要

// --- 通用的对话框显示函数 ---
// (可以放在这里，或者 utils/dialog_utils.dart 等更合适的地方)
Future<T?> showAppAnimatedDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) pageBuilder, // 构建对话框内容的函数
  bool barrierDismissible = true,
  String? barrierLabel,
  Color barrierColor = Colors.black54,
  Duration transitionDuration = const Duration(milliseconds: 350),
  Curve transitionCurve = Curves.easeOutBack, // 使用你喜欢的曲线
  double maxWidth = 300, // 默认最大宽度
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      // 直接调用传入的 pageBuilder 来构建内容
      return pageBuilder(buildContext);
    },
    transitionBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
      // 动画效果
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: transitionCurve, // 使用传入的曲线
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeIn,
          ),
          // 包裹 ConstrainedBox 和居中
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth), // 使用传入的 maxWidth
              child: child, // child 就是 pageBuilder 返回的 Widget (它应该自己带 Material)
            ),
          ),
        ),
      );
    },
  );
}

// --- 通用的单行文本编辑对话框 ---
class EditDialog extends StatefulWidget {
  final String title;
  final String initialText;
  final String hintText;
  final String cancelButtonText;
  final String saveButtonText;
  final int maxLines;
  final Future<void> Function(String text) onSave;
  final IconData iconData;
  final Color iconColor;

  const EditDialog({
    Key? key,
    required this.title,
    required this.initialText,
    required this.onSave,
    this.hintText = '编辑内容...',
    this.cancelButtonText = '取消',
    this.saveButtonText = '保存',
    this.maxLines = 3,
    this.iconData = Icons.edit_note,
    this.iconColor = Colors.blue,
  }) : super(key: key);

  /// 显示【单行】编辑对话框的静态方法 (调用 showAppAnimatedDialog)
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String initialText,
    required Future<void> Function(String) onSave,
    String hintText = '编辑内容...',
    String cancelButtonText = '取消',
    String saveButtonText = '保存',
    int maxLines = 3,
    IconData iconData = Icons.edit_note,
    Color? iconColor,
    double maxWidth = 300,
    // Duration? transitionDuration, // 可选覆盖动画参数
    // Curve? transitionCurve,
  }) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;

    return showAppAnimatedDialog<void>(
      context: context,
      maxWidth: maxWidth,
      // transitionDuration: transitionDuration ?? const Duration(milliseconds: 350), // 如需覆盖
      // transitionCurve: transitionCurve ?? Curves.easeOutBack, // 如需覆盖
      pageBuilder: (BuildContext buildContext) {
        // pageBuilder 返回 EditDialog 实例
        return EditDialog(
          title: title,
          initialText: initialText,
          onSave: onSave,
          hintText: hintText,
          cancelButtonText: cancelButtonText,
          saveButtonText: saveButtonText,
          maxLines: maxLines,
          iconData: iconData,
          iconColor: effectiveIconColor,
        );
      },
    );
  }

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController _controller;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    final text = _controller.text.trim();
    if (_isSaving) return;
    setState(() { _isSaving = true; });

    try {
      Navigator.pop(context); // 先关闭
      await widget.onSave(text); // 再执行保存回调
    } catch (e) {
      print("Error during EditDialog onSave callback: $e");
      // 可以在这里显示错误提示，但对话框已关闭，通常由调用者处理
      rethrow; // 重新抛出错误，让调用者知道
    }
    // 不需要 finally 重置状态，因为 widget 已 pop
  }

  void _handleCancel() {
    if (_isSaving) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // EditDialog 的根布局是 Material
    return Material(
      color: Colors.white,
      elevation: 6.0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.iconData,
                color: widget.iconColor,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),
              // --- 单个输入框 ---
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: widget.maxLines,
                textInputAction: widget.maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '内容不能为空'; // 基本校验
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // --- 按钮区域 ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : _handleCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      minimumSize: const Size(80, 40),
                    ),
                    child: Text(widget.cancelButtonText),
                  ),
                  const SizedBox(width: 8),
                  _isSaving
                      ? Container( // Loading indicator
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    height: 44,
                    constraints: const BoxConstraints(minWidth: 88),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                      : ElevatedButton( // Save button
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      elevation: 2,
                      shadowColor: theme.primaryColor.withOpacity(0.4),
                      minimumSize: const Size(88, 44),
                    ),
                    child: Text(widget.saveButtonText),
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