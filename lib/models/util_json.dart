// lib/models/util_json.dart
// 安全解析 DateTime
import 'package:mongo_dart/mongo_dart.dart';
import 'package:suxingchahui/models/game/game.dart';

class UtilJson {
  // 解析ID字段，处理 ObjectId 和普通字符串
  static String parseId(dynamic idValue) {
    if (idValue == null) return '';
    return idValue is ObjectId ? idValue.oid : idValue.toString();
  }

  // 安全解析可空 ID 字段
  static String? parseNullableId(dynamic idValue) {
    if (idValue == null) return null;
    final parsed = parseId(idValue); // parseId 已经处理了 ObjectId 和字符串
    return parsed.isEmpty ? null : parsed; // 如果 parseId 返回空字符串，则视作 null
  }

  static DateTime parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true); // 默认值
    }
    if (dateValue is DateTime) return dateValue;
    if (dateValue is Timestamp) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue.seconds * 1000,
          isUtc: true);
    }
    try {
      return DateTime.parse(dateValue.toString()).toLocal(); // 解析为本地时间
    } catch (e) {
      final millis = int.tryParse(dateValue.toString());
      if (millis != null) {
        return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true)
            .toLocal(); // 解析毫秒为本地时间
      }
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true); // 错误回退
    }
  }

  // 安全解析可空 DateTime
  static DateTime? parseNullableDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      // Go的time.Time零值处理为null
      if (dateValue is String &&
          (dateValue == "0001-01-01T00:00:00Z" ||
              dateValue.startsWith("0001-01-01"))) {
        return null;
      }
      return parseDateTime(dateValue);
    } catch (_) {
      return null;
    }
  }

  // 安全解析 int
  static int parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  // 安全解析可空 int
  static int? parseNullableIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  // 安全解析 double
  static double parseDoubleSafely(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // 安全解析可空 double
  static double? parseNullableDoubleSafely(dynamic value) {
    if (value == null) return null; // 如果是null，就直接返回null
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()); // 尝试解析，解析失败也返回null
  }

  // 解析标签列表
  static List<String> parseListString(dynamic list) {
    if (list == null) return [];
    if (list is List) {
      return list.map((item) => item.toString()).toList();
    }
    if (list is String) {
      return list.split(',').map((item) => item.trim()).toList();
    }
    return [];
  }

  // 安全解析 String
  static String parseStringSafely(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // 安全解析 String
  static String? parseNullableStringSafely(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  // 解析下载链接列表
  static List<GameDownloadLink> parseGameDownloadLinks(dynamic links) {
    if (links == null || links is! List) return [];
    return links
        .map((link) => link is Map<String, dynamic>
            ? GameDownloadLink.fromJson(link)
            : null)
        .whereType<GameDownloadLink>()
        .toList();
  }

  // 解析下载链接列表
  static List<GameExternalLink> parseGameExternalLinks(dynamic links) {
    if (links == null || links is! List) return [];
    return links
        .map((link) => link is Map<String, dynamic>
            ? GameExternalLink.fromJson(link)
            : null)
        .whereType<GameExternalLink>()
        .toList();
  }

  // 安全解析 bool
  static bool parseBoolSafely(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lowerCase = value.toLowerCase();
      if (lowerCase == 'true' || lowerCase == '1') return true;
      if (lowerCase == 'false' || lowerCase == '0') return false;
    }
    return defaultValue;
  }

  // 解析 DateTime 列表
  static List<DateTime> parseListDateTime(dynamic list) {
    if (list == null) return [];
    if (list is List) {
      return list
          .map((item) => parseNullableDateTime(item))
          .whereType<DateTime>()
          .toList();
    }
    return [];
  }
}
