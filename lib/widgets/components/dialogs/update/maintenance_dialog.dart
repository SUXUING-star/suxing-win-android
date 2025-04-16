// lib/widgets/dialogs/maintenance_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../services/main/maintenance/maintenance_service.dart';
import '../../../../../providers/auth/auth_provider.dart';


class MaintenanceDialog extends StatefulWidget {
  final bool canDismiss;

  const MaintenanceDialog({
    Key? key,
    this.canDismiss = false,
  }) : super(key: key);

  @override
  _MaintenanceDialogState createState() => _MaintenanceDialogState();

  // 静态方法，用于显示维护弹窗
  static void showMaintenanceDialog(BuildContext context, {bool canDismiss = false}) {
    showDialog(
      context: context,
      barrierDismissible: canDismiss,
      builder: (context) => MaintenanceDialog(canDismiss: canDismiss),
    );
  }
}

class _MaintenanceDialogState extends State<MaintenanceDialog> {
  Timer? _timer;
  int _remainingMinutes = 0;

  @override
  void initState() {
    super.initState();

    // 初始化剩余时间
    final maintenanceService = Provider.of<MaintenanceService>(context, listen: false);
    _remainingMinutes = maintenanceService.remainingMinutes;

    // 设置定时器，每分钟更新一次剩余时间
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _remainingMinutes = maintenanceService.remainingMinutes;
        });
      }
    });

    // 如果需要强制登出，处理登出逻辑
    if (maintenanceService.shouldForceLogout) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // 调用登出方法
      authProvider.signOut();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MaintenanceService>(
      builder: (context, maintenanceService, _) {
        final info = maintenanceService.maintenanceInfo;

        if (info == null) {
          return const AlertDialog(
            title: Text("系统维护"),
            content: Text("系统正在维护中，请稍后再试。"),
          );
        }

        // 根据维护类型设置不同的图标和颜色
        IconData iconData;
        Color iconColor;

        switch (info.maintenanceType) {
          case 'emergency':
            iconData = Icons.warning_amber_rounded;
            iconColor = Colors.red;
            break;
          case 'upgrade':
            iconData = Icons.system_update_alt;
            iconColor = Colors.blue;
            break;
          case 'scheduled':
          default:
            iconData = Icons.schedule;
            iconColor = Colors.orange;
            break;
        }

        return WillPopScope(
          onWillPop: () async => widget.canDismiss,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(iconData, color: iconColor, size: 28),
                const SizedBox(width: 8),
                const Text("系统维护通知"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  "预计维护结束时间: ${_formatDateTime(info.endTime)}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_remainingMinutes > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    "预计剩余时间: ${_formatRemainingTime(_remainingMinutes)}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            actions: [
              if (widget.canDismiss)
                TextButton(
                  onPressed: () => NavigationUtils.of(context).pop(),
                  child: const Text("稍后再试"),
                ),
              TextButton(
                onPressed: () async {
                  // 刷新维护状态
                  await maintenanceService.checkMaintenanceStatus();

                  // 如果不再处于维护状态，关闭对话框
                  if (!maintenanceService.isInMaintenance && mounted) {
                    NavigationUtils.of(context).pop();
                  } else {
                    // 否则更新剩余时间
                    setState(() {
                      _remainingMinutes = maintenanceService.remainingMinutes;
                    });
                  }
                },
                child: const Text("刷新状态"),
              ),
            ],
          ),
        );
      },
    );
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return DateTimeFormatter.formatStandard(dateTime);
  }

  // 格式化剩余时间
  String _formatRemainingTime(int minutes) {
    if (minutes < 60) {
      return "$minutes 分钟";
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return "$hours 小时 $remainingMinutes 分钟";
    }
  }

  // 将数字格式化为两位数
  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }
}