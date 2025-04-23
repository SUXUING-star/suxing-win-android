import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import '../../../../models/linkstools/tool.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class ToolFormDialog extends StatefulWidget {
  final Tool? tool;

  const ToolFormDialog({super.key, this.tool});

  @override
  _ToolFormDialogState createState() => _ToolFormDialogState();
}

class _ToolFormDialogState extends State<ToolFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _name;
  late String _description;
  late String _color;
  late List<Map<String, String>> _downloads;

  // 添加一个标志来跟踪表单是否正在提交
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _name = widget.tool?.name ?? '';
    _description = widget.tool?.description ?? '';
    _color = widget.tool?.color ?? '#228b6e';
    _downloads = widget.tool != null
        ? widget.tool!.downloads
            .map((download) => {
                  'name': download.name,
                  'description': download.description,
                  'url': download.url,
                })
            .toList()
        : [];
  }

  void _addDownloadLink() {
    setState(() {
      _downloads.add({
        'name': '',
        'description': '',
        'url': '',
      });
    });
  }

  void _removeDownloadLink(int index) {
    setState(() {
      _downloads.removeAt(index);
    });
  }

  bool _validateColor(String value) {
    final colorRegex = RegExp(r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})$');
    return colorRegex.hasMatch(value);
  }

  void _submitForm() {
    // 防止重复提交
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // 关键修改：返回 Map<String, dynamic> 而不是 Tool 对象
      final Map<String, dynamic> toolData = {
        '_id': widget.tool?.id ?? mongo.ObjectId().toHexString(),
        'name': _name.trim(),
        'description': _description.trim(),
        'color': _color.trim(),
        'downloads': _downloads
            .map((download) => {
                  'name': download['name']!.trim(),
                  'description': download['description']!.trim(),
                  'url': download['url']!.trim(),
                })
            .toList(),
        'createTime': widget.tool?.createTime ?? DateTime.now(),
        'isActive': true,
      };

      // 使用Future.delayed给Flutter一些时间来完成状态更新
      Future.delayed(Duration.zero, () {
        if (mounted) {
          Navigator.of(context).pop(toolData);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 防止在提交过程中通过返回按钮关闭对话框
      onWillPop: () async => !_isSubmitting,
      child: Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.tool == null ? '添加工具' : '编辑工具',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate([
                              // 工具名称
                              FormTextInputField(
                                initialValue: _name,
                                decoration: InputDecoration(
                                  labelText: '工具名称',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => _name = value,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '请输入工具名称';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),

                              // 工具描述
                              FormTextInputField(
                                initialValue: _description,
                                decoration: InputDecoration(
                                  labelText: '工具描述',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                                onChanged: (value) => _description = value,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '请输入工具描述';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),

                              // 颜色选择
                              FormTextInputField(
                                initialValue: _color,
                                decoration: InputDecoration(
                                  labelText: '颜色',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Container(
                                    padding: EdgeInsets.all(8),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(
                                            _color.replaceFirst('#', '0xFF'))),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                onChanged: (value) => _color = value,
                                validator: (value) {
                                  if (value == null || !_validateColor(value)) {
                                    return '请输入有效的颜色值（如 #228b6e）';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),

                              Text(
                                '下载链接',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              SizedBox(height: 8),
                            ]),
                          ),
                          // 下载链接列表
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= _downloads.length) return null;
                                return Card(
                                  margin: EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FormTextInputField(
                                          initialValue: _downloads[index]
                                              ['name'],
                                          decoration: InputDecoration(
                                            labelText: '下载名称',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (value) {
                                            _downloads[index]['name'] = value;
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return '请输入下载名称';
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 8),
                                        FormTextInputField(
                                          initialValue: _downloads[index]
                                              ['description'],
                                          decoration: InputDecoration(
                                            labelText: '下载描述',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (value) {
                                            _downloads[index]['description'] =
                                                value;
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return '请输入下载描述';
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 8),
                                        FormTextInputField(
                                          initialValue: _downloads[index]
                                              ['url'],
                                          decoration: InputDecoration(
                                            labelText: '下载链接',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (value) {
                                            _downloads[index]['url'] = value;
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return '请输入下载链接';
                                            }
                                            try {
                                              Uri.parse(value);
                                              return null;
                                            } catch (e) {
                                              return '请输入有效的 URL';
                                            }
                                          },
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _removeDownloadLink(index),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: _downloads.length,
                            ),
                          ),
                          // 添加下载链接按钮
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isSubmitting ? null : _addDownloadLink,
                                icon: Icon(Icons.add),
                                label: Text('添加下载链接'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 底部按钮
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                // 延迟执行pop操作
                                Future.delayed(Duration.zero, () {
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                });
                              },
                        child: Text('取消'),
                      ),
                      SizedBox(width: 8),
                      FunctionalButton(
                        onPressed: _isSubmitting ? () {} : _submitForm,
                        isEnabled: !_isSubmitting,
                        label: '保存',
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
