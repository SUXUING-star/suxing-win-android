// lib/widgets/link_form_dialog.dart
import 'package:flutter/material.dart';
import '../../models/link.dart';

class LinkFormDialog extends StatefulWidget {
  final Link? link;
  const LinkFormDialog({Key? key, this.link}) : super(key: key);

  @override
  State<LinkFormDialog> createState() => _LinkFormDialogState();
}

class _LinkFormDialogState extends State<LinkFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _colorController;
  late TextEditingController _orderController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.link?.title);
    _descriptionController = TextEditingController(text: widget.link?.description);
    _urlController = TextEditingController(text: widget.link?.url);
    _colorController = TextEditingController(text: widget.link?.color ?? '#228be6');  // 默认蓝色
    _orderController = TextEditingController(text: widget.link?.order.toString() ?? '0');
    _isActive = widget.link?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _colorController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.link == null ? '添加链接' : '编辑链接'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '标题'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入标题';
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
                decoration: const InputDecoration(labelText: 'URL'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入URL';
                  }
                  if (!Uri.tryParse(value)!.isAbsolute) {
                    return '请输入有效的URL';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: '颜色代码',
                  hintText: '#228be6',
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
                controller: _orderController,
                decoration: const InputDecoration(labelText: '排序'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入排序数字';
                  }
                  if (int.tryParse(value) == null) {
                    return '请输入有效的数字';
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
              final linkData = {
                if (widget.link != null) '_id': widget.link!.id,
                'title': _titleController.text,
                'description': _descriptionController.text,
                'url': _urlController.text,
                'icon': 'link',  // 固定使用link图标
                'color': _colorController.text,
                'order': int.parse(_orderController.text),
                'isActive': _isActive,
                'createTime': widget.link?.createTime ?? DateTime.now(),
              };
              Navigator.pop(context, linkData);
            }
          },
          child: Text(widget.link == null ? '添加' : '保存'),
        ),
      ],
    );
  }
}