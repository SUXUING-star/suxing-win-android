// lib/widgets/form/gameform/field/image_url_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';

class ImageUrlDialog extends StatefulWidget {
  final String? initialUrl;

  const ImageUrlDialog({
    Key? key,
    this.initialUrl,
  }) : super(key: key);

  @override
  State<ImageUrlDialog> createState() => _ImageUrlDialogState();
}

class _ImageUrlDialogState extends State<ImageUrlDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isValidImage = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.initialUrl ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<bool> _validateImageUrl(String url) async {
    if (!url.startsWith('http')) return false;

    try {
      // 创建一个 Completer 来处理异步验证
      final completer = Completer<bool>();

      final imageProvider = NetworkImage(url);
      final imageStream = imageProvider.resolve(ImageConfiguration());

      // 添加监听器
      imageStream.addListener(
        ImageStreamListener(
              (ImageInfo imageInfo, bool synchronousCall) {
            // 图片加载成功
            completer.complete(true);
          },
          onError: (dynamic exception, StackTrace? stackTrace) {
            // 图片加载失败
            completer.complete(false);
          },
        ),
      );

      // 等待结果
      return await completer.future;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('输入图片链接'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: '图片链接',
                hintText: '请输入http/https图片链接',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入图片链接';
                }
                if (!value.startsWith('http')) {
                  return '请输入有效的http/https链接';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            if (_isChecking)
              CircularProgressIndicator()
            else if (_urlController.text.isNotEmpty && _isValidImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _urlController.text,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              setState(() => _isChecking = true);
              final isValid = await _validateImageUrl(_urlController.text);
              setState(() {
                _isChecking = false;
                _isValidImage = isValid;
              });

              if (isValid) {
                Navigator.of(context).pop(_urlController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('无效的图片链接')),
                );
              }
            }
          },
          child: Text('确认'),
        ),
      ],
    );
  }
}