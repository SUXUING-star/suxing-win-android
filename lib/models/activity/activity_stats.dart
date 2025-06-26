// lib/models/activity/activity_stats.dart
import 'package:flutter/foundation.dart'; // @immutable 原来就有，保留
import 'package:suxingchahui/models/util_json.dart';

/// 单个活动类型的统计数据。
@immutable
class ActivityTypeCount {
  // --- JSON 字段键常量 ---
  static const String jsonKeyType = 'type';
  static const String jsonKeyCount = 'count';

  /// 活动类型，保持为 [String] 以兼容现有工具类。
  final String type;

  /// 该类型的活动数量。
  final int count;

  const ActivityTypeCount({
    required this.type,
    required this.count,
  });

  /// 复制并更新 ActivityTypeCount 对象部分字段。
  ActivityTypeCount copyWith({
    String? type,
    int? count,
  }) {
    return ActivityTypeCount(
      type: type ?? this.type,
      count: count ?? this.count,
    );
  }
}

/// 整体的活动统计数据模型。
///
/// 将后端返回的 Map 结构转换为更易于在 UI 中使用的 List 结构。
@immutable
class ActivityStats {
  // --- JSON 字段键常量 ---
  static const String jsonKeyTotalActivities = 'totalActivities';
  static const String jsonKeyCountsByType = 'countsByType';

  /// 总动态数。
  final int totalActivities;

  /// 按类型分的动态数量列表。
  final List<ActivityTypeCount> countsByType;

  const ActivityStats({
    required this.totalActivities,
    required this.countsByType,
  });

  /// 从 JSON Map 创建 [ActivityStats] 实例。
  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    List<ActivityTypeCount> countsList = [];

    // 业务逻辑: 后端返回的 `countsByType` 是一个 Map<String, int> 结构，
    // 这里需要遍历并转换为强类型的 List<ActivityTypeCount> 供前端使用。
    if (json[jsonKeyCountsByType] is Map<String, dynamic>) {
      countsList = (json[jsonKeyCountsByType] as Map<String, dynamic>)
          .entries
          .map((entry) => ActivityTypeCount(
                type: entry.key, // key is the activity type string
                count: UtilJson.parseIntSafely(entry.value),
              ))
          .toList();
    }

    return ActivityStats(
      totalActivities: UtilJson.parseIntSafely(json[jsonKeyTotalActivities]),
      countsByType: countsList,
    );
  }

  /// 将 [ActivityStats] 实例转换为 JSON Map。
  ///
  /// 它会将 `List<ActivityTypeCount>` 转换回后端原始的 Map 结构，以保证缓存数据与 API 响应格式一致。
  Map<String, dynamic> toJson() {
    // 使用 collection-for 将列表转换回 Map<String, int>
    final Map<String, int> countsMap = {
      for (var item in countsByType) item.type: item.count
    };

    return {
      jsonKeyTotalActivities: totalActivities,
      jsonKeyCountsByType: countsMap,
    };
  }

  /// 创建一个空的实例，用于加载或错误状态。
  factory ActivityStats.empty() {
    return const ActivityStats(
      totalActivities: 0,
      countsByType: [],
    );
  }

  /// 复制并更新 ActivityStats 对象部分字段。
  ActivityStats copyWith({
    int? totalActivities,
    List<ActivityTypeCount>? countsByType,
  }) {
    return ActivityStats(
      totalActivities: totalActivities ?? this.totalActivities,
      countsByType: countsByType ?? this.countsByType,
    );
  }
}
