class MaintenanceInfo {
  final bool isActive;
  final DateTime startTime;
  final DateTime endTime;
  final String message;
  final bool allowLogin;
  final bool forceLogout;
  final String maintenanceType;

  MaintenanceInfo({
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
      isActive: json['is_active'] ?? false,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now().add(const Duration(hours: 1)),
      message: json['message'] ?? '系统正在维护中，请稍后再试。',
      allowLogin: json['allow_login'] ?? false,
      forceLogout: json['force_logout'] ?? false,
      maintenanceType: json['maintenance_type'] ?? 'scheduled',
    );
  }
}
