// lib/widgets/components/screen/profile/experience/exp_progress_badge.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// **** 导入模型和 Service ****
import 'package:suxingchahui/models/user/daily_progress.dart';
import 'package:suxingchahui/models/user/user.dart'; // **** 导入 User 模型 ****
import 'package:suxingchahui/services/main/user/user_service.dart';
// **** 导入 UI 组件 ****
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'exp_badge_widget.dart';
import 'dialog/exp_dialog_content.dart';

class ExpProgressBadge extends StatefulWidget {
  // **** 接收 User 对象 ****
  final User currentUser;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isDesktop;

  const ExpProgressBadge({
    super.key,
    required this.currentUser, // **** 必须传入 User ****
    this.size = 24.0,
    this.backgroundColor,
    this.textColor,
    this.isDesktop = false,
  });

  @override
  State<ExpProgressBadge> createState() => _ExpProgressBadgeState();
}

class _ExpProgressBadgeState extends State<ExpProgressBadge> {
  DailyProgressData? _progressData;
  bool _isLoading = true;
  String? _error;
  // **** 彻底删除 _currentUser 和 _isDialogLoading 状态 ****

  @override
  void initState() {
    super.initState();
    _loadProgressData(); // 初始只加载进度数据
  }

  // 只加载每日进度数据
  Future<void> _loadProgressData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userService = context.read<UserService>();
      final data = await userService.getDailyExperienceProgress();

      if (mounted) {
        setState(() {
          _progressData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "加载失败";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_error != null || _progressData == null) {
      return InkWell(
        onTap: _loadProgressData,
        child: Tooltip(
          message: _error ?? "加载失败，点击重试",
          child: Icon(
            Icons.error_outline,
            color: Colors.red.shade300,
            size: widget.size,
          ),
        ),
      );
    }

    final earnedToday = _progressData!.todayProgress.earnedToday;
    final completionPercentage = _progressData!.todayProgress.completionPercentage;

    return ExpBadgeWidget(
      size: widget.size,
      backgroundColor: widget.backgroundColor ?? Theme.of(context).primaryColor,
      textColor: widget.textColor ?? Colors.white,
      earnedToday: earnedToday,
      completionPercentage: completionPercentage,
      // **** 点击时直接调用 _showProgressDialog ****
      onTap: () => _showProgressDialog(context),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: LoadingWidget.inline(size: widget.size * 0.6),
    );
  }

  // **** 彻底删除 _handleTap 方法 ****

  // 显示经验值进度详情对话框
  void _showProgressDialog(BuildContext context) {
    // 确保进度数据已加载
    if (_progressData == null) return;

    // **** User 对象直接从 widget.currentUser 获取 ****
    final User userToShow = widget.currentUser;
    final List<Task> tasks = _progressData!.tasks;
    final TodayProgressSummary todayProgress = _progressData!.todayProgress;

    // Dialog 关闭时的刷新逻辑 (只刷新进度)
    void refreshProgressCallback() {
      if(mounted) { // 检查 Mouted 状态
        _loadProgressData();
      }
    }

    BaseInputDialog.show<void>(
      context: context,
      title: '今日经验进度',
      iconData: Icons.stars,
      contentBuilder: (dialogContext) {
        // **** 直接传递 widget.currentUser 给 ExpDialogContent ****
        return ExpDialogContent(
          todayProgress: todayProgress,
          tasks: tasks,
          currentUser: userToShow, // **** 使用 widget.currentUser ****
          isDesktop: widget.isDesktop,
        );
      },
      confirmButtonText: '关闭',
      showCancelButton: false,
      // 关闭时刷新进度数据
      onConfirm: () async { // onConfirm 是 Future，保持 async
        refreshProgressCallback();
      },
      onCancel: refreshProgressCallback, // 点击背景关闭时也刷新
      isDraggable: true,
      isScalable: false,
    );
  }
}