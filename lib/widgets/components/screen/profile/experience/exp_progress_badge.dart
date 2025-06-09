// lib/widgets/components/screen/profile/experience/exp_progress_badge.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/daily_progress.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'exp_badge_widget.dart';
import 'dialog/exp_dialog_content.dart';

class ExpProgressBadge extends StatelessWidget {
  // 改成 StatelessWidget，因为它不再管理自己的状态了
  final User currentUser;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isDesktop;

  final DailyProgressData? dailyProgressData;
  final bool isLoadingExpData;
  final String? expDataError;
  final VoidCallback onRefreshExpData; // 用于重试和弹窗关闭时刷新

  const ExpProgressBadge({
    super.key,
    required this.currentUser,
    this.size = 24.0,
    this.backgroundColor,
    this.textColor,
    this.isDesktop = false,
    // **** 新增：必传的数据和回调 ****
    required this.dailyProgressData,
    required this.isLoadingExpData,
    this.expDataError,
    required this.onRefreshExpData,
  });

  void _showProgressDialog(BuildContext context) {
    // 确保进度数据已加载 (从 widget 属性获取)
    if (dailyProgressData == null) return;

    final User userToShow = currentUser;
    // 从 dailyProgressData 获取 tasks 和 todayProgress
    final List<Task> tasks = dailyProgressData!.tasks;
    final TodayProgressSummary todayProgress = dailyProgressData!.todayProgress;

    // Dialog 关闭时的刷新逻辑 (使用 onRefreshExpData)
    void refreshCallback() {
      onRefreshExpData();
    }

    BaseInputDialog.show<void>(
      context: context,
      title: '今日经验进度',
      iconData: Icons.stars,
      contentBuilder: (dialogContext) {
        return ExpDialogContent(
          todayProgress: todayProgress,
          tasks: tasks,
          currentUser: userToShow,
          isDesktop: isDesktop,
        );
      },
      confirmButtonText: '关闭',
      showCancelButton: false,
      onConfirm: () async {
        refreshCallback();
      },
      onCancel: refreshCallback, // 点击背景关闭时也刷新
      isDraggable: true,
      isScalable: false,
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: size,
      height: size,
      child: LoadingWidget(size: size * 0.6),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingExpData) {
      return _buildLoadingIndicator();
    }

    if (expDataError != null || dailyProgressData == null) {
      return InkWell(
        onTap: onRefreshExpData, // 点击重试
        child: Tooltip(
          message: expDataError ?? "加载失败，点击重试",
          child: Icon(
            Icons.error_outline,
            color: Colors.red.shade300,
            size: size,
          ),
        ),
      );
    }

    final earnedToday = dailyProgressData!.todayProgress.earnedToday;
    final completionPercentage =
        dailyProgressData!.todayProgress.completionPercentage;

    return ExpBadgeWidget(
      size: size,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      textColor: textColor ?? Colors.white,
      earnedToday: earnedToday,
      completionPercentage: completionPercentage,
      onTap: () => _showProgressDialog(context),
    );
  }
}
