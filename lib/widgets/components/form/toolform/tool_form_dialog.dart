// lib/widgets/components/form/toolform/tool_form_dialog.dart
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'package:suxingchahui/models/linkstools/tool.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';

class ToolFormDialog extends StatefulWidget {
  final InputStateService inputStateService;
  final Tool? tool; // 编辑时传入的对象，添加时为 null

  const ToolFormDialog({
    super.key,
    required this.inputStateService,
    this.tool,
  });

  // 静态方法用于显示对话框并返回结果
  // 返回 Future<Map<String, dynamic>?> 因为用户可能取消
  static Future<Map<String, dynamic>?> show(
      BuildContext context, InputStateService inputStateService,
      {Tool? tool}) {
    return showDialog<Map<String, dynamic>>(
      // 指定 showDialog 的返回类型
      context: context,
      // barrierDismissible: false, // 可以根据需要设置点击外部是否关闭，默认为 true
      builder: (BuildContext dialogContext) {
        return ToolFormDialog(
          tool: tool,
          inputStateService: inputStateService,
        );
      },
    );
  }

  @override
  _ToolFormDialogState createState() => _ToolFormDialogState();
}

class _ToolFormDialogState extends State<ToolFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _name;
  late String _description;
  late String _color;
  late List<Map<String, String>> _downloadsState;

  bool _hasInitializedDependencies = false;

  bool _isSubmitting = false; // 跟踪提交状态

  // 用于颜色预览的 State 变量
  late Color _previewColor;

  @override
  void initState() {
    super.initState();
    _name = widget.tool?.name ?? '';
    _description = widget.tool?.description ?? '';
    _color = widget.tool?.color ?? '#228b6e'; // 默认颜色
    // 初始化下载链接的 UI 状态
    _downloadsState = widget.tool != null
        ? widget.tool!.downloads
            .map((download) => {
                  'name': download.name,
                  'description': download.description,
                  'url': download.url,
                })
            .toList()
        : [];

    // 初始化颜色预览
    _updatePreviewColor(_color);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
  }

  // 更新颜色预览的辅助函数
  void _updatePreviewColor(String hexColor) {
    try {
      final colorValue = int.parse(hexColor.replaceFirst('#', '0xFF'));
      setState(() {
        _previewColor = Color(colorValue);
      });
    } catch (e) {
      // 如果颜色值无效，可以设置一个默认颜色或保持不变
      // print("Invalid color format: $hexColor. Using default preview.");
      setState(() {
        _previewColor = Colors.grey; // 或其他默认色
      });
    }
  }

  void _addDownloadLink() {
    // 如果正在提交，不允许添加
    if (_isSubmitting) return;
    setState(() {
      _downloadsState.add({
        'name': '',
        'description': '',
        'url': '',
      });
    });
  }

  void _removeDownloadLink(int index) {
    // 如果正在提交，不允许移除
    if (_isSubmitting) return;
    setState(() {
      _downloadsState.removeAt(index);
    });
  }

  bool _validateColor(String value) {
    final colorRegex =
        RegExp(r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$'); // 支持6位和8位Hex
    return colorRegex.hasMatch(value.trim());
  }

  void _submitForm() {
    if (_isSubmitting) return;

    // 先验证表单
    if (_formKey.currentState?.validate() ?? false) {
      // 设置提交状态
      setState(() {
        _isSubmitting = true;
      });

      // *** 使用 Tool 模型来构建对象 ***
      try {
        // 1. 将下载链接的 UI 状态 (_downloadsState) 转换为 List<ToolDownload>
        final List<ToolDownload> toolDownloads = _downloadsState
            .map((downloadMap) => ToolDownload(
                  name: downloadMap['name']!.trim(),
                  description: downloadMap['description']!.trim(),
                  url: downloadMap['url']!.trim(),
                ))
            .toList();

        // 2. 创建 Tool 实例
        final toolObject = Tool(
          id: widget.tool?.id ?? mongo.ObjectId().oid, // 保留原有 ID 或生成新 ID
          name: _name.trim(),
          description: _description.trim(),
          color: _color.trim(),
          downloads: toolDownloads, // 使用转换后的 List<ToolDownload>
          createTime:
              widget.tool?.createTime ?? DateTime.now(), // 保留原有创建时间或用当前时间
          isActive: widget.tool?.isActive ?? true, // 保留原有状态或默认为 true
          // 保留编辑时可能存在的 icon 和 type
          icon: widget.tool?.icon,
          type: widget.tool?.type,
        );

        // 3. 调用 toJson() 获取 Map
        final Map<String, dynamic> toolData = toolObject.toJson();

        // 4. 关闭对话框并返回 toolData Map
        // 使用 Future.delayed 确保 setState 完成渲染后再 pop
        Future.delayed(Duration.zero, () {
          if (mounted) {
            Navigator.of(context).pop(toolData);
          }
        });
      } catch (e) {
        AppSnackBar.showError("操作失败,${e.toString()}");
        setState(() {
          _isSubmitting = false; // 出错时重置提交状态
        });
      }
    } else {
      // 验证失败提示
      AppSnackBar.showError("请检查表单中的错误");
    }
  }

  @override
  Widget build(BuildContext context) {
    // *** 使用 PopScope 替换 WillPopScope ***
    return PopScope<Map<String, dynamic>?>(
      // <-- 1. 添加泛型 (匹配 Navigator.pop 的结果类型)
      canPop: !_isSubmitting,
      // <-- 2. 使用 onPopInvokedWithResult 并更新签名
      onPopInvokedWithResult: (bool didPop, Map<String, dynamic>? result) {
        // <-- 添加 result 参数
        // <-- 3. 内部逻辑不变，忽略 result
        if (!didPop && _isSubmitting) {
          // 最好检查 context
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger != null) {
            AppSnackBar.showInfo('正在保存中，请稍候...');
          }
        }
      },
      child: Dialog(
        // 增加圆角和 clipBehavior 以匹配 Card
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias, // 裁剪内容以符合圆角
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // 稍微调整最大宽度和高度，或根据需要设置
            maxWidth: MediaQuery.of(context).size.width * 0.85,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          // Card 提供背景色、阴影和形状，Dialog 本身通常是透明的
          child: Material(
            // 使用 Material 包裹 Card 的内容，确保主题效果正确应用
            type: MaterialType.card, // 模拟 Card 的材质类型
            elevation: 4.0, // 卡片阴影
            borderRadius: BorderRadius.circular(12.0), // 确保圆角一致
            child: Column(
              mainAxisSize: MainAxisSize.min, // 高度自适应内容
              children: [
                // --- 标题栏 ---
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0), // 调整内边距
                  child: Text(
                    widget.tool == null ? '添加工具' : '编辑工具',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Divider(height: 1, thickness: 1), // 添加分割线

                // --- 表单内容区域 (可滚动) ---
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      // 稍微减小滚动区域的内边距，让卡片边距更明显
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: CustomScrollView(
                        // 使用 CustomScrollView 优化长表单
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate([
                              SizedBox(height: 8), // 顶部留白
                              // --- 工具名称 ---
                              FormTextInputField(
                                inputStateService: widget.inputStateService,
                                initialValue: _name,
                                decoration: InputDecoration(
                                  labelText: '工具名称 *', // 标记必填
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.title),
                                ),
                                onChanged: (value) => _name = value, // 保存输入值
                                isEnabled: !_isSubmitting, // 提交中禁用
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '请输入工具名称';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),

                              // --- 工具描述 ---
                              FormTextInputField(
                                inputStateService: widget.inputStateService,
                                initialValue: _description,
                                decoration: InputDecoration(
                                  labelText: '工具描述 *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.description),
                                  alignLabelWithHint: true, // 标签与提示对齐
                                ),
                                maxLines: 3, // 增加行数
                                minLines: 2,
                                maxLength: 200, // 可以加个字数限制
                                onChanged: (value) => _description = value,
                                isEnabled: !_isSubmitting,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '请输入工具描述';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),

                              // --- 颜色选择 ---
                              FormTextInputField(
                                inputStateService: widget.inputStateService,
                                initialValue: _color,
                                decoration: InputDecoration(
                                  labelText: '颜色 (Hex) *',
                                  hintText: '#RRGGBB 或 #AARRGGBB',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Padding(
                                    // 使用 Padding 调整预览方块位置
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                          color: _previewColor, // 使用状态变量驱动预览
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color:
                                                  Colors.grey.shade400) // 加个边框
                                          ),
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  _color = value; // 保存输入值
                                  _updatePreviewColor(value); // 实时更新预览
                                },
                                isEnabled: !_isSubmitting,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '请输入颜色值';
                                  }
                                  if (!_validateColor(value)) {
                                    return '格式无效 (例: #228b6e)';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20), // 增加间距

                              // --- 下载链接标题 ---
                              Text(
                                '下载链接',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium, // 稍大一点的标题
                              ),
                              Divider(height: 16, thickness: 0.5),
                            ]),
                          ),
                          // --- 下载链接列表 ---
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= _downloadsState.length) {
                                  return null;
                                }
                                // 使用 Card 包裹每个下载链接表单，增加视觉分隔
                                return Card(
                                  elevation: 1.0, // 稍微一点阴影
                                  margin: EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 下载名称
                                        FormTextInputField(
                                          inputStateService:
                                              widget.inputStateService,
                                          initialValue: _downloadsState[index]
                                              ['name'],
                                          decoration: InputDecoration(
                                            labelText: '下载项名称 *',
                                            border: OutlineInputBorder(),
                                            isDense: true, // 更紧凑
                                          ),
                                          onChanged: (value) {
                                            _downloadsState[index]['name'] =
                                                value;
                                          },
                                          isEnabled: !_isSubmitting,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return '请输入名称';
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 10),
                                        // 下载描述
                                        FormTextInputField(
                                          inputStateService:
                                              widget.inputStateService,
                                          initialValue: _downloadsState[index]
                                              ['description'],
                                          decoration: InputDecoration(
                                            labelText: '下载项描述 *',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (value) {
                                            _downloadsState[index]
                                                ['description'] = value;
                                          },
                                          isEnabled: !_isSubmitting,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return '请输入描述';
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 10),
                                        // 下载链接
                                        FormTextInputField(
                                          inputStateService:
                                              widget.inputStateService,
                                          initialValue: _downloadsState[index]
                                              ['url'],
                                          decoration: InputDecoration(
                                            labelText: '下载链接 (URL) *',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (value) {
                                            _downloadsState[index]['url'] =
                                                value;
                                          },
                                          isEnabled: !_isSubmitting,
                                          keyboardType:
                                              TextInputType.url, // URL 键盘
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return '请输入链接';
                                            }
                                            // 更严格的 URL 验证
                                            final uri =
                                                Uri.tryParse(value.trim());
                                            if (uri == null ||
                                                !uri.isAbsolute ||
                                                (!uri.scheme
                                                    .startsWith('http'))) {
                                              return '请输入有效的 URL (http/https)';
                                            }
                                            return null;
                                          },
                                        ),
                                        // 删除按钮
                                        Align(
                                          // 使用 Align 控制按钮位置
                                          alignment: Alignment.centerRight,
                                          child: IconButton(
                                            icon: Icon(Icons.delete_outline,
                                                color: Colors.redAccent),
                                            tooltip: '移除此链接',
                                            padding:
                                                EdgeInsets.zero, // 移除默认padding
                                            visualDensity:
                                                VisualDensity.compact, // 更紧凑
                                            onPressed: _isSubmitting
                                                ? null
                                                : () =>
                                                    _removeDownloadLink(index),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: _downloadsState.length,
                            ),
                          ),
                          // --- 添加下载链接按钮 ---
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: OutlinedButton.icon(
                                // 使用 OutlinedButton 视觉上更轻量
                                onPressed:
                                    _isSubmitting ? null : _addDownloadLink,
                                icon: Icon(Icons.add_link),
                                label: Text('添加下载链接'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withSafeOpacity(0.5)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1), // 底部按钮上方的分割线
                // --- 底部按钮区域 ---
                Padding(
                  padding: const EdgeInsets.all(12.0), // 调整按钮区域边距
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end, // 按钮靠右
                    children: [
                      // 取消按钮
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                // 延迟执行 pop 操作确保状态更新完成
                                Future.delayed(Duration.zero, () {
                                  if (mounted) {
                                    Navigator.of(this.context)
                                        .pop(); // 取消直接返回 null
                                  }
                                });
                              },
                        child: Text('取消'),
                      ),
                      SizedBox(width: 8),
                      // 保存按钮
                      FunctionalButton(
                        onPressed: _submitForm, // 直接调用 _submitForm
                        label: '保存',
                        icon: Icons.save_alt_outlined,
                        isLoading: _isSubmitting, // 控制加载状态
                        isEnabled: !_isSubmitting, // 控制是否可点击
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
