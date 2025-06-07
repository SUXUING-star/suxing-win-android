// lib/utils/datetime/date_time_formatter.dart

/// 该文件定义了 DateTimeFormatter 工具类，提供日期时间格式化功能。
/// 该类用于将日期时间转换为特定时区并按不同格式输出。

import 'package:intl/intl.dart'; // 导入 intl 包，用于自定义日期时间格式化

/// `DateTimeFormatter` 类：提供日期时间格式化实用方法。
///
/// 该类包含将日期时间转换为北京时间，并按多种预定义和自定义格式输出的方法。
class DateTimeFormatter {
  /// 北京时区偏移常量（UTC+8）。
  static const Duration beijingOffset = Duration(hours: 8);

  /// 将 DateTime 转换为北京时间。
  ///
  /// [dateTime]：要转换的日期时间。
  /// 返回已转换为北京时区的 DateTime 实例。
  static DateTime toBeijingTime(DateTime dateTime) {
    if (dateTime.isUtc == false) {
      dateTime = dateTime.toUtc(); // 非 UTC 时间转换为 UTC
    }
    return dateTime.add(beijingOffset); // 增加北京时间偏移
  }

  /// 格式化为标准日期时间格式：YYYY-MM-DD HH:MM。
  ///
  /// [dateTime]：要格式化的日期时间。
  /// 返回格式化后的字符串。
  static String formatStandard(DateTime dateTime) {
    final DateTime beijingTime = toBeijingTime(dateTime); // 转换为北京时间

    return '${beijingTime.year}-${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')} '
        '${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化为年月日格式：YYYY-MM-DD。
  ///
  /// [dateTime]：要格式化的日期时间。
  /// 返回格式化后的字符串。
  static String formatNormal(DateTime dateTime) {
    final DateTime beijingTime = toBeijingTime(dateTime); // 转换为北京时间

    return '${beijingTime.year}-${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')}';
  }

  /// 格式化为简短日期时间格式：MM-DD HH:MM。
  ///
  /// [dateTime]：要格式化的日期时间。
  /// 返回格式化后的字符串。
  static String formatShort(DateTime dateTime) {
    final DateTime beijingTime = toBeijingTime(dateTime); // 转换为北京时间

    return '${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')} '
        '${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化为相对时间。
  ///
  /// [dateTime]：要格式化的日期时间。
  /// 返回“今天”、“昨天”、“前天”或标准日期时间格式的字符串。
  static String formatRelative(DateTime dateTime) {
    final DateTime beijingTime = toBeijingTime(dateTime); // 转换为北京时间
    final DateTime now = toBeijingTime(DateTime.now()); // 获取当前北京时间

    final DateTime todayStart =
        DateTime(now.year, now.month, now.day); // 今天开始时间
    final DateTime yesterdayStart =
        todayStart.subtract(const Duration(days: 1)); // 昨天开始时间
    final DateTime beforeYesterdayStart =
        todayStart.subtract(const Duration(days: 2)); // 前天开始时间

    if (beijingTime.isAfter(todayStart)) {
      return '今天 ${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
    } else if (beijingTime.isAfter(yesterdayStart)) {
      return '昨天 ${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
    } else if (beijingTime.isAfter(beforeYesterdayStart)) {
      return '前天 ${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
    } else if (beijingTime.year == now.year) {
      return '${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')} '
          '${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${beijingTime.year}-${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')} '
          '${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化为友好时间，如“刚刚”、“X分钟前”、“X天前”。
  ///
  /// [dateTime]：要格式化的日期时间。
  /// 超过 40 天时返回 YYYY-MM-DD 格式。
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now(); // 获取当前本地时间
    final difference = now.difference(dateTime); // 计算时间差

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 14) {
      return '一周前';
    } else if (difference.inDays < 20) {
      return '两周前';
    } else if (difference.inDays < 40) {
      return '一个月前';
    } else {
      return formatNormal(dateTime); // 超过 40 天返回标准年月日格式
    }
  }

  /// 格式化为自定义模式的日期时间。
  ///
  /// [dateTime]：要格式化的日期时间。
  /// [pattern]：自定义格式模式字符串。
  /// 返回格式化后的字符串。
  static String formatCustom(DateTime dateTime, String pattern) {
    final DateTime beijingTime = toBeijingTime(dateTime); // 转换为北京时间
    final DateFormat formatter = DateFormat(pattern); // 创建格式化器
    return formatter.format(beijingTime); // 返回格式化后的字符串
  }
}
