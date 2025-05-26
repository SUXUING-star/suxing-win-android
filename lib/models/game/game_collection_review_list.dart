// ---------------------------------------------------------------------------
// 文件路径: lib/models/game/game_collection_review_list.dart (示例路径)
// ---------------------------------------------------------------------------

import 'package:suxingchahui/models/common/pagination.dart'; // 确保路径正确
import 'package:suxingchahui/models/game/game_collection_review.dart'; // 确保路径正确

class GameCollectionReviewList {
  final List<GameCollectionReview> entries;
  final PaginationData pagination;
  final String gameId; // API 返回的 gameId 也可以包含进来

  GameCollectionReviewList({
    required this.entries,
    required this.pagination,
    required this.gameId,
  });

  // 静态工厂方法，用于创建一个空的实例
  static GameCollectionReviewList empty(String gameIdForEmpty) {
    return GameCollectionReviewList(
      entries: [],
      pagination: PaginationData(page: 1, limit: 0, total: 0, pages: 0), // 使用 PaginationData 的空状态
      gameId: gameIdForEmpty, // 即使是空列表，也知道是哪个游戏的
    );
  }

  factory GameCollectionReviewList.fromJson(Map<String, dynamic> json) {
    List<GameCollectionReview> entriesList = [];
    if (json['entries'] != null && json['entries'] is List) {
      entriesList = (json['entries'] as List)
          .map((entryJson) {
        try {
          return GameCollectionReview.fromJson(Map<String, dynamic>.from(entryJson));
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
      paginationData = PaginationData.fromJson(Map<String, dynamic>.from(json['pagination']));
    } else {
      // 如果 API 未返回 pagination，则根据当前 entries 数量构建一个默认的
      // 这在后端未完全实现分页时可能有用，但理想情况是后端总是返回 pagination
      int totalItems = entriesList.length;
      int limit = json['limit'] as int? ?? (entriesList.isNotEmpty ? entriesList.length : 10); // 尝试从json获取limit
      int page = json['page'] as int? ?? 1; // 尝试从json获取page

      paginationData = PaginationData(
        page: page,
        limit: limit,
        total: totalItems, // 此时只能知道当前页的数量作为total
        pages: (totalItems == 0 || limit == 0) ? 0 : (page), // 只能假设当前是最后一页或唯一一页
      );
      // log.warning("GameCollectionReviewList.fromJson: Pagination data missing or invalid from API, using default based on current entries.");
    }

    return GameCollectionReviewList(
      entries: entriesList,
      pagination: paginationData,
      gameId: json['gameId'] as String? ?? '', // API也返回了 gameId
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'pagination': pagination.toJson(),
      'gameId': gameId,
    };
  }

  GameCollectionReviewList copyWith({
    List<GameCollectionReview>? entries,
    PaginationData? pagination,
    String? gameId,
  }) {
    return GameCollectionReviewList(
      entries: entries ?? this.entries,
      pagination: pagination ?? this.pagination,
      gameId: gameId ?? this.gameId,
    );
  }

  @override
  String toString() {
    return 'GameCollectionReviewList(entries: ${entries.length}, pagination: $pagination, gameId: $gameId)';
  }
}