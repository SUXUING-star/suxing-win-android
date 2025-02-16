import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/tool.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

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
    _name = widget.tool?.name ?? '';
    _description = widget.tool?.description ?? '';
    _color = widget.tool?.color ?? '#228b6e';
    _downloads = widget.tool != null
        ? widget.tool!.downloads.map((download) => {
      'name': download.name,
      'description': download.description,
      'url': download.url,
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
      final downloads = _downloads.map((download) => ToolDownload(
        name: download['name']!.trim(),
        description: download['description']!.trim(),
        url: download['url']!.trim(),
      )).toList();

      final tool = Tool(
        id: widget.tool?.id ?? mongo.ObjectId().toHexString(),
        name: _name.trim(),
        description: _description.trim(),
        color: _color.trim(),
        createTime: widget.tool?.createTime ?? DateTime.now(),
        downloads: downloads,
        isActive: true,
      );

      Navigator.of(context).pop(tool);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                                      color: Color(
                                          int.parse(_color.replaceFirst('#', '0xFF'))),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            childCount: _downloads.length,
                          ),
                        ),
                        // 添加下载链接按钮
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: ElevatedButton.icon(
                              onPressed: _addDownloadLink,
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('取消'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('保存'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}