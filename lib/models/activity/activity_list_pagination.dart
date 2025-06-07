// lib/models/activity/activity_list_pagination.dart

import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';

class ActivityListPagination {
  final List<UserActivity> activities;
  final PaginationData pagination;

  ActivityListPagination({
    required this.activities,
    required this.pagination,
  });

  static ActivityListPagination empty() {
    return ActivityListPagination(
      activities: [],
      pagination: PaginationData(page: 1, limit: 0, total: 0, pages: 0),
    );
  }

  factory ActivityListPagination.fromJson(Map<String, dynamic> json) {
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

    return ActivityListPagination(
      activities: activitiesList,
      pagination: paginationData,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'activities': activities.map((activity) => activity.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
    return data;
  }

  ActivityListPagination copyWith({
    List<UserActivity>? activities,
    PaginationData? pagination,
  }) {
    return ActivityListPagination(
      activities: activities ?? this.activities,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  String toString() {
    return 'UserActivityList(activities: ${activities.length} activities, pagination: $pagination)';
  }
}
