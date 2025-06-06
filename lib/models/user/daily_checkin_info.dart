// lib/models/user/daily_checkin_info.dart

/// 单日签到信息模型
class DailyCheckInInfo {
  final int day;
  final bool checkedIn;
  final int exp;

  DailyCheckInInfo({
    required this.day,
    required this.checkedIn,
    required this.exp,
  });

  factory DailyCheckInInfo.fromJson(Map<String, dynamic> json) {
    // 确保 'day' 字段能够处理字符串日期（例如 '2023-10-26'）
    int? parsedDay;
    if (json['day'] is int) {
      parsedDay = json['day'];
    } else if (json['day'] is String) {
      try {
        parsedDay = int.parse(
            json['day'].toString().split('-').last); // 尝试从 'YYYY-MM-DD' 中提取日期
      } catch (e) {
        // print('Error parsing day from string: ${json['day']} - $e');
      }
    }

    return DailyCheckInInfo(
      day: parsedDay ?? 0, // 默认值为 0 或根据需求设定
      checkedIn: json['checkedIn'] as bool? ?? false,
      exp: json['exp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'checkedIn': checkedIn,
      'exp': exp,
    };
  }
}
