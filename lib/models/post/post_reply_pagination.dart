// lib/models/post/post_reply_pagination.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/post/post_reply.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class PostReplyPagination {
  // 1. 定义 JSON 字段的 static const String 常量
  static const String jsonKeyReplies = 'replies';
  static const String jsonKeyPagination = 'pagination';

  final List<PostReply> replies;
  final PaginationData pagination;

  const PostReplyPagination({
    required this.replies,
    required this.pagination,
  });

  // 静态工厂方法，用于创建一个空的 PostReplyList 实例
  static PostReplyPagination empty() {
    return PostReplyPagination(
      replies: [],
      pagination: PaginationData(page: 1, limit: 0, total: 0, pages: 0),
    );
  }

  // 2. 添加一个静态的查验接口函数
  /// 检查给定的原始响应 JSON 数据（通常是 dynamic 类型）是否符合
  /// PostReplyPagination 的基本结构要求。
  ///
  /// 此函数作为外部前置检验，不抛出异常，只返回布尔值。
  /// 适用于直接处理网络响应体（response.data），该响应体通常为 dynamic 类型。
  ///
  /// 要求：
  /// 1. 输入 jsonResponse 必须是一个 [Map<String, dynamic>] 类型。
  /// 2. 必须包含 'replies' 键，且其值为 [List] 类型。
  /// 3. 必须包含 'pagination' 键，且其值为 [Map] 类型。
  static bool isValidJson(dynamic jsonResponse) {
    // 1. 检查输入是否为 [Map<String, dynamic>]
    if (jsonResponse is! Map<String, dynamic>) {
      return false;
    }
    final Map<String, dynamic> json = jsonResponse;

    // 2. 检查回复列表字段的存在和类型
    final dynamic repliesData = json[jsonKeyReplies]; // 使用常量
    if (repliesData is! List) {
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

  factory PostReplyPagination.fromJson(Map<String, dynamic> json) {
    final repliesList = UtilJson.parseObjectList<PostReply>(
      json[jsonKeyReplies], // 使用常量
      (itemJson) =>
          PostReply.fromJson(itemJson), // 告诉它怎么把一个 item 的 json 转成 PostReply 对象
    );

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: repliesList, // 把回复列表传进去，用于计算兜底分页
    );

    return PostReplyPagination(
      replies: repliesList,
      pagination: paginationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyReplies: replies.map((reply) => reply.toJson()).toList(), // 使用常量
      jsonKeyPagination: pagination.toJson(), // 使用常量
    };
  }

  PostReplyPagination copyWith({
    List<PostReply>? replies,
    PaginationData? pagination,
  }) {
    return PostReplyPagination(
      replies: replies ?? this.replies,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  String toString() {
    return 'PostReplyList(replies: ${replies.length} replies, pagination: $pagination)';
  }
}
