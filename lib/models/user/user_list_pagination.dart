import 'package:meta/meta.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/user/user_with_ban_status.dart';
import 'package:suxingchahui/models/util_json.dart';

/// 用户列表分页数据模型。
@immutable
class UserListPagination {
  final List<UserWithBanStatus> users;
  final PaginationData pagination;

  const UserListPagination({
    required this.users,
    required this.pagination,
  });

  /// 创建一个空实例。
  static UserListPagination empty() {
    return UserListPagination(
      users: [],
      pagination: PaginationData.empty(),
    );
  }

  /// 从 JSON Map 创建实例。
  factory UserListPagination.fromJson(Map<String, dynamic> json) {
    final usersList = (json['users'] as List? ?? [])
        .map((userJson) =>
            UserWithBanStatus.fromJson(Map<String, dynamic>.from(userJson)))
        .toList();

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: usersList, // 把游戏列表传进去，用于计算兜底分页
    );

    return UserListPagination(
      users: usersList,
      pagination: paginationData,
    );
  }

  /// 转换为 JSON Map。
  Map<String, dynamic> toJson() {
    return {
      'users': users.map((user) => user.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  /// 复制实例并替换部分数据。
  UserListPagination copyWith({
    List<UserWithBanStatus>? users,
    PaginationData? pagination,
  }) {
    return UserListPagination(
      users: users ?? this.users,
      pagination: pagination ?? this.pagination,
    );
  }
}
