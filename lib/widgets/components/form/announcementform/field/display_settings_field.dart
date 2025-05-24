import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'image_field.dart';

class DisplaySettingsField extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int priority;
  final dynamic imageSource;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;
  final Function(bool) onActiveChanged;
  final Function(int) onPriorityChanged;
  final ValueChanged<dynamic> onImageSourceChanged;

  const DisplaySettingsField({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.priority,
    required this.imageSource, // 修改
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onActiveChanged,
    required this.onPriorityChanged,
    required this.onImageSourceChanged, // 修改
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期部分 - 不变
        const Text('显示日期',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _buildDateField(
                    context, '开始日期', startDate, onStartDateChanged)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildDateField(
                    context, '结束日期', endDate, onEndDateChanged)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('设置公告的显示时间范围。',
            style: TextStyle(
                fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),

        // 优先级部分 - 不变
        const Text('优先级',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          // 使用 DropdownButtonFormField 更好
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 调整内边距
          ),
          value: priority.clamp(1, 10), // 确保值在1-10
          items: List.generate(10, (index) => index + 1) // 生成 1 到 10
              .map((p) => DropdownMenuItem(value: p, child: Text('$p')))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onPriorityChanged(value);
            }
          },
        ),
        const SizedBox(height: 8),
        const Text('数字越大优先级越高 (10为最高)。',
            style: TextStyle(
                fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),

        // --- 图片上传组件 (修改) ---
        AnnouncementImageField(
          imageSource: imageSource, // 传入 imageSource
          onImageSourceChanged: onImageSourceChanged, // 传入 onImageSourceChanged
        ),
        const SizedBox(height: 16),

        // 是否激活部分 - 不变
        Row(
          children: [
            const Text('是否激活',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Switch(value: isActive, onChanged: onActiveChanged),
          ],
        ),
        const Text('激活后将在指定日期内对用户可见。',
            style: TextStyle(
                fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
      ],
    );
  }

  // _buildDateField 方法 - 保持不变
  Widget _buildDateField(BuildContext context, String label,
      DateTime initialDate, Function(DateTime) onDateChanged) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return InkWell(
      onTap: () async {
        final DateTime? date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2020), // 允许更早的日期
          lastDate: DateTime(2101), // 允许更晚的日期
        );
        if (date != null) {
          // 如果需要保留时间，可以结合 TimeOfDay 选择器或使用现有时间
          final currentTime = TimeOfDay.fromDateTime(initialDate);
          final finalDateTime = DateTime(date.year, date.month, date.day,
              currentTime.hour, currentTime.minute);
          onDateChanged(finalDateTime); // 返回包含时间的 DateTime
          // 如果只需要日期，则： onDateChanged(date);
        }
      },
      child: InputDecorator(
        // 使用 InputDecorator 样式更统一
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // 调整边距
        ),
        child: Text(dateFormat.format(initialDate)),
      ),
    );
  }
}
