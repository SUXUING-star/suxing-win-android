import 'package:flutter/material.dart';
import 'package:suxingchahui/models/linkstools/tool.dart'; // 确认路径
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart'; // 确认路径
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 确认路径
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart'; // 确认路径
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:async'; // For Completer

// Helper class to hold controllers for a download link
class _DownloadLinkControllers {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController urlController;

  _DownloadLinkControllers({String? name, String? description, String? url})
      : nameController = TextEditingController(text: name ?? ''),
        descriptionController = TextEditingController(text: description ?? ''),
        urlController = TextEditingController(text: url ?? '');

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    urlController.dispose();
  }

  Map<String, String> getData() {
    return {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'url': urlController.text.trim(),
    };
  }
}

// --- 静态方法用于显示对话框 ---
class ToolFormDialog {
  /// 显示添加/编辑工具的对话框
  /// 返回 Future<Map<String, dynamic>?>: 成功保存时返回工具数据 Map，否则返回 null
  static Future<Map<String, dynamic>?> show(
      BuildContext context, {
        Tool? initialTool, // 传入要编辑的工具，null 表示添加
      }) {
    // 使用 GlobalKey 来访问 _ToolFormContentState
    final GlobalKey<_ToolFormContentState> contentKey = GlobalKey<_ToolFormContentState>();

    return BaseInputDialog.show<Map<String, dynamic>>( // 指定返回类型
      context: context,
      title: initialTool == null ? '添加工具' : '编辑工具',
      iconData: initialTool == null ? Icons.add_circle_outline : Icons.edit_note,
      maxWidth: 500, // 可以根据内容调整宽度
      barrierDismissible: false, // 通常表单不希望点击外部关闭
      allowDismissWhenNotProcessing: false, // 也不希望返回按钮关闭 (除非点取消)
      confirmButtonText: '保存',

      // --- 内容构建 ---
      contentBuilder: (ctx) {
        return _ToolFormContent(
          key: contentKey, // 将 key 传递给内容 Widget
          initialTool: initialTool,
        );
      },

      // --- 确认回调 ---
      onConfirm: () async {
        final state = contentKey.currentState;
        if (state != null) {
          // 1. 验证表单
          if (state.validateForm()) {
            // 2. 获取数据
            final toolData = state.getToolData();
            // 3. 可以在这里执行异步保存操作（如果需要）
            // await Future.delayed(Duration(seconds: 1)); // 模拟网络请求
            print("Form validated and data retrieved: $toolData");
            return toolData; // 返回数据，BaseInputDialog 会关闭
          } else {
            print("Form validation failed.");
            return null; // 验证失败，返回 null，BaseInputDialog 不关闭
          }
        }
        print("Error: Content state is null.");
        return null; // 状态获取失败，不关闭
      },

      // onCancel 可以留空，BaseInputDialog 默认会处理关闭
    );
  }
}


// --- 内部表单内容 Widget ---
class _ToolFormContent extends StatefulWidget {
  final Tool? initialTool;

  const _ToolFormContent({super.key, this.initialTool});

  @override
  _ToolFormContentState createState() => _ToolFormContentState();
}

class _ToolFormContentState extends State<_ToolFormContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 主字段的 Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _colorController;

  // 下载链接的 Controllers 列表
  final List<_DownloadLinkControllers> _downloadControllers = [];

  // 用于颜色预览
  Color _previewColor = Colors.teal; // 默认颜色

  @override
  void initState() {
    super.initState();

    // 初始化主字段 Controllers
    _nameController = TextEditingController(text: widget.initialTool?.name ?? '');
    _descriptionController = TextEditingController(text: widget.initialTool?.description ?? '');
    _colorController = TextEditingController(text: widget.initialTool?.color ?? '#228b6e');

    // 初始化下载链接 Controllers
    if (widget.initialTool != null) {
      for (var download in widget.initialTool!.downloads) {
        _downloadControllers.add(_DownloadLinkControllers(
          name: download.name,
          description: download.description,
          url: download.url,
        ));
      }
    }

    // 初始化颜色预览
    _updatePreviewColor(_colorController.text);

    // 监听颜色输入变化以更新预览
    _colorController.addListener(() {
      _updatePreviewColor(_colorController.text);
    });
  }

  @override
  void dispose() {
    // Dispose 主字段 Controllers
    _nameController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();

    // Dispose 下载链接 Controllers
    for (var controllers in _downloadControllers) {
      controllers.dispose();
    }
    super.dispose();
  }

  void _updatePreviewColor(String colorHex) {
    Color? newColor = _tryParseColor(colorHex);
    if (newColor != null && mounted) {
      setState(() {
        _previewColor = newColor;
      });
    } else if (mounted) {
      // 如果解析失败，可以恢复默认或保持上一个有效颜色
      // setState(() { _previewColor = Colors.grey; });
    }
  }

  Color? _tryParseColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // 添加 alpha
    }
    if (hexColor.length == 8) {
      try {
        return Color(int.parse(hexColor, radix: 16));
      } catch (e) {
        // 解析失败
      }
    }
    return null; // 无效格式
  }

  bool _validateColor(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return _tryParseColor(value.trim()) != null;
  }

  void _addDownloadLink() {
    setState(() {
      _downloadControllers.add(_DownloadLinkControllers());
    });
  }

  void _removeDownloadLink(int index) {
    if (index >= 0 && index < _downloadControllers.length) {
      // Dispose 控制器是好习惯
      _downloadControllers[index].dispose();
      setState(() {
        _downloadControllers.removeAt(index);
      });
    }
  }

  // 供外部调用：验证表单
  bool validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  // 供外部调用：获取表单数据
  Map<String, dynamic> getToolData() {
    return {
      '_id': widget.initialTool?.id ?? mongo.ObjectId().toHexString(),
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'color': _colorController.text.trim(),
      'downloads': _downloadControllers
          .map((controllers) => controllers.getData())
          .toList(),
      'createTime': widget.initialTool?.createTime ?? DateTime.now(),
      'isActive': widget.initialTool?.isActive ?? true, // 保留或默认 true
    };
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Form 包裹 CustomScrollView
    return Form(
      key: _formKey,
      child: CustomScrollView(
        shrinkWrap: true, // 让 ScrollView 根据内容调整大小（在 Flexible 内重要）
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              // --- 工具名称 ---
              FormTextInputField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '工具名称 *',
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入工具名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- 工具描述 ---
              FormTextInputField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '工具描述 *',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入工具描述';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- 颜色选择 ---
              FormTextInputField(
                controller: _colorController,
                decoration: InputDecoration(
                  labelText: '颜色 *',
                  hintText: '例如: #228b6e',
                  border: const OutlineInputBorder(),
                  prefixIcon: Padding( // 用 Padding 包裹 Icon
                    padding: const EdgeInsets.all(12.0), // 调整内边距使预览居中
                    child: Container( // 颜色预览方块
                      width: 20,
                      height: 20, // 固定大小
                      decoration: BoxDecoration(
                          color: _previewColor, // 使用状态中的预览颜色
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade400, width: 0.5) // 加个边框更明显
                      ),
                    ),
                  ),
                ),
                validator: (value) {
                  if (!_validateColor(value)) {
                    return '请输入有效的6位十六进制颜色值 (例如 #228b6e)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24), // 与下一部分的间距

              // --- 下载链接标题 ---
              Text(
                '下载链接',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Divider(height: 16), // 分隔线
            ]),
          ),

          // --- 下载链接列表 ---
          if (_downloadControllers.isEmpty)
            SliverToBoxAdapter( // 如果列表为空，显示提示
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text("还没有添加下载链接", style: TextStyle(color: Colors.grey.shade600))),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final controllers = _downloadControllers[index];
                  return Card(
                    elevation: 1.5, // 轻微阴影
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FormTextInputField(
                            controller: controllers.nameController,
                            decoration: const InputDecoration(
                              labelText: '下载名称 *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // 调整内边距
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return '请输入下载名称';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12), // 调整间距
                          FormTextInputField(
                            controller: controllers.descriptionController,
                            decoration: const InputDecoration(
                              labelText: '下载描述 *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return '请输入下载描述';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          FormTextInputField(
                            controller: controllers.urlController,
                            decoration: const InputDecoration(
                              labelText: '下载链接 (URL) *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            keyboardType: TextInputType.url,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return '请输入下载链接';
                              try {
                                // 简单 URL 验证
                                final uri = Uri.parse(value.trim());
                                if (!uri.hasScheme || !uri.hasAuthority) {
                                  return '请输入有效的 URL (包含 http/https)';
                                }
                                return null;
                              } catch (e) {
                                return '请输入有效的 URL';
                              }
                            },
                          ),
                          Align( // 删除按钮靠右
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                              tooltip: '删除此链接',
                              padding: EdgeInsets.zero, // 减小点击区域
                              constraints: const BoxConstraints(), // 移除默认约束
                              onPressed: () => _removeDownloadLink(index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _downloadControllers.length,
              ),
            ),

          // --- 添加下载链接按钮 ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 16.0), // 调整按钮上下边距
              child: FunctionalButton( // 使用 FunctionalButton
                onPressed: _addDownloadLink,
                icon: Icons.add_link, // 换个更贴切的图标
                label: '添加下载链接',
                // isLoading: false, // 这个按钮本身不加载
                // isEnabled: true, // 默认启用
                padding: const EdgeInsets.symmetric(vertical: 8), // 调整按钮内边距
              ),
            ),
          ),
        ],
      ),
    );
  }
}