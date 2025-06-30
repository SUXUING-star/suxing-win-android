// lib/models/maintenance/maintenance_info.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class MaintenanceInfo {
  static const String upgradeType = 'upgrade';
  static const String emergencyType = 'emergency';
  static const String scheduledType = 'scheduled';

  static const List<String> maintenanceTypes = [
    upgradeType,
    emergencyType,
    scheduledType,
  ];

  static const jsonKeyIsActive = 'isActive';
  static const jsonKeyStartTime = 'startTime';
  static const jsonKeyEndTime = 'endTime';
  static const jsonKeyMessage = 'message';
  static const jsonKeyAllowLogin = 'allowLogin';
  static const jsonKeyForceLogout = 'forceLogout';
  static const jsonKeyType = 'maintenanceType';

  final bool isActive;
  final DateTime startTime;
  final DateTime endTime;
  final String message;
  final bool allowLogin;
  final bool forceLogout;
  final String type;
  IconData iconData;
  Color iconColor;
  String label;

  MaintenanceInfo({
    required this.isActive,
    required this.startTime,
    required this.endTime,
    required this.message,
    required this.allowLogin,
    required this.forceLogout,
    required this.type,
  })  : iconData = getMaintenanceIcon(type),
        iconColor = getMaintenanceIconColor(type),
        label = getMaintenanceTitle(type);

  factory MaintenanceInfo.fromJson(Map<String, dynamic> json) {
    return MaintenanceInfo(
      isActive: UtilJson.parseBoolSafely(json[jsonKeyIsActive]),
      startTime: UtilJson.parseDateTime(json[jsonKeyStartTime]),
      endTime: UtilJson.parseDateTime(json[jsonKeyEndTime]),
      // 业务逻辑: 如果后端未提供 message，则使用预设的默认消息
      message:
          UtilJson.parseStringSafely(json[jsonKeyMessage] ?? '系统正在维护中，请稍后再试。'),
      allowLogin: UtilJson.parseBoolSafely(json[jsonKeyAllowLogin]),
      forceLogout: UtilJson.parseBoolSafely(json[jsonKeyForceLogout]),
      // 业务逻辑: 如果后端未提供维护类型，则默认为 'scheduled'
      type: UtilJson.parseStringSafely(json[jsonKeyType] ?? scheduledType),
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      jsonKeyIsActive: isActive,
      jsonKeyStartTime: startTime.toIso8601String(),
      jsonKeyEndTime: endTime.toIso8601String(),
      jsonKeyMessage: message,
      jsonKeyAllowLogin: allowLogin,
      jsonKeyForceLogout: forceLogout,
      jsonKeyType: type,
    };
  }

  static IconData getMaintenanceIcon(String type) {
    switch (type) {
      case emergencyType:
        return Icons.warning_amber_rounded;
      case upgradeType:
        return Icons.system_update_alt;
      case scheduledType:
      default:
        return Icons.schedule;
    }
  }

  static Color getMaintenanceIconColor(String type) {
    switch (type) {
      case emergencyType:
        return Colors.red;
      case upgradeType:
        return Colors.blue;
      case scheduledType:
      default:
        return Colors.orange;
    }
  }

  static String getMaintenanceTitle(String type) {
    switch (type) {
      case emergencyType:
        return '系统紧急维护中';
      case upgradeType:
        return '系统升级维护中';
      case scheduledType:
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
