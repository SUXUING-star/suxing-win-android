// lib/models/game/game_collection_review_pagination.dart

import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game_collection_review.dart';

class GameCollectionReviewPagination {
  final List<GameCollectionReview> reviews;
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
    List<GameCollectionReview> reviewsList = [];
    if (json['reviews'] != null && json['reviews'] is List) {
      reviewsList = (json['reviews'] as List)
          .map((r) {
            try {
              return GameCollectionReview.fromJson(
                  Map<String, dynamic>.from(r));
            } catch (e) {
              // print('Error parsing GameCollectionReview from JSON: $entryJson, error: $e');
              return null; // 解析失败则返回 null
            }
          })
          .whereType<GameCollectionReview>() // 过滤掉解析失败的 null
          .toList();
    }

    PaginationData paginationData;
    if (json['pagination'] != null && json['pagination'] is Map) {
      paginationData = PaginationData.fromJson(
          Map<String, dynamic>.from(json['pagination']));
    } else {
      // 如果 API 未返回 pagination，则根据当前 entries 数量构建一个默认的
      // 这在后端未完全实现分页时可能有用，但理想情况是后端总是返回 pagination
      int totalItems = reviewsList.length;
      int limit = json['limit'] as int? ??
          (reviewsList.isNotEmpty ? reviewsList.length : 10); // 尝试从json获取limit
      int page = json['page'] as int? ?? 1; // 尝试从json获取page

      paginationData = PaginationData(
        page: page,
        limit: limit,
        total: totalItems, // 此时只能知道当前页的数量作为total
        pages: (totalItems == 0 || limit == 0) ? 0 : (page), // 只能假设当前是最后一页或唯一一页
      );
      // log.warning("GameCollectionReviewList.fromJson: Pagination data missing or invalid from API, using default based on current entries.");
    }

    return GameCollectionReviewPagination(
      reviews: reviewsList,
      pagination: paginationData,
      gameId: json['gameId'] as String? ?? '', // API也返回了 gameId
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviews': reviews.map((entry) => entry.toJson()).toList(),
      'pagination': pagination.toJson(),
      'gameId': gameId,
    };
  }

  GameCollectionReviewPagination copyWith({
    List<GameCollectionReview>? entries,
    PaginationData? pagination,
    String? gameId,
  }) {
    return GameCollectionReviewPagination(
      reviews: entries ?? reviews,
      pagination: pagination ?? this.pagination,
      gameId: gameId ?? this.gameId,
    );
  }

  @override
  String toString() {
    return 'GameCollectionReviewList(entries: ${reviews.length}, pagination: $pagination, gameId: $gameId)';
  }
}
