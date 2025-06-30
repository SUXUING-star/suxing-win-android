// lib/models/game/game/game_list_pagination.dart

import 'package:suxingchahui/models/game/game/game.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/extension/json/to_json_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class GameListPagination {
  // 提取 JSON 字段名为 static const String 常量，使用驼峰命名（camelCase）
  static const String jsonKeyGames = 'games';
  static const String jsonKeyHistoryFallback = 'history'; // games 字段的备用名
  static const String jsonKeyPagination = 'pagination';
  static const String jsonKeyCategoryName = 'categoryName';
  static const String jsonKeyCategoryFallback =
      'category'; // categoryName 字段的备用名
  static const String jsonKeyTag = 'tag';
  static const String jsonKeyTagNameFallback = 'tagName'; // tag 字段的备用名
  static const String jsonKeyQuery = 'query';

  final List<Game> games;
  final PaginationData pagination;
  final String? categoryName;
  final String? tag;
  final String? query;

  GameListPagination({
    required this.games,
    required this.pagination,
    this.categoryName,
    this.tag,
    this.query,
  });

  static GameListPagination empty() {
    return GameListPagination(
      games: [],
      pagination: PaginationData(page: 1, limit: 0, total: 0, pages: 0),
      categoryName: null,
      tag: null,
      query: null,
    );
  }

  /// 检查给定的原始响应 JSON 数据（通常是 dynamic 类型）是否符合
  /// GameListPagination 的基本结构要求。
  ///
  /// 此函数作为外部前置检验，不抛出异常，只返回布尔值。
  /// 适用于直接处理网络响应体（response.data），该响应体通常为 dynamic 类型。
  ///
  /// 要求：
  /// 1. 输入 jsonResponse 必须是一个 [Map<String, dynamic>] 类型。
  /// 2. 必须包含 'games' 键 (或其备用 'history')，且其值为 [List] 类型。
  /// 3. 必须包含 'pagination' 键，且其值为 [Map] 类型。
  static bool isValidJson(dynamic jsonResponse) {
    // 1. 检查输入是否为 Map<String, dynamic>
    if (jsonResponse is! Map<String, dynamic>) {
      return false;
    }
    final Map<String, dynamic> json = jsonResponse;

    // 2. 检查游戏列表字段的存在和类型
    // 假设 jsonKeyGames 和 jsonKeyHistoryFallback 已经作为 static const String 定义在类中
    final dynamic gamesData =
        json[jsonKeyGames] ?? json[jsonKeyHistoryFallback];
    if (gamesData is! List) {
      return false;
    }

    // 3. 检查分页信息字段的存在和类型
    // 假设 jsonKeyPagination 已经作为 static const String 定义在类中
    final dynamic paginationData = json[jsonKeyPagination];
    if (paginationData is! Map) {
      return false;
    }

    // 所有必要条件都满足
    return true;
  }

  factory GameListPagination.fromJson(Map<String, dynamic> json) {
    // 使用常量代替硬编码的字符串
    final gamesList = Game.fromListJson(
      json[jsonKeyGames] ?? json[jsonKeyHistoryFallback], // 传入原始的 list 数据
    );

    final paginationData = UtilJson.parsePaginationData(
      json,
      listForFallback: gamesList, // 把游戏列表传进去，用于计算兜底分页
    );

    return GameListPagination(
      games: gamesList,
      pagination: paginationData,
      categoryName: UtilJson.parseNullableStringSafely(
          json[jsonKeyCategoryName] ?? json[jsonKeyCategoryFallback]),
      tag: UtilJson.parseNullableStringSafely(
          json[jsonKeyTag] ?? json[jsonKeyTagNameFallback]),
      query: UtilJson.parseNullableStringSafely(json[jsonKeyQuery]),
    );
  }

  Map<String, dynamic> toJson() {
    // 使用常量代替硬编码的字符串
    final Map<String, dynamic> data = {
      jsonKeyGames: games.toListJson(),
      jsonKeyPagination: pagination.toJson(),
    };
    if (categoryName != null) {
      data[jsonKeyCategoryName] = categoryName;
    }
    if (tag != null) {
      data[jsonKeyTag] = tag;
    }
    if (query != null) {
      // 如果 query 不为 null，则加入到 JSON
      data[jsonKeyQuery] = query;
    }
    return data;
  }

  GameListPagination copyWith({
    List<Game>? games,
    PaginationData? pagination,
    String? categoryName,
    String? tag,
    String? query,
    bool clearCategoryName = false,
    bool clearTag = false,
    bool clearQuery = false,
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
    if (query != null) result += ', query: "$query"';
    result += ')';
    return result;
  }
}
