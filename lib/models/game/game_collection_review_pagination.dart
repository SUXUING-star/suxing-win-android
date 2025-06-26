// lib/models/game/game_collection_review_pagination.dart

import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game_collection_review.dart';
import 'package:suxingchahui/models/util_json.dart';

class GameCollectionReviewPagination {
  // 1. 定义 JSON 字段的 static const String 常量
  static const String jsonKeyReviews = 'reviews';
  static const String jsonKeyPagination = 'pagination';
  static const String jsonKeyGameId = 'gameId';

  final List<GameCollectionReviewEntry> reviews;
  final PaginationData pagination;
  final String gameId;

  GameCollectionReviewPagination({
    required this.reviews,
    required this.pagination,
    required this.gameId,
  });

  // 静态工厂方法，用于创建一个空的实例
  static GameCollectionReviewPagination empty(String gameIdForEmpty) {
    return GameCollectionReviewPagination(
      reviews: [],
      pagination: PaginationData(
          page: 1, limit: 0, total: 0, pages: 0), // 使用 PaginationData 的空状态
      gameId: gameIdForEmpty, // 即使是空列表，也知道是哪个游戏的
    );
  }

  // 2. 添加一个静态的查验接口函数
  /// 检查给定的原始响应 JSON 数据（通常是 dynamic 类型）是否符合
  /// GameCollectionReviewPagination 的基本结构要求。
  ///
  /// 此函数作为外部前置检验，不抛出异常，只返回布尔值。
  /// 适用于直接处理网络响应体（response.data），该响应体通常为 dynamic 类型。
  ///
  /// 要求：
  /// 1. 输入 jsonResponse 必须是一个 [Map<String, dynamic>] 类型。
  /// 2. 必须包含 'reviews' 键，且其值为 [List] 类型。
  /// 3. 必须包含 'pagination' 键，且其值为 [Map] 类型。
  /// 4. 必须包含 'gameId' 键。
  static bool isValidJson(dynamic jsonResponse) {
    // 1. 检查输入是否为 [Map<String, dynamic>]
    if (jsonResponse is! Map<String, dynamic>) {
      return false;
    }
    final Map<String, dynamic> json = jsonResponse;

    // 2. 检查评论列表字段的存在和类型
    final dynamic reviewsData = json[jsonKeyReviews]; // 使用常量
    if (reviewsData is! List) {
      return false;
    }

    // 3. 检查分页信息字段的存在和类型
    final dynamic paginationData = json[jsonKeyPagination]; // 使用常量
    if (paginationData is! Map) {
      return false;
    }

    // 4. 检查 gameId 字段的存在
    if (!json.containsKey(jsonKeyGameId)) {
      // 检查键是否存在，因为其值可能是 null 但键本身必须存在
      return false;
    }

    // 所有必要条件都满足
    return true;
  }

  factory GameCollectionReviewPagination.fromJson(Map<String, dynamic> json) {
    final reviewsList = UtilJson.parseObjectList<GameCollectionReviewEntry>(
      json[jsonKeyReviews], // 使用常量
      (itemJson) => GameCollectionReviewEntry.fromJson(
          itemJson), // 告诉它怎么把一个 item 的 json 转成 GameCollectionReviewEntry 对象
    );

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: reviewsList, // 把评论列表传进去，用于计算兜底分页
    );

    return GameCollectionReviewPagination(
      reviews: reviewsList,
      pagination: paginationData,
      gameId: json[jsonKeyGameId] as String? ?? '', // 使用常量，API也返回了 gameId
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyReviews: reviews.map((r) => r.toJson()).toList(), // 使用常量
      jsonKeyPagination: pagination.toJson(), // 使用常量
      jsonKeyGameId: gameId, // 使用常量
    };
  }

  GameCollectionReviewPagination copyWith({
    List<GameCollectionReviewEntry>? reviews,
    PaginationData? pagination,
    String? gameId,
  }) {
    return GameCollectionReviewPagination(
      reviews: reviews ?? this.reviews,
      pagination: pagination ?? this.pagination,
      gameId: gameId ?? this.gameId,
    );
  }

  @override
  String toString() {
    return 'GameCollectionReviewList(entries: ${reviews.length}, pagination: $pagination, gameId: $gameId)';
  }
}
