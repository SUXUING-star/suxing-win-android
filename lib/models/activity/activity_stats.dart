// lib/models/activity/activity_stats.dart
import 'package:flutter/foundation.dart';

/// 单个活动类型的统计数据。
@immutable
class ActivityTypeCount {
  /// 活动类型，保持为 [String] 以兼容现有工具类。
  final String type;

  /// 该类型的活动数量。
  final int count;

  const ActivityTypeCount({
    required this.type,
    required this.count,
  });
}

/// 整体的活动统计数据模型。
///
/// 将后端返回的 Map 结构转换为更易于在 UI 中使用的 List 结构。
@immutable
class ActivityStats {
  /// 总动态数。
  final int totalActivities;

  /// 按类型分的动态数量列表。
  final List<ActivityTypeCount> countsByType;

  const ActivityStats({
    required this.totalActivities,
    required this.countsByType,
  });

  /// 从 JSON Map 创建 [ActivityStats] 实例。
  ///
  /// 负责把后端返回的 `countsByType` Map 转换成 `List<ActivityTypeCount>`。
  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    final List<ActivityTypeCount> countsList = [];

    if (json['countsByType'] is Map) {
      final countsMap = json['countsByType'] as Map;
      countsMap.forEach((key, value) {
        if (key is String && value is int) {
          countsList.add(ActivityTypeCount(type: key, count: value));
        }
      });
    }

    return ActivityStats(
      totalActivities: (json['totalActivities'] as num?)?.toInt() ?? 0,
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
      'totalActivities': totalActivities,
      'countsByType': countsMap,
    };
  }

  /// 创建一个空的实例，用于加载或错误状态。
  factory ActivityStats.empty() {
    return const ActivityStats(
      totalActivities: 0,
      countsByType: [],
    );
  }
}