// lib/models/activity/activity_navigation_info.dart

import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/util_json.dart';

class ActivityNavigationInfo {
  // --- JSON 字段键常量 ---
  static const String jsonKeyFeedType = 'feedType';
  static const String jsonKeyPrevId = 'prevId';
  static const String jsonKeyPrevActivity = 'prevActivity';
  static const String jsonKeyPrevPageNum = 'prevPageNum';
  static const String jsonKeyNextId = 'nextId';
  static const String jsonKeyNextPageNum = 'nextPageNum';
  static const String jsonKeyNextActivity = 'nextActivity';

  final String feedType;
  final String? prevId;
  final UserActivity? prevActivity;
  final int? prevPageNum;
  final String? nextId;
  final int? nextPageNum;
  final UserActivity? nextActivity;

  ActivityNavigationInfo({
    required this.feedType,
    this.prevId,
    this.prevActivity,
    this.prevPageNum,
    this.nextId,
    this.nextActivity,
    this.nextPageNum,
  });

  Map<String, dynamic> toJson() {
    return {
      jsonKeyFeedType: feedType,
      jsonKeyPrevId: prevId,
      // 安全地转换为JSON，如果为null则返回null
      jsonKeyPrevActivity: prevActivity?.toJson(),
      jsonKeyPrevPageNum: prevPageNum,
      jsonKeyNextId: nextId,
      // 安全地转换为JSON，如果为null则返回null
      jsonKeyNextActivity: nextActivity?.toJson(),
      jsonKeyNextPageNum: nextPageNum,
    };
  }

  factory ActivityNavigationInfo.fromJson(Map<String, dynamic> json) {
    return ActivityNavigationInfo(
      feedType: UtilJson.parseStringSafely(json[jsonKeyFeedType]),
      // 保持原始逻辑，用 UtilJson.parseId 处理 ID 字段的可空性
      prevId: UtilJson.parseId(json[jsonKeyPrevId]),
      // 原始代码是直接 UserActivity.fromJson(json['prevActivity'])，如果为 null 会报错
      // 这里改为安全解析，如果 json['prevActivity'] 为 null 则返回 null
      prevActivity: json[jsonKeyPrevActivity] != null &&
              json[jsonKeyPrevActivity] is Map<String, dynamic>
          ? UserActivity.fromJson(json[jsonKeyPrevActivity])
          : null,
      prevPageNum: UtilJson.parseIntSafely(json[jsonKeyPrevPageNum]),
      // 保持原始逻辑，用 UtilJson.parseId 处理 ID 字段的可空性
      nextId: UtilJson.parseId(json[jsonKeyNextId]),
      // 原始代码是直接 UserActivity.fromJson(json['nextActivity'])，如果为 null 会报错
      // 这里改为安全解析，如果 json['nextActivity'] 为 null 则返回 null
      nextActivity: json[jsonKeyNextActivity] != null &&
              json[jsonKeyNextActivity] is Map<String, dynamic>
          ? UserActivity.fromJson(json[jsonKeyNextActivity])
          : null,
      nextPageNum: UtilJson.parseIntSafely(json[jsonKeyNextPageNum]),
    );
  }

  /// 创建一个空的 ActivityNavigationInfo 对象。
  static ActivityNavigationInfo empty() {
    return ActivityNavigationInfo(
      feedType: '',
      prevId: null,
      prevActivity: null,
      prevPageNum: null,
      nextId: null,
      nextPageNum: null,
      nextActivity: null,
    );
  }

  /// 复制并更新 ActivityNavigationInfo 对象部分字段。
  ActivityNavigationInfo copyWith({
    String? feedType,
    String? prevId,
    UserActivity? prevActivity,
    int? prevPageNum,
    String? nextId,
    int? nextPageNum,
    UserActivity? nextActivity,
  }) {
    return ActivityNavigationInfo(
      feedType: feedType ?? this.feedType,
      prevId: prevId ?? this.prevId,
      prevActivity: prevActivity ?? this.prevActivity,
      prevPageNum: prevPageNum ?? this.prevPageNum,
      nextId: nextId ?? this.nextId,
      nextPageNum: nextPageNum ?? this.nextPageNum,
      nextActivity: nextActivity ?? this.nextActivity,
    );
  }
}
