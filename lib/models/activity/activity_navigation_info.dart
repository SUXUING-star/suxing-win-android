// lib/models/activity/activity_navigation_info.dart

import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/util_json.dart';

class ActivityNavigationInfo {
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
      'feedType': feedType,
      'prevId': prevId,
      'prevActivity': prevActivity,
      'prevPageNum': prevPageNum,
      'nextId': nextId,
      'nextActivity': nextActivity,
      'nextPageNum': nextPageNum,
    };
  }

  factory ActivityNavigationInfo.fromJson(Map<String, dynamic> json) {
    return ActivityNavigationInfo(
      feedType: UtilJson.parseStringSafely(json['feedType']),
      prevId: UtilJson.parseId(json['prevId']),
      prevActivity: UserActivity.fromJson(json['prevActivity']),
      prevPageNum: UtilJson.parseIntSafely(json['prevPageNum']),
      nextId: UtilJson.parseId(json['nextId']),
      nextActivity: UserActivity.fromJson(json['nextActivity']),
      nextPageNum: UtilJson.parseIntSafely(json['nextPageNum']),
    );
  }
}
