
import 'package:suxingchahui/models/activity/user_activity.dart'; // 确保 UserActivity 模型的路径正确
import 'package:suxingchahui/models/common/pagination.dart'; // 导入你的 PaginationData 模型

class ActivityList {
  final List<UserActivity> activities;
  final PaginationData pagination;
  // 动态列表可能没有像游戏或帖子那样明确的 'tag' 或 'categoryName' 作为顶层属性
  // 如果有需要，可以按需添加

  ActivityList({
    required this.activities,
    required this.pagination,
  });

  // 静态工厂方法，用于创建一个空的 UserActivityList 实例
  static ActivityList empty() {
    return ActivityList(
      activities: [],
      pagination: PaginationData(
          page: 1, limit: 0, total: 0, pages: 0), // 使用 PaginationData 的空状态
    );
  }

  factory ActivityList.fromJson(Map<String, dynamic> json) {
    List<UserActivity> activitiesList = [];
    // API 返回的键名通常是 'activities'
    if (json['activities'] != null && json['activities'] is List) {
      activitiesList = (json['activities'] as List)
          .map((activityJson) =>
              UserActivity.fromJson(Map<String, dynamic>.from(activityJson)))
          .toList();
    }
    // 注意：UserActivity 模块似乎没有像 Game 或 Post 那样有 'history' 作为列表键的先例，
    // 所以这里暂时不添加对 'history' 的兼容。如果需要，可以仿照 GameList/PostList 添加。

    PaginationData paginationData;
    if (json['pagination'] != null && json['pagination'] is Map) {
      paginationData = PaginationData.fromJson(
          Map<String, dynamic>.from(json['pagination']));
    } else {
      // 如果API响应中没有 'pagination' 对象，创建一个默认的
      int totalItems = activitiesList.length;
      int defaultLimit = 20; // 默认每页数量
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
      'activities': activities.map((activity) => activity.toJson()).toList(),
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
