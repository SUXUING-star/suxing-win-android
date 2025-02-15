import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/tool.dart';

class ToolFormDialog extends StatefulWidget {
  final Tool? tool;

  const ToolFormDialog({Key? key, this.tool}) : super(key: key);

  @override
  _ToolFormDialogState createState() => _ToolFormDialogState();
}

class _ToolFormDialogState extends State<ToolFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _name;
  late String _description;
  late String _color;
  late List<Map<String, String>> _downloads;

  @override
  void initState() {
    super.initState();

    // 初始化数据
    _name = widget.tool?.name ?? '';
    _description = widget.tool?.description ?? '';
    _color = widget.tool?.color ?? '#228b6e';

    // 初始化下载链接
    _downloads = widget.tool != null && widget.tool!.downloads.isNotEmpty
        ? widget.tool!.downloads.map((download) => {
      'name': download['name']?.toString() ?? '',
      'description': download['description']?.toString() ?? '',
      'url': download['url']?.toString() ?? '',
    }).toList()
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
    if (_formKey.currentState!.validate()) {
      final toolData = {
        'name': _name.trim(),
        'description': _description.trim(),
        'color': _color.trim(),
        'downloads': _downloads.map((download) => {
          'name': download['name']!.trim(),
          'description': download['description']!.trim(),
          'url': download['url']!.trim(),
        }).toList(),
        'isActive': true,
      };

      // 如果是编辑，添加 id
      if (widget.tool != null) {
        toolData['id'] = widget.tool!.id;
      }

      Navigator.of(context).pop(toolData);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mounted) {
      setState(() {
        // 更新状态
      });
    }

    return AlertDialog(
      title: Text(widget.tool == null ? '添加工具' : '编辑工具'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 工具名称
              TextFormField(
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
              TextFormField(
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
              TextFormField(
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
                        color: Color(int.parse(_color.replaceFirst('#', '0xFF'))),
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

              // 下载链接管理
              Text(
                '下载链接',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_downloads.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _downloads.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: _downloads[index]['name'],
                              decoration: InputDecoration(
                                labelText: '下载名称',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _downloads[index]['name'] = value;
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入下载名称';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              initialValue: _downloads[index]['description'],
                              decoration: InputDecoration(
                                labelText: '下载描述',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _downloads[index]['description'] = value;
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入下载描述';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              initialValue: _downloads[index]['url'],
                              decoration: InputDecoration(
                                labelText: '下载链接',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _downloads[index]['url'] = value;
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
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
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeDownloadLink(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // 添加下载链接按钮
              ElevatedButton.icon(
                onPressed: _addDownloadLink,
                icon: Icon(Icons.add),
                label: Text('添加下载链接'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text('保存'),
        ),
      ],
    );
  }
}