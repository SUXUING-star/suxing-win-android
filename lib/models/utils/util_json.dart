// lib/models/utils/util_json.dart

// 安全解析 DateTime
import 'package:mongo_dart/mongo_dart.dart';
import 'package:suxingchahui/models/common/pagination.dart';

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

  /// 安全地从动态值中解析出月份中的“日”。
  ///
  /// 此方法可以处理以下情况：
  /// - `int` 类型的值 (例如 `26`)
  /// - `String` 类型的值，格式为 'YYYY-MM-DD' (例如 `'2023-10-26'`)
  /// - `String` 类型的值，只包含一个数字 (例如 `'26'`)
  ///
  /// 如果解析失败或值为 null，则返回 0。
  static int parseDayOfMonthSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      try {
        // 检查是否是 'YYYY-MM-DD' 格式，如果是，则取最后一部分。
        // 否则，直接尝试解析整个字符串。
        final dayString = value.contains('-') ? value.split('-').last : value;
        return int.tryParse(dayString) ?? 0;
      } catch (_) {
        // 如果 split 或其他操作失败，返回 0
        return 0;
      }
    }
    return 0; // 其他类型，返回 0
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

  /// 从动态 JSON 数据中安全地解析分页信息。
  ///
  /// 此方法专门处理从不同来源（API响应、Hive缓存）获取的分页数据，
  /// 解决了因类型擦除（如 `Map<dynamic, dynamic>`）导致的问题。
  ///
  /// [json] 包含分页数据的顶层 Map。
  /// [listForFallback] (可选) 用于在缺少分页信息时计算总数的项目列表。
  /// 返回一个有效的 [PaginationData] 对象，绝不为 null。
  static PaginationData parsePaginationData(
    Map<String, dynamic> json, {
    List<dynamic>? listForFallback,
  }) {
    // 检查 'pagination' 字段是否存在且是一个 Map
    if (json['pagination'] is Map) {
      try {
        // 关键一步：无论原始类型是什么，都强制转换为 Map<String, dynamic>
        // 这就解决了 Hive 返回 Map<dynamic, dynamic> 的问题。
        final paginationMap =
            Map<String, dynamic>.from(json['pagination'] as Map);
        return PaginationData.fromJson(paginationMap);
      } catch (e) {
        // 如果转换或解析失败，则退回到下面的默认逻辑。
      }
    }

    // 如果 'pagination' 字段不存在、不是 Map 或解析失败，则生成一个默认的分页对象。
    final items = listForFallback ?? [];
    final totalItems = items.length;
    const defaultLimit = 15; // 使用一个固定的、可预期的默认值

    return PaginationData(
      page: 1,
      limit: defaultLimit,
      total: totalItems,
      pages: totalItems == 0 ? 0 : (totalItems / defaultLimit).ceil(),
    );
  }

  /// 从动态列表中安全地解析出指定类型的对象列表。
  ///
  /// 此方法是处理来自不同数据源（API、Hive缓存）列表的终极解决方案。
  /// 它使用一个转换函数 [fromJson] 来处理每一个列表项，并优雅地处理
  /// 类型不匹配和解析失败的情况。
  ///
  /// - `T`: 期望的目标对象类型。
  /// - [list]: 可能是 `null`、`List<dynamic>` 或其他类型的原始列表数据。
  /// - [fromJson]: 一个函数，接收一个 `Map<String, dynamic>` 并返回一个 `T` 类型的实例。
  ///
  /// 返回一个 `List<T>`，如果原始列表为 `null` 或解析失败，则返回空列表。
  static List<T> parseObjectList<T>(
    dynamic list,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    // 1. 检查原始数据是否是一个 List
    if (list is! List) {
      return []; // 如果不是 List，直接返回空列表
    }

    // 2. 遍历列表，安全地转换和解析每一项
    return list
        .map((item) {
          // 3. 检查每一项是否是一个 Map
          if (item is Map) {
            try {
              // 4. 关键一步：无论原始类型，都强制转换为 Map<String, dynamic>
              final itemMap = Map<String, dynamic>.from(item);
              // 5. 使用传入的 fromJson 函数进行解析
              return fromJson(itemMap);
            } catch (e) {
              // 如果 fromJson 解析失败，返回 null
              return null;
            }
          }
          // 如果列表项不是 Map，返回 null
          return null;
        })
        .whereType<T>()
        .toList(); // 6. 过滤掉所有 null，只留下成功的 T 类型对象
  }

  /// 从一个可能包含完整B站URL或只有bvid的字符串中，提取出纯净的BVID。
  ///
  /// 例如，可以处理以下输入:
  /// - 'BV1vS4y1G7gH' (纯净的bvid)
  /// - 'https://www.bilibili.com/video/BV1vS4y1G7gH'
  /// - 'http://b23.tv/BV1vS4y1G7gH'
  /// - 'b23.tv/BV1vS4y1G7gH'
  /// - 任何包含 'BV' 开头，后跟10位字母数字的字符串
  ///
  /// 如果找不到有效的BVID，返回 null。
  static String? parseBvid(dynamic value) {
    if (value == null || value is! String || value.isEmpty) {
      return null;
    }

    // 正则表达式，用于匹配 "BV" 开头，后跟10位字母和数字的字符串
    // \w 匹配字母、数字和下划线，B站bvid没有下划线，所以是安全的
    final regExp = RegExp(r'BV(\w{10})');
    final match = regExp.firstMatch(value);

    // 如果匹配成功，返回完整的匹配项 (例如 "BV1vS4y1G7gH")
    if (match != null) {
      return match.group(0);
    }

    return null; // 匹配失败，返回 null
  }

  /// 直接根据纯净的 bvid 构建 URL，不再需要解析。
  static String? parseBvidToUrl(String? originalBvid) {
    final bvid = parseBvid(originalBvid);
    if (bvid == null || bvid.isEmpty) {
      return null;
    }
    return 'https://player.bilibili.com/player.html?bvid=$bvid';
  }

  /// 新增网易云音乐 ID 解析工具
  /// 从一个可能包含完整网易云音乐URL的字符串中，提取出纯净的歌曲ID。
  ///
  /// 可以处理以下格式:
  /// - https://music.163.com/song?id=35845064...
  /// - https://music.163.com/#/song?id=35845064...
  /// - https://music.163.com/song/35845064/...
  ///
  /// 如果找不到有效的歌曲ID，返回 null。
  static String? _parseNeteaseMusicId(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return null;
    try {
      // 核心逻辑：用正则表达式匹配所有可能的 "id=" 或 "/song/" 后面的数字
      final regExp = RegExp(r'(?<=id=)\d+|(?<=song\/)\d+');
      final match = regExp.firstMatch(originalUrl);

      if (match != null) {
        return match.group(0); // 返回匹配到的纯数字ID
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// 新增网易云音乐 URL 生成工具
  /// 根据纯净的歌曲ID构建可直接播放的网易云音乐嵌入式 URL。
  static String? parseNeteaseMusicUrl(String? originalUrl) {
    final songId = _parseNeteaseMusicId(originalUrl);
    if (songId == null || songId.isEmpty) {
      return null;
    }
    return 'https://music.163.com/outchain/player?type=2&id=$songId&auto=0&height=86';
  }

  static List<T> fromListStringToListObject<T>(
    List<String>? list,
    T Function(String s) fromString,
  ) {
    if (list == null) return [];
    return list.map((s) => fromString(s)).toList();
  }
}
