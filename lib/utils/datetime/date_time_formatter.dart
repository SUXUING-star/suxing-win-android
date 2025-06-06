// lib/utils/datetime/date_time_formatter.dart
import 'package:intl/intl.dart';

class DateTimeFormatter {
  /// 常量：北京时区偏移（UTC+8）
  static const Duration beijingOffset = Duration(hours: 8);

  /// 将DateTime转换为北京时间
  static DateTime toBeijingTime(DateTime dateTime) {
    // 如果已经是本地时间，则转换为UTC
    if (dateTime.isUtc == false) {
      dateTime = dateTime.toUtc();
    }

    // 转为北京时间 (UTC+8)
    return dateTime.add(beijingOffset);
  }

  /// 格式化为标准日期时间： YYYY-MM-DD HH:MM
  static String formatStandard(DateTime dateTime) {
    final DateTime beijingTime = toBeijingTime(dateTime);

    return '${beijingTime.year}-${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')} '
        '${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化为年月日： YYYY-MM-DD
  static String formatNormal(DateTime dateTime) {
    final DateTime beijingTime = toBeijingTime(dateTime);

    return '${beijingTime.year}-${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')}';
  }

  /// 格式化为简短日期时间： MM-DD HH:MM
  static String formatShort(DateTime dateTime) {
    final DateTime beijingTime = toBeijingTime(dateTime);

    return '${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')} '
        '${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化为相对时间 (今天、昨天、前天，或日期)
  static String formatRelative(DateTime dateTime) {
    final DateTime beijingTime = toBeijingTime(dateTime);
    final DateTime now = toBeijingTime(DateTime.now());

    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime yesterdayStart =
        todayStart.subtract(const Duration(days: 1));
    final DateTime beforeYesterdayStart =
        todayStart.subtract(const Duration(days: 2));

    if (beijingTime.isAfter(todayStart)) {
      return '今天 ${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
    } else if (beijingTime.isAfter(yesterdayStart)) {
      return '昨天 ${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
    } else if (beijingTime.isAfter(beforeYesterdayStart)) {
      return '前天 ${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
    } else if (beijingTime.year == now.year) {
      // 同年显示月日
      return '${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')} '
          '${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
    } else {
      // 不同年显示年月日
      return '${beijingTime.year}-${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')} '
          '${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化友好格式，最近返回回D天前/M月前
  /// 若超过40天则返回 YYYY-MM-DD
  static String formatTimeAgo(DateTime dateTime) {
    // 使用设备的当前本地时间
    final now = DateTime.now();
    // 计算本地时间差
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      // 小于1分钟
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      // 小于1小时
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      // 小于1天
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      // 小于7天
      return '${difference.inDays}天前';
    } else if (difference.inDays < 14) {
      // 小于14天
      return '一周前';
    } else if (difference.inDays < 20) {
      // 小于20天
      return '两周前';
    } else if (difference.inDays < 40) {
      // 小于40天
      return '一个月前';
    } else {
      // 超过40天返回年月日一般格式
      return formatNormal(dateTime);
    }
  }

  /// 格式化为自定义格式 (使用intl包的DateFormat)
  static String formatCustom(DateTime dateTime, String pattern) {
    final DateTime beijingTime = toBeijingTime(dateTime);
    final DateFormat formatter = DateFormat(pattern);
    return formatter.format(beijingTime);
  }
}
