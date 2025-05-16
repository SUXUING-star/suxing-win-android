// lib/widgets/components/screen/profile/experience/exp_task_card.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/daily_progress.dart'; // 导入 Task 模型
import 'package:suxingchahui/widgets/components/screen/profile/experience/models/task_style.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';     // 导入 AppText
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';// 导入 AppTextType

class ExpTaskCard extends StatelessWidget {
  // **** 修改输入参数类型为 Task ****
  final Task task;

  const ExpTaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
      return Container(
      margin: const EdgeInsets.only(bottom: 6.0), // 调整底部间距
      decoration: BoxDecoration(
        // 使用 task.style 获取颜色
        color: task.style.color.withSafeOpacity(0.08), // 背景透明度调整
        borderRadius: BorderRadius.circular(10), // 圆角调整
        border: Border.all(
          color: task.style.color.withSafeOpacity(0.25), // 边框透明度调整
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // 内边距调整
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 标题和计数 ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中对齐
            children: [
              // 任务标题 (内部已用 AppText)
              _buildTaskTitle(task.style, task.name, task.completed),
              // 计数 (使用 AppText)
              AppText(
                task.countText, // 使用 Task getter
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: task.style.color.withSafeOpacity(0.9), // 调整颜色透明度
              ),
            ],
          ),
          const SizedBox(height: 10), // 增加间距

          // --- 进度条 ---
          // 使用 Task getter 获取进度值
          _buildTaskProgressBar(task.style.color, task.progress),
          const SizedBox(height: 8), // 调整间距

          // --- 描述和每次任务经验值 ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中对齐
            children: [
              // 描述 (使用 AppText)
              Expanded( // 允许描述文本换行或省略
                child: AppText(
                  task.description, // 使用 Task 属性
                  type: AppTextType.caption, // 使用小字号类型
                  color: Colors.grey.shade700, // 调整颜色
                  fontSize: 12, // 明确字号
                  maxLines: 2, // 最多显示两行
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12), // 增加左右间距
              // 每次任务经验值 (使用 AppText)
              AppText(
                task.expPerTaskText, // 使用 Task getter
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: task.style.color, // 使用任务颜色
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建任务标题 (内部使用 AppText)
  Widget _buildTaskTitle(TaskStyle taskStyle, String name, bool completed) {
    return Flexible( // 使用 Flexible 防止标题过长导致溢出
      child: Row(
        mainAxisSize: MainAxisSize.min, // Row 只占用必要宽度
        children: [
          Icon(taskStyle.icon, size: 16, color: taskStyle.color),
          const SizedBox(width: 8),
          Flexible( // 文本也用 Flexible
            child: AppText( // **** 使用 AppText ****
              name,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              // **** 使用更清晰的方式设置颜色 ****
              color: completed ? Colors.grey.shade600 : Colors.black87,
              maxLines: 1, // 标题通常只显示一行
              overflow: TextOverflow.ellipsis, // 超长时省略
            ),
          ),
          if (completed)
            Padding(
              padding: const EdgeInsets.only(left: 6.0), // 调整图标间距
              child: Icon(
                Icons.check_circle_outline_rounded, // 换个图标试试
                color: Colors.green.shade500, // 调整颜色
                size: 15, // 调整大小
              ),
            ),
        ],
      ),
    );
  }

  // 构建任务进度条 (接收 double progress)
  Widget _buildTaskProgressBar(Color taskColor, double progress) {
    return Container( // 移除外层 Stack，通常不需要
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5), // 进度条圆角
        // 可以移除阴影，让卡片更简洁
        // boxShadow: [ ... ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: progress, // 使用传入的进度值 (0.0 - 1.0)
          backgroundColor: taskColor.withSafeOpacity(0.15), // 背景色用任务色的淡化
          valueColor: AlwaysStoppedAnimation<Color>(taskColor.withSafeOpacity(0.8)), // 进度条颜色也调整透明度
          minHeight: 7, // 进度条高度调整
        ),
      ),
    );
  }
}