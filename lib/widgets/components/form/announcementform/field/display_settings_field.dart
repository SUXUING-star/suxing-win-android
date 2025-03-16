// lib/widgets/components/form/announcementform/field/display_settings_field.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DisplaySettingsField extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int priority;
  final String? imageUrl;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;
  final Function(bool) onActiveChanged;
  final Function(int) onPriorityChanged;
  final Function(String) onImageUrlChanged;

  const DisplaySettingsField({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.priority,
    required this.imageUrl,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onActiveChanged,
    required this.onPriorityChanged,
    required this.onImageUrlChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示日期
        const Text(
          '显示日期',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                context,
                '开始日期',
                startDate,
                    (date) => onStartDateChanged(date),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                context,
                '结束日期',
                endDate,
                    (date) => onEndDateChanged(date),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '设置公告的显示时间范围，超出此范围的公告将不会显示给用户。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        // 优先级
        const Text(
          '优先级',
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
            child: DropdownButton<int>(
              value: priority,
              isExpanded: true,
              items: List.generate(10, (index) {
                final priority = index + 1;
                return DropdownMenuItem<int>(
                  value: priority,
                  child: Text('$priority'),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  onPriorityChanged(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '优先级越高的公告将会优先显示给用户，10为最高优先级。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        // 图片 URL
        const Text(
          '图片URL (可选)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: imageUrl ?? '',
          decoration: const InputDecoration(
            hintText: '输入图片URL',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: onImageUrlChanged,
        ),
        const SizedBox(height: 8),
        const Text(
          '为公告添加图片，留空则不显示图片。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        // 是否激活
        Row(
          children: [
            const Text(
              '是否激活',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Switch(
              value: isActive,
              onChanged: onActiveChanged,
            ),
          ],
        ),
        const Text(
          '激活后将在指定日期内显示给用户，未激活的公告不会显示。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
      BuildContext context,
      String label,
      DateTime initialDate,
      Function(DateTime) onDateChanged,
      ) {
    return InkWell(
      onTap: () async {
        final DateTime? date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onDateChanged(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy-MM-dd').format(initialDate),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.calendar_today,
              size: 20,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}