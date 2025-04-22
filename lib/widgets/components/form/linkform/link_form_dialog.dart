import 'package:flutter/material.dart';
import 'package:suxingchahui/models/linkstools/link.dart'; // 确认路径
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart'; // 确认路径
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 确认路径 (虽然这里不用，但保持一致性)
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart'; // 确认路径
import 'package:mongo_dart/mongo_dart.dart' as mongo; // 如果 Link ID 是 ObjectId
import 'dart:async';

import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // For Completer

// --- 静态方法用于显示对话框 ---
class LinkFormDialog {
  /// 显示添加/编辑链接的对话框
  /// 返回 Future<Map<String, dynamic>?>: 成功保存时返回链接数据 Map，否则返回 null
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Link? initialLink, // 传入要编辑的链接，null 表示添加
  }) {
    // 使用 GlobalKey 来访问 _LinkFormContentState
    final GlobalKey<_LinkFormContentState> contentKey =
        GlobalKey<_LinkFormContentState>();

    return BaseInputDialog.show<Map<String, dynamic>>(
      context: context,
      title: initialLink == null ? '添加链接' : '编辑链接',
      iconData: initialLink == null ? Icons.add_link : Icons.link_outlined,
      maxWidth: 450, // 根据内容调整宽度
      barrierDismissible: false,
      allowDismissWhenNotProcessing: false,
      confirmButtonText: initialLink == null ? '添加' : '保存',

      // --- 内容构建 ---
      contentBuilder: (ctx) {
        return _LinkFormContent(
          key: contentKey, // 将 key 传递给内容 Widget
          initialLink: initialLink,
        );
      },

      // --- 确认回调 ---
      onConfirm: () async {
        final state = contentKey.currentState;
        if (state != null) {
          // 1. 验证表单
          if (state.validateForm()) {
            // 2. 获取数据
            final linkData = state.getLinkData();
            if (linkData != null) {
              // 3. （可选）异步操作
              print("Link Form validated and data retrieved: $linkData");
              return linkData; // 返回数据，BaseInputDialog 会关闭
            } else {
              // getLinkData 内部可能因为解析失败返回 null
              print(
                  "Link Form validation passed, but data retrieval failed (e.g., order parse error).");
              // 可以在这里给用户提示，例如 SnackBar
              AppSnackBar.showWarning(context, "无法保存，请检查排序字段是否为有效数字。");
              return null; // 数据获取失败，不关闭
            }
          } else {
            print("Link Form validation failed.");
            return null; // 验证失败，返回 null，BaseInputDialog 不关闭
          }
        }
        print("Error: Link Content state is null.");
        return null; // 状态获取失败，不关闭
      },
    );
  }
}

// --- 内部表单内容 Widget ---
class _LinkFormContent extends StatefulWidget {
  final Link? initialLink;

  const _LinkFormContent({super.key, this.initialLink});

  @override
  _LinkFormContentState createState() => _LinkFormContentState();
}

class _LinkFormContentState extends State<_LinkFormContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _colorController;
  late TextEditingController _orderController;
  bool _isActive = true;

  // 用于颜色预览
  Color _previewColor = Colors.blue; // 默认颜色

  @override
  void initState() {
    super.initState();

    // 初始化 Controllers
    _titleController =
        TextEditingController(text: widget.initialLink?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialLink?.description ?? '');
    _urlController = TextEditingController(text: widget.initialLink?.url ?? '');
    _colorController = TextEditingController(
        text: widget.initialLink?.color ?? '#228be6'); // 默认蓝色
    _orderController = TextEditingController(
        text: widget.initialLink?.order.toString() ?? '0');
    _isActive = widget.initialLink?.isActive ?? true;

    // 初始化颜色预览
    _updatePreviewColor(_colorController.text);

    // 监听颜色输入变化以更新预览
    _colorController.addListener(() {
      _updatePreviewColor(_colorController.text);
    });
  }

  @override
  void dispose() {
    // Dispose Controllers
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _colorController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _updatePreviewColor(String colorHex) {
    Color? newColor = _tryParseColor(colorHex);
    if (newColor != null && mounted) {
      setState(() {
        _previewColor = newColor;
      });
    }
  }

  Color? _tryParseColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      try {
        return Color(int.parse(hexColor, radix: 16));
      } catch (e) {/* 解析失败 */}
    }
    return null;
  }

  bool _validateColor(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    // 放宽要求，允许3位或6位，带或不带 #
    final validHex = RegExp(r'^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$');
    if (!validHex.hasMatch(value.trim())) return false;
    return _tryParseColor(value.trim()) != null;
  }

  // 供外部调用：验证表单
  bool validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  // 供外部调用：获取表单数据
  // 返回 Map? 是因为 order 可能解析失败
  Map<String, dynamic>? getLinkData() {
    final order = int.tryParse(_orderController.text.trim());
    if (order == null) {
      // 如果 order 解析失败，返回 null 表示数据无效
      return null;
    }

    // 确保颜色保存时带有 '#' 前缀且为6位
    String finalColor = _colorController.text.trim();
    if (!finalColor.startsWith('#')) {
      finalColor = '#$finalColor';
    }
    // (如果需要强制6位，可以在这里处理3位转6位)
    if (finalColor.length == 4) {
      // #abc -> #aabbcc
      finalColor =
          '#${finalColor[1]}${finalColor[1]}${finalColor[2]}${finalColor[2]}${finalColor[3]}${finalColor[3]}';
    }

    return {
      // 如果 ID 是 ObjectId，需要这样处理
      // '_id': widget.initialLink?.id ?? mongo.ObjectId(),
      // 如果 ID 是 String，可以这样
      if (widget.initialLink?.id != null) '_id': widget.initialLink!.id,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'url': _urlController.text.trim(),
      'icon': 'link', // 默认值或根据需要设置
      'color': finalColor, // 使用处理后的颜色值
      'order': order, // 使用解析后的整数
      'isActive': _isActive,
      'createTime': widget.initialLink?.createTime ?? DateTime.now(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        // 使用 Column，因为 BaseInputDialog 会处理滚动
        mainAxisSize: MainAxisSize.min, // 尽可能收缩
        children: [
          // --- 标题 ---
          FormTextInputField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题 *',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入标题';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // --- 描述 ---
          FormTextInputField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '描述 *',
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            minLines: 1,
            textInputAction: TextInputAction.newline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入描述';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // --- URL ---
          FormTextInputField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL *',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入URL';
              }
              try {
                final uri = Uri.parse(value.trim());
                // 确保是绝对路径且有协议和域名
                if (!uri.isAbsolute || !uri.hasScheme || !uri.hasAuthority) {
                  return '请输入有效的URL (例如 https://...)';
                }
                return null;
              } catch (e) {
                return '请输入有效的URL';
              }
            },
          ),
          const SizedBox(height: 16),

          // --- 颜色 ---
          FormTextInputField(
            controller: _colorController,
            decoration: InputDecoration(
              labelText: '颜色 *',
              hintText: '例如: #228be6 或 #3a3',
              border: const OutlineInputBorder(),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                      color: _previewColor,
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: Colors.grey.shade400, width: 0.5)),
                ),
              ),
            ),
            validator: (value) {
              if (!_validateColor(value)) {
                return '请输入有效的3位或6位十六进制颜色 (例如 #228be6)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // --- 排序 ---
          FormTextInputField(
            controller: _orderController,
            decoration: const InputDecoration(
              labelText: '排序 *',
              prefixIcon: Icon(Icons.sort_by_alpha),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入排序数字';
              }
              if (int.tryParse(value.trim()) == null) {
                return '请输入有效的整数';
              }
              return null;
            },
          ),
          const SizedBox(height: 8), // SwitchListTile 前间距小一点

          // --- 是否启用 ---
          SwitchListTile(
            title: const Text('是否启用'),
            value: _isActive,
            onChanged: (bool value) {
              setState(() {
                _isActive = value;
              });
            },
            dense: true, // 使其更紧凑
            contentPadding: const EdgeInsets.symmetric(horizontal: 4), // 调整内边距
            activeColor: Theme.of(context).primaryColor, // 使用主题色
          ),
        ],
      ),
    );
  }
}
