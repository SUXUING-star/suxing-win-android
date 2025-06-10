// lib/widgets/dialogs/maintenance_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/maintenance/maintenance_info.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';
import 'package:suxingchahui/services/main/maintenance/maintenance_service.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

// MaintenanceDialog 现在可以只是一个包含静态方法的类，不需要是 Widget
class MaintenanceDialog {
  // 私有构造函数防止实例化
  MaintenanceDialog._();

  // 静态方法，用于显示维护弹窗
  // 返回 Future<void>，因为 BaseInputDialog.show 返回 Future
  static Future<void> showMaintenanceDialog(
      BuildContext context, MaintenanceService maintenanceService,
      {bool canDismiss = false}) {
    final info = maintenanceService.maintenanceInfo;

    // --- 1. 处理 info 为 null 的情况 ---
    if (info == null) {
      return Future.value();
    }

    // --- 2. 确定图标和颜色 ---
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

    // --- 3. 调用 BaseInputDialog.show ---
    return BaseInputDialog.show<void>(
      // 使用 void 因为我们不关心返回值
      context: context,
      title: "系统维护通知",
      iconData: iconData,
      iconColor: iconColor,
      barrierDismissible: canDismiss, // 控制点击背景是否关闭
      allowDismissWhenNotProcessing: canDismiss, // 控制物理返回键/手势是否关闭
      showCancelButton: canDismiss, // 只有可关闭时才显示取消按钮
      cancelButtonText: "知道了", // 取消按钮文本
      confirmButtonText: "刷新状态", // 确认按钮文本
      isDraggable: false, // 通常维护通知不需要拖拽
      isScalable: false, // 通常维护通知不需要缩放

      // --- 4. 构建对话框内容 ---
      contentBuilder: (dialogContext) {
        return StreamBuilder<MaintenanceInfo?>(
          stream: maintenanceService.maintenanceInfoStream,
          initialData: maintenanceService.maintenanceInfo,
          builder: (context, maintenanceSnapshot) {
            final currentInfo = maintenanceService.maintenanceInfo;
            final remainingMinutes = maintenanceService.remainingMinutes;

            // 如果在对话框显示期间 info 变为 null (例如刷新失败?)
            if (currentInfo == null) {
              return const AppText("无法获取维护信息。", textAlign: TextAlign.center);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              // 让文本默认左对齐，更符合阅读习惯
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  currentInfo.message,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                  textAlign: TextAlign.left, // 明确左对齐
                ),
                const SizedBox(height: 16),
                AppText(
                  "预计维护结束时间: ${DateTimeFormatter.formatStandard(currentInfo.endTime)}",
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                  textAlign: TextAlign.left, // 明确左对齐
                ),
                if (remainingMinutes > 0) ...[
                  const SizedBox(height: 8),
                  AppText(
                    "预计剩余时间: ${_formatRemainingTimeStatic(remainingMinutes)}",
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                    textAlign: TextAlign.left, // 明确左对齐
                  ),
                ],
              ],
            );
          },
        );
      },

      // --- 5. 定义确认操作 (刷新状态) ---
      onConfirm: () async {
        try {
          await maintenanceService.checkMaintenanceStatus();
        } catch (e) {
          AppSnackBar.showError("操作失败,${e.toString()}");
          // 重新抛出错误，让 BaseInputDialog 的 Future 失败
          rethrow;
        }
        // 注意：BaseInputDialog 的 finally 块会执行 Navigator.pop
      },

      // --- 6. 定义取消操作 ---
      onCancel: () {
        // 如果 canDismiss 为 true，点击“知道了”按钮时会调用这里。
        // BaseInputDialog 会自动处理关闭逻辑，所以这里通常不需要做额外操作。
        // print("MaintenanceDialog: '知道了' clicked.");
      },
    );
  }

  // --- 7. 辅助函数改为静态 ---
  static String _formatRemainingTimeStatic(int minutes) {
    if (minutes < 0) return "时间未知"; // 处理负数情况
    if (minutes < 60) {
      return "$minutes 分钟";
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return "$hours 小时";
      }
      return "$hours 小时 $remainingMinutes 分钟";
    }
  }
}
