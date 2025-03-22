// lib/widgets/components/screen/profile/experience/exp_dialog_content.dart

import 'package:flutter/material.dart';
import '../../../../../../../../utils/font/font_config.dart';
import '../card/exp_total_card.dart';
import '../card/exp_today_progress_card.dart';
import '../card/exp_task_card.dart';

class ExpDialogContent extends StatelessWidget {
  final Map<String, dynamic> progressData;
  final List<Map<String, dynamic>> tasks;
  final bool isDesktop;

  const ExpDialogContent({
    Key? key,
    required this.progressData,
    required this.tasks,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 提取数据
    final totalExp = progressData['totalExperience'];
    final earnedToday = progressData['todayProgress']['earnedToday'];
    final possibleToday = progressData['todayProgress']['possibleToday'];
    final remainingToday = progressData['todayProgress']['remainingToday'];
    final completionPercentage = progressData['todayProgress']['completionPercentage'];

    return Container(
      width: double.maxFinite,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        maxWidth: isDesktop ? 400 : 300,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          // 总经验值卡片
          ExpTotalCard(totalExp: totalExp),

          SizedBox(height: 16),

          // 今日进度
          ExpTodayProgressCard(
            earnedToday: earnedToday,
            possibleToday: possibleToday,
            remainingToday: remainingToday,
            completionPercentage: completionPercentage,
          ),

          SizedBox(height: 16),

          // 任务列表标题
          _buildTaskListTitle(),

          // 任务卡片列表
          ...tasks.map((task) => ExpTaskCard(task: task)).toList(),
        ],
      ),
    );
  }

  // 任务列表标题
  Widget _buildTaskListTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        '任务列表',
        style: TextStyle(
          fontFamily: FontConfig.defaultFontFamily,
          fontFamilyFallback: FontConfig.fontFallback,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}