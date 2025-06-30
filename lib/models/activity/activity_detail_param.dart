// lib/models/activity/activity_detail_param.dart

import 'package:flutter/cupertino.dart'; // 用于 ValueGetter
import 'package:meta/meta.dart'; // 用于 @immutable
import 'package:suxingchahui/models/activity/activity.dart'; // 用户活动模型
import 'package:suxingchahui/models/utils/util_json.dart'; // JSON 解析工具类
import 'package:suxingchahui/services/main/activity/activity_service.dart'; // 活动流类型常量

/// 活动详情页参数模型。
///
/// 用于在导航到活动详情页时传递必要数据。
@immutable
class ActivityDetailParam {
  // --- JSON 字段键常量 ---
  static const String jsonKeyListPageNum = 'listPageNum';
  static const String jsonKeyFeedType = 'feedType';
  static const String jsonKeyActivity = 'activity';
  static const String jsonKeyActivityId = 'activityId';

  final int listPageNum;
  final String feedType;
  final Activity activity; // 完整的活动对象
  final String activityId; // 活动ID

  /// 构造函数。
  ///
  /// [activity] 和 [activityId] 必须提供。
  /// [feedType] 默认为 [ActivitiesFeedType.public]，[listPageNum] 默认为 1。
  const ActivityDetailParam({
    this.feedType = ActivitiesFeedType.public,
    this.listPageNum = 1,
    required this.activity,
    required this.activityId,
  });

  /// 将 [ActivityDetailParam] 实例转换为 JSON Map。
  Map<String, dynamic> toJson() {
    return {
      jsonKeyActivityId: activityId,
      jsonKeyListPageNum: listPageNum,
      jsonKeyFeedType: feedType,
      jsonKeyActivity: activity.toJson(), // 将嵌套的 UserActivity 对象转换为 JSON
    };
  }

  /// 从 JSON Map 创建 [ActivityDetailParam] 实例。
  ///
  /// 如果 `activity` 字段在 JSON 中缺失或不是一个有效的 Map，将抛出 [FormatException]。
  factory ActivityDetailParam.fromJson(Map<String, dynamic> json) {
    // 确保 activity 字段存在且是一个 Map，因为它在构造函数中是 required 的
    final activityJson = json[jsonKeyActivity];
    if (activityJson is! Map<String, dynamic>) {
      throw FormatException(
          'ActivityDetailParam: "activity" field must be a valid map, got: $activityJson');
    }

    return ActivityDetailParam(
      activityId: UtilJson.parseId(json[jsonKeyActivityId]),
      activity: Activity.fromJson(activityJson),
      feedType: UtilJson.parseStringSafely(json[jsonKeyFeedType]),
      listPageNum: UtilJson.parseIntSafely(json[jsonKeyListPageNum]),
    );
  }

  /// 创建一个空的 [ActivityDetailParam] 实例。
  static ActivityDetailParam empty() {
    return ActivityDetailParam(
      activity: Activity.empty(),
      activityId: '',
      feedType: ActivitiesFeedType.public,
      listPageNum: 1,
    );
  }

  /// 复制当前 [ActivityDetailParam] 实例并选择性地更新某些字段。
  ActivityDetailParam copyWith({
    int? listPageNum,
    String? feedType,
    Activity? activity,
    String? activityId,
  }) {
    return ActivityDetailParam(
      listPageNum: listPageNum ?? this.listPageNum,
      feedType: feedType ?? this.feedType,
      activity: activity ?? this.activity,
      activityId: activityId ?? this.activityId,
    );
  }
}
