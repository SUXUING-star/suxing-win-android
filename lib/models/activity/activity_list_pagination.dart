// lib/models/activity/activity_list_pagination.dart

import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/util_json.dart';

class ActivityListPagination {
  // 1. 定义 JSON 字段的 static const String 常量
  static const String jsonKeyActivities = 'activities';
  static const String jsonKeyPagination = 'pagination';

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

  // 2. 添加一个静态的查验接口函数
  /// 检查给定的原始响应 JSON 数据（通常是 dynamic 类型）是否符合
  /// ActivityListPagination 的基本结构要求。
  ///
  /// 此函数作为外部前置检验，不抛出异常，只返回布尔值。
  /// 适用于直接处理网络响应体（response.data），该响应体通常为 dynamic 类型。
  ///
  /// 要求：
  /// 1. 输入 jsonResponse 必须是一个 [Map<String, dynamic>] 类型。
  /// 2. 必须包含 'activities' 键，且其值为 [List] 类型。
  /// 3. 必须包含 'pagination' 键，且其值为 [Map] 类型。
  static bool isValidJson(dynamic jsonResponse) {
    // 1. 检查输入是否为 [Map<String, dynamic>]
    if (jsonResponse is! Map<String, dynamic>) {
      return false;
    }
    final Map<String, dynamic> json = jsonResponse;

    // 2. 检查活动列表字段的存在和类型
    final dynamic activitiesData = json[jsonKeyActivities];
    if (activitiesData is! List) {
      return false;
    }

    // 3. 检查分页信息字段的存在和类型
    final dynamic paginationData = json[jsonKeyPagination];
    if (paginationData is! Map) {
      return false;
    }

    // 所有必要条件都满足
    return true;
  }

  factory ActivityListPagination.fromJson(Map<String, dynamic> json) {
    final activitiesList = UserActivity.fromListJson(json[jsonKeyActivities]);

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: activitiesList, // 把活动列表传进去，用于计算兜底分页
    );

    return ActivityListPagination(
      activities: activitiesList,
      pagination: paginationData,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      jsonKeyActivities:
          activities.map((activity) => activity.toJson()).toList(), // 使用常量
      jsonKeyPagination: pagination.toJson(), // 使用常量
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
