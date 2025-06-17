// lib/models/game/game_collection_review_pagination.dart

import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game_collection_review.dart';
import 'package:suxingchahui/models/util_json.dart';

class GameCollectionReviewPagination {
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

  factory GameCollectionReviewPagination.fromJson(Map<String, dynamic> json) {
    final reviewsList = UtilJson.parseObjectList<GameCollectionReviewEntry>(
      json['reviews'], // 传入原始的 list 数据
      (itemJson) => GameCollectionReviewEntry.fromJson(
          itemJson), // 告诉它怎么把一个 item 的 json 转成 Game 对象
    );

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: reviewsList, // 把游戏列表传进去，用于计算兜底分页
    );

    return GameCollectionReviewPagination(
      reviews: reviewsList,
      pagination: paginationData,
      gameId: json['gameId'] as String? ?? '', // API也返回了 gameId
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'pagination': pagination.toJson(),
      'gameId': gameId,
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
