// lib/widgets/components/form/announcementform/field/basic_info_field.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';

class BasicInfoField extends StatelessWidget {
  final String title;
  final String content;
  final String type;
  final Function(String) onTitleChanged;
  final Function(String) onContentChanged;
  final Function(String) onTypeChanged;

  const BasicInfoField({
    super.key,
    required this.title,
    required this.content,
    required this.type,
    required this.onTitleChanged,
    required this.onContentChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> types = ['info', 'warning', 'error', 'success', 'update', 'event'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        const Text(
          '标题',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        FormTextInputField(
          initialValue: title,
          decoration: const InputDecoration(
            hintText: '输入公告标题',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入标题';
            }
            return null;
          },
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: 16),

        // 内容
        const Text(
          '内容',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        FormTextInputField(
          initialValue: content,
          decoration: const InputDecoration(
            hintText: '输入公告内容',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入内容';
            }
            return null;
          },
          onChanged: onContentChanged,
        ),
        const SizedBox(height: 16),

        // 类型
        const Text(
          '类型',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: type,
              isExpanded: true,
              hint: const Text('选择公告类型'),
              items: types.map((type) {
                IconData icon;
                Color color;

                // 匹配类型对应的图标和颜色
                switch (type) {
                  case 'warning':
                    icon = Icons.warning;
                    color = Colors.orange;
                    break;
                  case 'error':
                    icon = Icons.error;
                    color = Colors.red;
                    break;
                  case 'success':
                    icon = Icons.check_circle;
                    color = Colors.green;
                    break;
                  case 'update':
                    icon = Icons.system_update;
                    color = Colors.blue;
                    break;
                  case 'event':
                    icon = Icons.event;
                    color = Colors.purple;
                    break;
                  default: // 'info'
                    icon = Icons.info;
                    color = Colors.teal;
                    break;
                }

                return DropdownMenuItem<String>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 12),
                      Text(type),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onTypeChanged(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '选择最适合您公告内容的类型，不同类型有不同的视觉样式。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}