// lib/widgets/components/screen/profile/experience/exp_task_card.dart

import 'package:flutter/material.dart';
import '../../../../../../../../utils/font/font_config.dart';
import '../models/task_style.dart';

class ExpTaskCard extends StatelessWidget {
  final Map<String, dynamic> task;

  const ExpTaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final used = task['used'];
    final limit = task['limit'];
    final completed = task['completed'];
    final name = task['name'];
    final description = task['description'];
    final expPerTask = task['expPerTask'];
    final type = task['type'];

    // 根据任务类型确定颜色和图标
    final TaskStyle taskStyle = TaskStyle.getTaskStyle(type, completed);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: taskStyle.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: taskStyle.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和计数
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTaskTitle(taskStyle, name, completed),
              Text(
                '$used/$limit',
                style: TextStyle(
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: taskStyle.color,
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // 进度条
          _buildTaskProgressBar(taskStyle.color, used, limit),

          SizedBox(height: 6),

          // 描述和每次任务经验值
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontFamily: FontConfig.defaultFontFamily,
                    fontFamilyFallback: FontConfig.fontFallback,
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '+$expPerTask经验/次',
                style: TextStyle(
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: taskStyle.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建任务标题
  Widget _buildTaskTitle(TaskStyle taskStyle, String name, bool completed) {
    return Row(
      children: [
        Icon(taskStyle.icon, size: 16, color: taskStyle.color),
        SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: completed ? Colors.grey : Colors.grey.shade800,
          ),
        ),
        if (completed)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Icon(
                Icons.check_circle,
                color: Colors.green.shade400,
                size: 14
            ),
          ),
      ],
    );
  }

  // 构建任务进度条
  Widget _buildTaskProgressBar(Color taskColor, int used, int limit) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: used / limit,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(taskColor),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}