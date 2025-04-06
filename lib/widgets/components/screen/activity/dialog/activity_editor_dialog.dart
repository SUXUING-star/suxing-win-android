// lib/widgets/components/screen/activity/dialog/activity_editor_dialog.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/edit_dialog.dart'; // 导入 showAppAnimatedDialog
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // 导入 AppSnackBar

class ActivityEditorDialog extends StatefulWidget {
  final String initialContent;
  final bool initialIsPublic;
  // *** 新增：接收 onSave 回调 ***
  final Future<void> Function(String content, bool isPublic) onSave;
  final String title;
  final String hintText;
  final String contentLabel;
  final String publicSwitchLabel;
  final String cancelButtonText;
  final String saveButtonText;

  const ActivityEditorDialog({
    Key? key,
    required this.initialContent,
    required this.initialIsPublic,
    required this.onSave, // *** 必须提供 onSave ***
    this.title = '编辑动态',
    this.hintText = '说点什么...',
    this.contentLabel = '内容',
    this.publicSwitchLabel = '公开可见',
    this.cancelButtonText = '取消',
    this.saveButtonText = '保存',
  }) : super(key: key);

  /// 显示动态编辑对话框的静态方法
  // *** 修改 show 方法，不再直接返回结果，而是等待 onSave 完成 ***
  static Future<void> show({
    // 返回 Future<void>
    required BuildContext context,
    required String initialContent,
    required bool initialIsPublic,
    required Future<void> Function(String content, bool isPublic)
        onSave, // *** 接收 onSave ***
    String title = '编辑动态',
    String hintText = '说点什么...',
    String publicSwitchLabel = '公开可见',
    String cancelButtonText = '取消',
    String saveButtonText = '保存',
    double maxWidth = 320,
  }) {
    // 返回 showAppAnimatedDialog 的 Future
    return showAppAnimatedDialog<void>(
      // 泛型为 void
      context: context,
      maxWidth: maxWidth,
      pageBuilder: (BuildContext buildContext) {
        // 返回 ActivityEditorDialog 实例，并传入 onSave
        return ActivityEditorDialog(
          initialContent: initialContent,
          initialIsPublic: initialIsPublic,
          onSave: onSave, // *** 传递 onSave ***
          title: title,
          hintText: hintText,
          publicSwitchLabel: publicSwitchLabel,
          cancelButtonText: cancelButtonText,
          saveButtonText: saveButtonText,
        );
      },
    );
  }

  @override
  State<ActivityEditorDialog> createState() => _ActivityEditorDialogState();
}

class _ActivityEditorDialogState extends State<ActivityEditorDialog> {
  late TextEditingController _contentController;
  late bool _isPublic;
  bool _isSaving = false; // *** 添加保存状态 ***
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    _isPublic = widget.initialIsPublic;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // *** 修改 _handleSave 为 async，并调用 widget.onSave ***
  Future<void> _handleSave() async {
    // 简单的非空检查
    final String content = _contentController.text.trim();
    if (content.isEmpty) {
      // 可以在这里加个提示，或者依赖外部 onSave 处理
      if (mounted) AppSnackBar.showWarning(context, "内容不能为空");
      return;
    }

    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    }); // *** 设置保存中状态 ***

    try {
      // *** 调用外部传入的 onSave 异步函数 ***
      await widget.onSave(content, _isPublic);
      // 如果 onSave 没抛异常，说明外部操作成功了
      if (mounted) {
        Navigator.pop(context); // *** 操作成功后关闭对话框 ***
      }
    } catch (e) {
      print("ActivityEditorDialog: onSave callback failed: $e");
      // 外部 onSave 出错了，对话框不关闭，但要停止加载状态
      if (mounted) {
        setState(() {
          _isSaving = false;
        }); // *** 恢复按钮状态 ***
        // 可以在这里显示通用错误，或者让外部 onSave 自己处理提示
        // AppSnackBar.showError(context, "保存失败: $e");
      }
      // 错误不重新抛出，让对话框保持打开状态
    }
    // *** 不再需要在 finally 里设置 _isSaving = false，因为成功时 pop，失败时在 catch 里设置 ***
  }

  void _handleCancel() {
    if (_isSaving) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 使用 Material 作为根，提供背景和形状
    return Material(
      color: Colors.white,
      elevation: 6.0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),

              // 内容输入框
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: widget.contentLabel, // 使用 Label
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide:
                          BorderSide(color: theme.primaryColor, width: 1.5)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 4, // 允许多行输入
                textInputAction: TextInputAction.newline,
                // validator: (value) { ... } // 可以添加验证逻辑
              ),
              const SizedBox(height: 16),

              // 公开状态开关
              SwitchListTile(
                title: Text(
                  widget.publicSwitchLabel,
                  style: theme.textTheme.bodyLarge,
                ),
                value: _isPublic,
                onChanged: (bool value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
                activeColor: theme.primaryColor,
                contentPadding: EdgeInsets.zero, // 去掉默认内边距
                dense: true, // 更紧凑
              ),
              const SizedBox(height: 24),

              // 按钮区域
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FunctionalTextButton(
                      onPressed: _isSaving ? null : _handleCancel,
                      label: widget.cancelButtonText),
                  const SizedBox(width: 8),
                  _isSaving
                      ? LoadingWidget.inline(size: 12)
                      : FunctionalButton(
                          onPressed: _handleSave, label: widget.saveButtonText)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
