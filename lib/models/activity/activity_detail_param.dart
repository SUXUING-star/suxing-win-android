// lib/models/activity/activity_detail_param.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/util_json.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';

@immutable
class ActivityDetailParam {
  final int listPageNum;
  final String feedType;
  final UserActivity activity;
  final String activityId;
  const ActivityDetailParam({
    this.feedType = ActivitiesFeedType.public,
    this.listPageNum = 1,
    required this.activity,
    required this.activityId,
  });

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'listPageNum': listPageNum,
      'feedType': feedType,
      'activity': activity,
    };
  }

  factory ActivityDetailParam.fromJson(Map<String, dynamic> json) {
    return ActivityDetailParam(
      activityId: UtilJson.parseId(json['activityId']),
      activity: UserActivity.fromJson(json['activity']),
      feedType: UtilJson.parseStringSafely(json['feedType']),
      listPageNum: UtilJson.parseIntSafely(json['listPageNum']),
    );
  }
}
