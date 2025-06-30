// lib/models/user/user/user_list_pagination.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/user/user/user_with_ban_status.dart';
import 'package:suxingchahui/models/extension/json/to_json_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

/// 用户列表分页数据模型。
@immutable
class UserListPagination {
  // 1. 定义 JSON 字段的 static const String 常量
  static const String jsonKeyUsers = 'users';
  static const String jsonKeyPagination = 'pagination';

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

  // 2. 添加一个静态的查验接口函数
  /// 检查给定的原始响应 JSON 数据（通常是 dynamic 类型）是否符合
  /// UserListPagination 的基本结构要求。
  ///
  /// 此函数作为外部前置检验，不抛出异常，只返回布尔值。
  /// 适用于直接处理网络响应体（response.data），该响应体通常为 dynamic 类型。
  ///
  /// 要求：
  /// 1. 输入 jsonResponse 必须是一个 [Map<String, dynamic>] 类型。
  /// 2. 必须包含 'users' 键，且其值为 [List] 类型。
  /// 3. 必须包含 'pagination' 键，且其值为 [Map] 类型。
  static bool isValidJson(dynamic jsonResponse) {
    // 1. 检查输入是否为 [Map<String, dynamic>]
    if (jsonResponse is! Map<String, dynamic>) {
      return false;
    }
    final Map<String, dynamic> json = jsonResponse;

    // 2. 检查用户列表字段的存在和类型
    final dynamic usersData = json[jsonKeyUsers]; // 使用常量
    if (usersData is! List) {
      return false;
    }

    // 3. 检查分页信息字段的存在和类型
    final dynamic paginationData = json[jsonKeyPagination]; // 使用常量
    if (paginationData is! Map) {
      return false;
    }

    // 所有必要条件都满足
    return true;
  }

  /// 从 JSON Map 创建实例。
  factory UserListPagination.fromJson(Map<String, dynamic> json) {
    final usersList = UtilJson.parseObjectList<UserWithBanStatus>(
        json[jsonKeyUsers], // 使用常量
        (itemJson) => UserWithBanStatus.fromJson(itemJson));

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: usersList, // 把列表传进去，用于计算兜底分页
    );

    return UserListPagination(
      users: usersList,
      pagination: paginationData,
    );
  }

  /// 转换为 JSON Map。
  Map<String, dynamic> toJson() {
    return {
      jsonKeyUsers: users.toListJson(), // 使用常量
      jsonKeyPagination: pagination.toJson(), // 使用常量
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
