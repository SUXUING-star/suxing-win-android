// lib/widgets/components/screen/maintenance/maintenance_display.dart (新文件)
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/maintenance/maintenance_info.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 确认引入

class MaintenanceDisplay extends StatelessWidget {
  final MaintenanceInfo? maintenanceInfo;
  final int remainingMinutes;

  const MaintenanceDisplay({
    super.key,
    required this.maintenanceInfo,
    required this.remainingMinutes,
  });

  @override
  Widget build(BuildContext context) {
    // 如果 info 为 null，显示通用维护信息或加载状态
    if (maintenanceInfo == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.amber),
              SizedBox(height: 16),
              Text('系统维护中', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('正在获取详细信息，请稍候...', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // 有 info，构建详细维护界面
    final visuals = _getMaintenanceVisuals(maintenanceInfo!.maintenanceType);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(visuals['icon'], size: 64, color: visuals['color']),
            const SizedBox(height: 20),
            Text(
              _getMaintenanceTitle(maintenanceInfo!.maintenanceType),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              maintenanceInfo!.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _buildTimeInfo(context, "预计结束时间:", DateTimeFormatter.formatStandard(maintenanceInfo!.endTime)),
            if (remainingMinutes > 0) ...[
              const SizedBox(height: 8),
              _buildTimeInfo(context, "预计剩余时间:", _formatRemainingTime(remainingMinutes)),
            ],
            const SizedBox(height: 30),
            Text(
              "给您带来不便，敬请谅解。",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // --- 辅助方法 (从 Wrapper 移过来) ---
  Map<String, dynamic> _getMaintenanceVisuals(String maintenanceType) {
    switch (maintenanceType) {
      case 'emergency':
        return {'icon': Icons.warning_amber_rounded, 'color': Colors.red};
      case 'upgrade':
        return {'icon': Icons.system_update_alt, 'color': Colors.blue};
      case 'scheduled':
      default:
        return {'icon': Icons.schedule, 'color': Colors.orange};
    }
  }

  String _getMaintenanceTitle(String maintenanceType) {
    switch (maintenanceType) {
      case 'emergency':
        return '系统紧急维护中';
      case 'upgrade':
        return '系统升级维护中';
      case 'scheduled':
      default:
        return '系统维护中';
    }
  }

  Widget _buildTimeInfo(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  String _formatRemainingTime(int minutes) {
    if (minutes <= 0) return "即将结束";
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