// lib/widgets/tool_form_dialog.dart
import 'package:flutter/material.dart';
import '../../models/tool.dart';

class ToolFormDialog extends StatefulWidget {
  final Tool? tool;
  const ToolFormDialog({Key? key, this.tool}) : super(key: key);

  @override
  State<ToolFormDialog> createState() => _ToolFormDialogState();
}

class _ToolFormDialogState extends State<ToolFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _colorController;
  late TextEditingController _typeController;
  List<Map<String, dynamic>> _downloads = [];
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tool?.name);
    _descriptionController = TextEditingController(text: widget.tool?.description);
    _colorController = TextEditingController(text: widget.tool?.color ?? '#19712C');  // 默认绿色
    _typeController = TextEditingController(text: widget.tool?.type);
    _downloads = List.from(widget.tool?.downloads ?? []);
    _isActive = widget.tool?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  void _addDownload() {
    showDialog(
      context: context,
      builder: (context) => _DownloadFormDialog(),
    ).then((download) {
      if (download != null) {
        setState(() {
          _downloads.add(download);
        });
      }
    });
  }

  void _editDownload(int index) {
    showDialog(
      context: context,
      builder: (context) => _DownloadFormDialog(download: _downloads[index]),
    ).then((download) {
      if (download != null) {
        setState(() {
          _downloads[index] = download;
        });
      }
    });
  }

  void _removeDownload(int index) {
    setState(() {
      _downloads.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tool == null ? '添加工具' : '编辑工具'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名称'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入名称';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '描述'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入描述';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: '颜色代码',
                  hintText: '#19712C',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入颜色代码';
                  }
                  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
                    return '请输入有效的HEX颜色代码';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: '类型'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入类型';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: const Text('是否启用'),
                value: _isActive,
                onChanged: (bool value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '下载链接',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addDownload,
                    tooltip: '添加下载链接',
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _downloads.length,
                itemBuilder: (context, index) {
                  final download = _downloads[index];
                  return ListTile(
                    title: Text(download['name'] ?? ''),
                    subtitle: Text(download['description'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editDownload(index),
                          tooltip: '编辑',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeDownload(index),
                          tooltip: '删除',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final toolData = {
                if (widget.tool != null) '_id': widget.tool!.id,
                'name': _nameController.text,
                'description': _descriptionController.text,
                'icon': 'build',  // 固定使用build图标
                'color': _colorController.text,
                'type': _typeController.text,
                'downloads': _downloads,
                'isActive': _isActive,
                'createTime': widget.tool?.createTime ?? DateTime.now(),
              };
              Navigator.pop(context, toolData);
            }
          },
          child: Text(widget.tool == null ? '添加' : '保存'),
        ),
      ],
    );
  }
}

class _DownloadFormDialog extends StatefulWidget {
  final Map<String, dynamic>? download;
  const _DownloadFormDialog({this.download});

  @override
  State<_DownloadFormDialog> createState() => _DownloadFormDialogState();
}

class _DownloadFormDialogState extends State<_DownloadFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.download?['name']);
    _descriptionController = TextEditingController(text: widget.download?['description']);
    _urlController = TextEditingController(text: widget.download?['url']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.download == null ? '添加下载' : '编辑下载'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名称'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入名称';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: '描述'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入描述';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: '下载链接'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入下载链接';
                }
                if (!Uri.tryParse(value)!.isAbsolute) {
                  return '请输入有效的URL';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'description': _descriptionController.text,
                'url': _urlController.text,
              });
            }
          },
          child: Text(widget.download == null ? '添加' : '保存'),
        ),
      ],
    );
  }
}