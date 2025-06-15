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
    if (json['activities'] is List) {
      activitiesList = (json['activities'] as List)
          .map((item) {
        // 确保列表中的每个元素都是 Map 类型再进行解析
        if (item is Map<String, dynamic>) {
          return UserActivity.fromJson(item);
        }
        return null;
      })
          .whereType<UserActivity>() // 过滤掉解析失败的 null 项
          .toList();
    }

    PaginationData paginationData;
    if (json['pagination'] is Map<String, dynamic>) {
      paginationData = PaginationData.fromJson(json['pagination'] as Map<String, dynamic>);
    } else {
      // 业务逻辑: 如果后端响应中缺少分页信息，则根据返回的列表长度在前端生成一个默认的分页对象
      int totalItems = activitiesList.length;
      int defaultLimit = 20; // 动态列表的默认每页数量
      paginationData = PaginationData(
        page: 1,
        limit: defaultLimit,
        total: totalItems,
        pages: totalItems == 0 ? 0 : (totalItems / defaultLimit).ceil(),
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
