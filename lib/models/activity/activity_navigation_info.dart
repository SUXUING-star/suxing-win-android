// lib/models/activity/activity_navigation_info.dart

import 'package:suxingchahui/models/activity/activity.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

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
  final Activity? prevActivity;
  final int? prevPageNum;
  final String? nextId;
  final int? nextPageNum;
  final Activity? nextActivity;

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
      prevId: UtilJson.parseId(json[jsonKeyPrevId]),
      prevActivity: json[jsonKeyPrevActivity] != null &&
              json[jsonKeyPrevActivity] is Map<String, dynamic>
          ? Activity.fromJson(json[jsonKeyPrevActivity])
          : null,
      prevPageNum: UtilJson.parseIntSafely(json[jsonKeyPrevPageNum]),
      nextId: UtilJson.parseId(json[jsonKeyNextId]),
      nextActivity: json[jsonKeyNextActivity] != null &&
              json[jsonKeyNextActivity] is Map<String, dynamic>
          ? Activity.fromJson(json[jsonKeyNextActivity])
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
    Activity? prevActivity,
    int? prevPageNum,
    String? nextId,
    int? nextPageNum,
    Activity? nextActivity,
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
