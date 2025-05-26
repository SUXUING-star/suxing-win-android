// lib/models/game/game_list_data.dart

import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/common/pagination.dart';

class GameList {
  final List<Game> games;
  final PaginationData pagination;
  final String? categoryName; // 已有
  final String? tag; // 已有
  final String? query; // 新增：用于搜索结果的查询关键词

  GameList({
    required this.games,
    required this.pagination,
    this.categoryName,
    this.tag,
    this.query, // 构造函数中设为可选
  });

  static GameList empty() {
    return GameList(
      games: [],
      pagination: PaginationData(page: 1, limit: 0, total: 0, pages: 0),
      categoryName: null,
      tag: null,
      query: null, // 空状态时 query 也为 null
    );
  }

  factory GameList.fromJson(Map<String, dynamic> json) {
    List<Game> gamesList = [];
    if (json['games'] != null && json['games'] is List) {
      gamesList = (json['games'] as List)
          .map((gameJson) => Game.fromJson(Map<String, dynamic>.from(gameJson)))
          .toList();
    } else if (json['history'] != null && json['history'] is List) {
      try {
        gamesList = (json['history'] as List)
            .map((itemJson) =>
                Game.fromJson(Map<String, dynamic>.from(itemJson)))
            .toList();
      } catch (_) {
        // 解析失败，gamesList 保持为空
      }
    }

    PaginationData paginationData;
    if (json['pagination'] != null && json['pagination'] is Map) {
      paginationData = PaginationData.fromJson(
          Map<String, dynamic>.from(json['pagination']));
    } else {
      int totalItems = gamesList.length;
      int defaultLimit = 15; // 与 GameService 中的 gamesLimit 或其他默认值保持一致
      paginationData = PaginationData(
        page: 1,
        limit: defaultLimit,
        total: totalItems,
        pages: (totalItems == 0)
            ? 0
            : ((defaultLimit <= 0) ? 1 : (totalItems / defaultLimit).ceil()),
      );
    }

    return GameList(
      games: gamesList,
      pagination: paginationData,
      categoryName: json['categoryName'] as String?,
      tag: json['tag'] as String?,
      query: json['query'] as String?, // 解析可选的 query
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'games': games.map((game) => game.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
    if (categoryName != null) {
      data['categoryName'] = categoryName;
    }
    if (tag != null) {
      data['tag'] = tag;
    }
    if (query != null) {
      // 如果 query 不为 null，则加入到 JSON
      data['query'] = query;
    }
    return data;
  }

  GameList copyWith({
    List<Game>? games,
    PaginationData? pagination,
    String? categoryName,
    String? tag,
    String? query, // copyWith 中添加 query
    bool clearCategoryName = false,
    bool clearTag = false,
    bool clearQuery = false, // 用于显式清除 query
  }) {
    return GameList(
      games: games ?? this.games,
      pagination: pagination ?? this.pagination,
      categoryName:
          clearCategoryName ? null : (categoryName ?? this.categoryName),
      tag: clearTag ? null : (tag ?? this.tag),
      query: clearQuery ? null : (query ?? this.query),
    );
  }

  @override
  String toString() {
    String result =
        'GameList(games: ${games.length} games, pagination: $pagination';
    if (categoryName != null) result += ', categoryName: $categoryName';
    if (tag != null) result += ', tag: $tag';
    if (query != null) result += ', query: "$query"'; // query 加上引号以便区分
    result += ')';
    return result;
  }
}
