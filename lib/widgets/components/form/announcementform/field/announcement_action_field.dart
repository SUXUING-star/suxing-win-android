// lib/widgets/components/form/announcementform/field/announcement_action_field.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';

class AnnouncementActionField extends StatelessWidget {
  final String? actionUrl;
  final String? actionText;
  final InputStateService inputStateService;
  final Function(String) onActionUrlChanged;
  final Function(String) onActionTextChanged;

  const AnnouncementActionField({
    super.key,
    required this.actionUrl,
    required this.actionText,
    required this.inputStateService,
    required this.onActionUrlChanged,
    required this.onActionTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '操作按钮设置 (可选)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),

        // 操作链接
        const Text(
          '操作链接',
          style: TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        FormTextInputField(
          inputStateService: inputStateService,
          initialValue: actionUrl ?? '',
          decoration: const InputDecoration(
            hintText: '输入链接URL',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: Icon(Icons.link),
          ),
          onChanged: onActionUrlChanged,
          validator: (value){
            if( !value!.startsWith("http") ){
              return '链接不合法';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        const Text(
          '用户点击按钮时会跳转到此链接，留空则不显示按钮。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        // 操作文本
        const Text(
          '按钮文本',
          style: TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        FormTextInputField(
          inputStateService: inputStateService,
          initialValue: actionText ?? '',
          decoration: const InputDecoration(
            hintText: '输入按钮显示文本',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: Icon(Icons.text_fields),
          ),
          onChanged: onActionTextChanged,
          validator: (value){
            if(value != null || value!.isEmpty) return "文本为空";
            return null;
          },
        ),
        const SizedBox(height: 8),
        const Text(
          '按钮上显示的文本，例如"立即查看"、"了解更多"等。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 16),

        // 预览
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withSafeOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withSafeOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '按钮预览',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: (actionUrl?.isNotEmpty ?? false) && (actionText?.isNotEmpty ?? false)
                      ? () {}
                      : null,
                  child: Text(actionText?.isNotEmpty ?? false ? actionText! : '按钮文本'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  (actionUrl?.isNotEmpty ?? false) && (actionText?.isNotEmpty ?? false)
                      ? '按钮将会显示并可点击'
                      : '请同时填写操作链接和按钮文本才能显示按钮',
                  style: TextStyle(
                    fontSize: 12,
                    color: (actionUrl?.isNotEmpty ?? false) && (actionText?.isNotEmpty ?? false)
                        ? Colors.green
                        : Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}