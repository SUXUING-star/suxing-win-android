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
    final gamesList = UtilJson.parseObjectList<Game>(
      json['games'] ?? json['history'], // 传入原始的 list 数据
      (itemJson) => Game.fromJson(itemJson), // 告诉它怎么把一个 item 的 json 转成 Game 对象
    );

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: gamesList, // 把游戏列表传进去，用于计算兜底分页
    );

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
