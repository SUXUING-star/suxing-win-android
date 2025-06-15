// lib/models/maintenance/maintenance_info.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class MaintenanceInfo {
  final bool isActive;
  final DateTime startTime;
  final DateTime endTime;
  final String message;
  final bool allowLogin;
  final bool forceLogout;
  final String maintenanceType;

  const MaintenanceInfo({
    required this.isActive,
    required this.startTime,
    required this.endTime,
    required this.message,
    required this.allowLogin,
    required this.forceLogout,
    required this.maintenanceType,
  });

  factory MaintenanceInfo.fromJson(Map<String, dynamic> json) {
    return MaintenanceInfo(
      isActive: UtilJson.parseBoolSafely(json['is_active']),
      startTime: UtilJson.parseDateTime(json['start_time']),
      endTime: UtilJson.parseDateTime(json['end_time']),
      // 业务逻辑: 如果后端未提供 message，则使用预设的默认消息
      message: UtilJson.parseStringSafely(json['message'] ?? '系统正在维护中，请稍后再试。'),
      allowLogin: UtilJson.parseBoolSafely(json['allow_login']),
      forceLogout: UtilJson.parseBoolSafely(json['force_logout']),
      // 业务逻辑: 如果后端未提供维护类型，则默认为 'scheduled'
      maintenanceType:
          UtilJson.parseStringSafely(json['maintenance_type'] ?? 'scheduled'),
    );
  }

  static Map<String, dynamic> getMaintenanceVisuals(String maintenanceType) {
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

  static String getMaintenanceTitle(String maintenanceType) {
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

  static String formatRemainingTime(int minutes) {
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
