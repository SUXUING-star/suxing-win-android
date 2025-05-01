// lib/widgets/components/screen/profile/experience/exp_progress_badge.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../../../services/main/user/user_service.dart';
import 'exp_badge_widget.dart';
import 'dialog/exp_dialog_content.dart';

// 主组件：经验值进度徽章
class ExpProgressBadge extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isDesktop;

  const ExpProgressBadge({
    super.key,
    this.size = 24.0,
    this.backgroundColor,
    this.textColor,
    this.isDesktop = false,
  });

  @override
  State<ExpProgressBadge> createState() => _ExpProgressBadgeState();
}

class _ExpProgressBadgeState extends State<ExpProgressBadge> {
  Map<String, dynamic>? _progressData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final userService = context.read<UserService>();

      final data = await userService.getDailyExperienceProgressWithCache();

      if (mounted) {
        setState(() {
          _progressData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
      return _buildErrorIndicator();
    }

    // 提取进度值
    final earnedToday = (_progressData!['todayProgress']['earnedToday'] as num).toInt();
    final completionPercentage = (_progressData!['todayProgress']['completionPercentage'] as num).toDouble();

    return ExpBadgeWidget(
      size: widget.size,
      backgroundColor: widget.backgroundColor ?? Theme.of(context).primaryColor,
      textColor: widget.textColor ?? Colors.white,
      earnedToday: earnedToday,
      completionPercentage: completionPercentage,
      onTap: () => _showProgressDialog(context),
    );
  }

  // 加载中指示器
  Widget _buildLoadingIndicator() {
    return LoadingWidget.inline();
  }

  // 错误指示器
  Widget _buildErrorIndicator() {
    return InlineErrorWidget();
  }

  // 显示经验值进度详情对话框
  void _showProgressDialog(BuildContext context) {
    if (_progressData == null) return;

    // 获取任务列表并更新经验值
    final List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(_progressData!['tasks']);
    _updateTaskExpValues(tasks);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.stars, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              '今日经验进度',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: ExpDialogContent(
          progressData: _progressData!,
          tasks: tasks,
          isDesktop: widget.isDesktop,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _loadProgressData(); // 关闭时刷新数据
              Navigator.of(context).pop();
            },
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 更新任务经验值
  void _updateTaskExpValues(List<Map<String, dynamic>> tasks) {
    for (var task in tasks) {
      final type = task['type'];

      // 根据任务类型设置经验值
      switch (type) {
        case 'checkin': // 签到
          task['expPerTask'] = 15;
          break;
        case 'post': // 发帖
          task['expPerTask'] = 10;
          break;
        default: // 其他所有任务类型（回复、点赞、关注、收藏、评论等）
          task['expPerTask'] = 5;
      }
    }
  }
}