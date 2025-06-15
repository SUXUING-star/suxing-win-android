// lib/models/game/game_list_pagination.dart

import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/util_json.dart';

class GameListPagination {
  final List<Game> games;
  final PaginationData pagination;
  final String? categoryName; // 已有
  final String? tag; // 已有
  final String? query; // 新增：用于搜索结果的查询关键词

  GameListPagination({
    required this.games,
    required this.pagination,
    this.categoryName,
    this.tag,
    this.query, // 构造函数中设为可选
  });

  static GameListPagination empty() {
    return GameListPagination(
      games: [],
      pagination: PaginationData(page: 1, limit: 0, total: 0, pages: 0),
      categoryName: null,
      tag: null,
      query: null, // 空状态时 query 也为 null
    );
  }

  factory GameListPagination.fromJson(Map<String, dynamic> json) {
    List<Game> gamesList = [];

    // 业务逻辑: API 可能在 'games' 或 'history' 键下返回游戏列表，优先使用 'games'
    dynamic rawList = json['games'] ?? json['history'];

    if (rawList is List) {
      gamesList = rawList
          .map((item) {
            if (item is Map<String, dynamic>) {
              return Game.fromJson(item);
            }
            return null;
          })
          .whereType<Game>() // 过滤掉解析失败的 null 项
          .toList();
    }

    PaginationData paginationData;
    if (json['pagination'] is Map<String, dynamic>) {
      paginationData =
          PaginationData.fromJson(json['pagination'] as Map<String, dynamic>);
    } else {
      // 业务逻辑: 如果后端响应中缺少分页信息，则根据返回的列表长度在前端生成一个默认的分页对象
      int totalItems = gamesList.length;
      int defaultLimit = 15; // 默认每页数量
      paginationData = PaginationData(
        page: 1,
        limit: defaultLimit,
        total: totalItems,
        pages: totalItems == 0 ? 0 : (totalItems / defaultLimit).ceil(),
      );
    }

    return GameListPagination(
      games: gamesList,
      pagination: paginationData,
      categoryName: UtilJson.parseNullableStringSafely(json['categoryName']),
      tag: UtilJson.parseNullableStringSafely(json['tag']),
      query: UtilJson.parseNullableStringSafely(json['query']),
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

  GameListPagination copyWith({
    List<Game>? games,
    PaginationData? pagination,
    String? categoryName,
    String? tag,
    String? query, // copyWith 中添加 query
    bool clearCategoryName = false,
    bool clearTag = false,
    bool clearQuery = false, // 用于显式清除 query
  }) {
    return GameListPagination(
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
