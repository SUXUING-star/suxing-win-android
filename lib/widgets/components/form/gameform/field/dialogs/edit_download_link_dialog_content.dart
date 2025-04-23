// widgets/form/gameform/edit_download_link_dialog_content.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'dart:async'; // Future 需要
// 导入 DownloadLink 模型 (根据你的项目结构调整路径)
import '../../../../../../models/game/game.dart';

class EditDownloadLinkDialogContent extends StatefulWidget {
  final DownloadLink initialLink;
  // onSave 回调，成功时外部会处理状态更新和提示
  final Future<void> Function(DownloadLink updatedLink) onSave;
  // 可以传入自定义的标题、按钮文字等，增加灵活性
  final String dialogTitle;
  final String saveButtonText;
  final String cancelButtonText;
  final IconData iconData;

  const EditDownloadLinkDialogContent({
    super.key,
    required this.initialLink,
    required this.onSave,
    this.dialogTitle = '编辑下载链接',
    this.saveButtonText = '保存',
    this.cancelButtonText = '取消',
    this.iconData = Icons.link_outlined, // 默认图标
  });

  @override
  _EditDownloadLinkDialogContentState createState() =>
      _EditDownloadLinkDialogContentState();
}

class _EditDownloadLinkDialogContentState
    extends State<EditDownloadLinkDialogContent> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialLink.title);
    _urlController = TextEditingController(text: widget.initialLink.url);
    _descriptionController =
        TextEditingController(text: widget.initialLink.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedLink = DownloadLink(
        id: widget.initialLink.id, // 保持原始 ID
        title: _titleController.text.trim(),
        url: _urlController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      // 调用外部传入的 onSave 回调来处理实际的保存逻辑和状态更新
      await widget.onSave(updatedLink);

      // 如果 onSave 没有抛出异常，说明保存成功，关闭对话框
      if (mounted) {
        // 检查 widget 是否还在树中
        Navigator.pop(context); // 关闭对话框
        // 成功的提示由外部 onSave 之后处理，这里不处理
      }
    } catch (e) {
      print("Error during EditDownloadLinkDialogContent onSave callback: $e");
      // 保存失败的提示也应该由外部处理，或者在这里显示一个通用的
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 无论成功失败，重置保存状态
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _handleCancel() {
    if (_isSaving) return;
    Navigator.pop(context);
  }

  // 辅助方法，统一定义输入框样式
  InputDecoration _inputDecoration(
      ThemeData theme, String labelText, String hintText) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: TextStyle(fontSize: 14),
      hintStyle: TextStyle(fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 这个 Widget 的根是一个 Padding，它会被 showAppAnimatedDialog 包裹在 Material 里
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // 高度自适应
          children: [
            // --- 图标 和 标题 ---
            Icon(
              widget.iconData,
              color: theme.primaryColor, // 使用主题色
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              widget.dialogTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 18),

            // --- 三个输入框 ---
            FormTextInputField(
              controller: _titleController,
              decoration: _inputDecoration(theme, '链接标题 *', '例如：百度网盘'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '标题不能为空' : null,
            ),
            const SizedBox(height: 12),
            FormTextInputField(
              controller: _urlController,
              decoration: _inputDecoration(theme, '下载链接 *', 'https://...'),
              keyboardType: TextInputType.url,
              maxLines: null,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return '链接不能为空';
                }
                final trimmedUrl = v.trim();
                final uri = Uri.tryParse(trimmedUrl);
                // 检查是否解析成功，并且有 scheme (如 http, https) 和 host (域名部分)
                if (uri == null ||
                    !uri.hasScheme ||
                    !uri.hasAuthority ||
                    uri.host.isEmpty) {
                  // !uri.hasAbsolutePath 对于 magnet: 等链接可能为 false，所以用 !uri.hasAuthority 更通用
                  // uri.host.isEmpty 进一步确保不是像 "http://" 这样的无效链接
                  return '请输入有效的URL (例如 https://...)';
                }
                return null; // 验证通过
              },
            ),
            const SizedBox(height: 12),
            FormTextInputField(
              controller: _descriptionController,
              decoration: _inputDecoration(theme, '描述 (可选)', '例如：提取码: abcd'),
              maxLines: 2,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                if (value!.length > 12) return "长度过长";
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
                    foregroundColor:
                        theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    minimumSize: const Size(80, 40),
                  ),
                  child: Text(widget.cancelButtonText),
                ),
                const SizedBox(width: 8),
                _isSaving
                    ? Container(
                        // Loading
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        height: 44,
                        constraints: const BoxConstraints(minWidth: 88),
                        alignment: Alignment.center,
                        child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5)),
                      )
                    : FunctionalButton(
                        // Save Button
                        onPressed: _handleSave, // 调用内部的保存处理
                        label: widget.saveButtonText,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
