// lib/models/activity/activity_list.dart

import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';

class ActivityList {
  final List<UserActivity> activities;
  final PaginationData pagination;

  ActivityList({
    required this.activities,
    required this.pagination,
  });

  static ActivityList empty() {
    return ActivityList(
      activities: [],
      pagination: PaginationData(page: 1, limit: 0, total: 0, pages: 0),
    );
  }

  factory ActivityList.fromJson(Map<String, dynamic> json) {
    List<UserActivity> activitiesList = [];
    if (json['activities'] != null && json['activities'] is List) {
      activitiesList = (json['activities'] as List)
          .map((activityJson) =>
              UserActivity.fromJson(Map<String, dynamic>.from(activityJson)))
          .toList();
    }

    PaginationData paginationData;
    if (json['pagination'] != null && json['pagination'] is Map) {
      paginationData = PaginationData.fromJson(
          Map<String, dynamic>.from(json['pagination']));
    } else {
      int totalItems = activitiesList.length;
      int defaultLimit = 20;
      paginationData = PaginationData(
        page: 1,
        limit: defaultLimit,
        total: totalItems,
        pages: (totalItems == 0)
            ? 0
            : ((defaultLimit <= 0) ? 1 : (totalItems / defaultLimit).ceil()),
      );
    }

    return ActivityList(
      activities: activitiesList,
      pagination: paginationData,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      // ***** 关键修改在这里 *****
      'activities': activities.map((activity) => activity.toJson()).toList(),
      // ***** 结束修改 *****
      'pagination': pagination.toJson(),
    };
    return data;
  }

  ActivityList copyWith({
    List<UserActivity>? activities,
    PaginationData? pagination,
  }) {
    return ActivityList(
      activities: activities ?? this.activities,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  String toString() {
    return 'UserActivityList(activities: ${activities.length} activities, pagination: $pagination)';
  }
}
