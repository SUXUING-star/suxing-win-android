// lib/models/game/collection/grouped_collection_items_with_games.dart

import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/collection/collection_item_with_game.dart';
import 'package:suxingchahui/models/game/collection/user_collection_counts.dart';
import 'package:suxingchahui/models/extension/json/to_json_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class GroupedCollectionItemsWithGames {
  // 提取 JSON 字段名为 static const String 常量
  static const String jsonKeyWantToPlay = 'want_to_play';
  static const String jsonKeyPlaying = 'playing';
  static const String jsonKeyPlayed = 'played';
  static const String jsonKeyCounts = 'counts';
  static const String jsonKeyPagination = 'pagination';

  final List<CollectionItemWithGame> wantToPlay;
  final List<CollectionItemWithGame> playing;
  final List<CollectionItemWithGame> played;
  final UserCollectionCounts counts;
  final PaginationData pagination;

  GroupedCollectionItemsWithGames({
    required this.wantToPlay,
    required this.playing,
    required this.played,
    required this.counts,
    required this.pagination,
  });

  /// 检查给定的原始响应 JSON 数据（通常是 dynamic 类型）是否符合
  /// GroupedGameCollections 的基本结构要求。
  ///
  /// 此函数作为外部前置检验，不抛出异常，只返回布尔值。
  /// 适用于直接处理网络响应体（response.data），该响应体通常为 dynamic 类型。
  ///
  /// **简化要求：**
  /// 1. 输入 jsonResponse 必须是一个 [Map<String, dynamic>] 类型。
  /// （内部字段的缺失或类型不符将由 [fromJson] 方法的安全解析逻辑处理）
  static bool isValidJson(dynamic jsonResponse) {
    // 仅仅检查顶层是否为 Map 类型，因为 fromJson 及其依赖的 UtilJson.parseSafely 方法
    // 能够安全地处理内部字段的缺失或类型不符。
    return jsonResponse is Map<String, dynamic>;
  }

  factory GroupedCollectionItemsWithGames.fromJson(Map<String, dynamic> json) {
    List<CollectionItemWithGame> parseList(dynamic listData) {
      return UtilJson.parseObjectList<CollectionItemWithGame>(
        listData, // 传入原始的 list 数据
        (itemJson) => CollectionItemWithGame.fromJson(
            itemJson), // 告诉它怎么把一个 item 的 json 转成 Game 对象
      );
    }

    // 明确指定空 Map 的类型为 [Map<String, dynamic>]，以确保类型推断正确
    // 使用常量引用
    final countsData = json[jsonKeyCounts] is Map<String, dynamic>
        ? json[jsonKeyCounts] as Map<String, dynamic>
        : <String, dynamic>{};
    // 使用常量引用
    final paginationData = json[jsonKeyPagination] is Map<String, dynamic>
        ? json[jsonKeyPagination] as Map<String, dynamic>
        : <String, dynamic>{};

    return GroupedCollectionItemsWithGames(
      // 使用常量引用
      wantToPlay: parseList(json[jsonKeyWantToPlay]),
      playing: parseList(json[jsonKeyPlaying]),
      played: parseList(json[jsonKeyPlayed]),
      counts: UserCollectionCounts.fromJson(countsData),
      pagination: PaginationData.fromJson(paginationData),
    );
  }

  Map<String, dynamic> toJson() => {
        // 使用常量引用
        jsonKeyWantToPlay: wantToPlay.toListJson(),
        jsonKeyPlaying: playing.toListJson(),
        jsonKeyPlayed: played.toListJson(),
        jsonKeyCounts: counts.toJson(),
        jsonKeyPagination: pagination.toJson(),
      };
}
