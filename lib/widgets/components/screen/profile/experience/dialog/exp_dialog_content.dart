// lib/widgets/components/screen/profile/experience/dialog/exp_dialog_content.dart

import 'package:flutter/material.dart';
// **** 导入模型 ****
import 'package:suxingchahui/models/user/daily_progress.dart';
import 'package:suxingchahui/models/user/user.dart'; // 导入 User 模型
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
// **** 导入 UI 组件 ****
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';
import '../card/exp_task_card.dart'; // 导入 ExpTaskCard

class ExpDialogContent extends StatelessWidget {
  final TodayProgressSummary todayProgress;
  final List<Task> tasks;
  final User currentUser;
  final bool isDesktop;

  const ExpDialogContent({
    super.key,
    required this.todayProgress,
    required this.tasks,
    required this.currentUser, // **** 接收 User 对象 ****
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    // **** 不再需要前端计算等级，直接使用 User 对象里的数据 ****
    // final UserLevelDetails levelInfo = getUserLevelInfo(totalExperience); // 删除！

    return SingleChildScrollView(
      // **** 增加内边距，让内容不贴边 ****
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 高度自适应
        crossAxisAlignment: CrossAxisAlignment.stretch, // 子项宽度撑满
        children: [
          // **** 显示等级信息，直接从 currentUser 获取 ****
          _buildLevelInfo(context, currentUser),
          const SizedBox(height: 16), // 增加模块间距

          // 显示今日汇总信息
          _buildSummary(context),
          const SizedBox(height: 20),

          // 任务列表标题
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 10.0), // 调整边距
            child: AppText(
              '今日任务:',
              type: AppTextType.title,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          // 任务列表
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0), // 上下多留白
              child: Center(
                child: AppText(
                  '今日暂无任务',
                  type: AppTextType.secondary,
                ),
              ),
            )
          else
          // 用 Column 渲染任务卡片
            Column(
              // ExpTaskCard 内部已确保使用 AppText
              children: tasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0), // 给卡片之间加点间距
                  child: ExpTaskCard(task: task)
              )).toList(),
            ),
        ],
      ),
    );
  }

  // 构建等级信息显示区域 (接收 User 对象)
  Widget _buildLevelInfo(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withSafeOpacity(0.03), // 加点淡背景色
        borderRadius: BorderRadius.circular(10), // 圆角更大
        border: Border.all(color: Colors.deepPurple.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // 让进度条撑满
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center, // 中心对齐更好看
            // textBaseline: TextBaseline.alphabetic,
            children: [
              // 等级和总经验
              Column( // 用 Column 组合等级和经验
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Lv. ${user.level}', // 使用 user.level
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700, // 深一点的紫色
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    '总经验: ${user.experience}', // 使用 user.experience
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    type: AppTextType.caption, // 用小字号类型
                  ),
                ],
              ),
              // 升级提示
              if (!user.isMaxLevel) // 只有未满级时显示
                AppText(
                  '还差 ${user.expToNextLevel} EXP 升级', // 使用 user.expToNextLevel
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  type: AppTextType.caption,
                )
              else // 满级时显示
                AppText(
                  '已满级',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade800, // 满级用橙色
                  type: AppTextType.caption,
                ),
            ],
          ),
          const SizedBox(height: 10), // 增加间距
          // 等级进度条
          Tooltip( // 给进度条加上 Tooltip
            message: '当前等级进度: ${user.levelProgress.toStringAsFixed(1)}%',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5), // 进度条圆角
              child: LinearProgressIndicator(
                value: user.levelProgress / 100.0, // 使用 user.levelProgress
                backgroundColor: Colors.deepPurple.shade100.withSafeOpacity(0.5), // 背景更淡
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade400), // 进度条颜色
                minHeight: 8, // 进度条加高一点
              ),
            ),
          ),
        ],
      ),
    );
  }


  // 构建汇总信息的小部件
  Widget _buildSummary(BuildContext context) {
    final progressPercent = todayProgress.completionPercentage.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // 调整内边距
      decoration: BoxDecoration(
        color: Colors.lightBlue.withSafeOpacity(0.05), // 更淡的背景
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.lightBlue.shade100, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // 保持均分
        children: [
          _buildSummaryItem('今日已获', '${todayProgress.earnedToday} EXP', Colors.lightBlue.shade800),
          _buildSummaryItem('今日上限', '${todayProgress.possibleToday} EXP', Colors.grey.shade700), // 上限用灰色
          _buildSummaryItem('完成度', '$progressPercent%', Colors.green.shade700),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    // 使用 Expanded 让每个 item 均分宽度，并居中对齐
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // 文字居中
        children: [
          AppText(
            value,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor,
          ),
          const SizedBox(height: 4),
          AppText(
            label,
            fontSize: 11,
            type: AppTextType.caption, // 使用小字号类型
            color: Colors.grey.shade800, // 标签颜色深一点
          ),
        ],
      ),
    );
  }
}