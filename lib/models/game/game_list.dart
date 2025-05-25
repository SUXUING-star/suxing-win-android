// lib/models/game/game_list_data.dart (或者你指定的其他路径)

import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/common/pagination.dart';

class GameList {
  final List<Game> games;
  final PaginationData pagination;
  final String? categoryName;
  final String? tag;

  GameList({
    required this.games,
    required this.pagination,
    this.categoryName,
    this.tag,
  });

  // --- 新增：静态工厂方法，用于创建一个空的 GameList 实例 ---
  static GameList empty() {
    return GameList(
      games: [],
      pagination: PaginationData(
          page: 1, limit: 0, total: 0, pages: 0), // 使用 PaginationData 的默认或空状态
      categoryName: null,
      tag: null,
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
      int defaultLimit = 20;
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
    return data;
  }

  GameList copyWith({
    List<Game>? games,
    PaginationData? pagination,
    String? categoryName,
    String? tag,
    bool clearCategoryName = false,
    bool clearTag = false,
  }) {
    return GameList(
      games: games ?? this.games,
      pagination: pagination ?? this.pagination,
      categoryName:
          clearCategoryName ? null : (categoryName ?? this.categoryName),
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }

  @override
  String toString() {
    String result =
        'GameList(games: ${games.length} games, pagination: $pagination';
    if (categoryName != null) {
      result += ', categoryName: $categoryName';
    }
    if (tag != null) {
      result += ', tag: $tag';
    }
    result += ')';
    return result;
  }
}
