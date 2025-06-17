// lib/models/activity/activity_list_pagination.dart

import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/util_json.dart';

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
    final activitiesList = UtilJson.parseObjectList<UserActivity>(
      json['activities'], // 传入原始的 list 数据
      (itemJson) =>
          UserActivity.fromJson(itemJson), // 告诉它怎么把一个 item 的 json 转成 Game 对象
    );

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: activitiesList, // 把游戏列表传进去，用于计算兜底分页
    );

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
