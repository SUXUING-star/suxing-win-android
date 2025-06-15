// lib/widgets/ui/components/maintenance_display.dart
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
    final visuals = MaintenanceInfo.getMaintenanceVisuals(maintenanceInfo!.maintenanceType);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(visuals['icon'], size: 64, color: visuals['color']),
            const SizedBox(height: 20),
            Text(
              MaintenanceInfo.getMaintenanceTitle(maintenanceInfo!.maintenanceType),
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
              _buildTimeInfo(context, "预计剩余时间:",MaintenanceInfo.formatRemainingTime(remainingMinutes)),
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


}