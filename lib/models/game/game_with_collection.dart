// lib/models/game/game_with_collection.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection_item.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GameWithCollection {
  // 提取 JSON 字段名为 static const String 常量
  static const String jsonKeyGame = 'game';
  static const String jsonKeyGameCollection = 'collectionItem';

  final Game? game;
  final GameCollectionItem collection;

  const GameWithCollection({
    this.game,
    required this.collection,
  });

  factory GameWithCollection.fromJson(Map<String, dynamic> json) {
    Game? parsedGame;
    // 使用常量引用
    if (json[jsonKeyGame] is Map<String, dynamic>) {
      parsedGame = Game.fromJson(json[jsonKeyGame] as Map<String, dynamic>);
    }
    return GameWithCollection(
      game: parsedGame,
      // 业务逻辑: GameCollectionItem 的字段直接在 GameWithCollection 的顶层 JSON 中，而不是嵌套在 'collection' 键下
      collection: GameCollectionItem.fromJson(
          json[jsonKeyGameCollection] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      jsonKeyGameCollection: collection.toJson(),
    };

    // 使用常量引用
    if (game != null) {
      data[jsonKeyGame] = game!.toJson();
    } else {
      data[jsonKeyGame] = null;
    }
    return data;
  }
}

class GroupedGameCollections {
  // 提取 JSON 字段名为 static const String 常量
  static const String jsonKeyWantToPlay = 'want_to_play';
  static const String jsonKeyPlaying = 'playing';
  static const String jsonKeyPlayed = 'played';
  static const String jsonKeyCounts = 'counts';
  static const String jsonKeyPagination = 'pagination';

  final List<GameWithCollection> wantToPlay;
  final List<GameWithCollection> playing;
  final List<GameWithCollection> played;
  final GameCollectionCounts counts;
  final PaginationData pagination;

  GroupedGameCollections({
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

  factory GroupedGameCollections.fromJson(Map<String, dynamic> json) {
    List<GameWithCollection> parseList(dynamic listData) {
      return UtilJson.parseObjectList<GameWithCollection>(
        listData, // 传入原始的 list 数据
        (itemJson) => GameWithCollection.fromJson(
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

    return GroupedGameCollections(
      // 使用常量引用
      wantToPlay: parseList(json[jsonKeyWantToPlay]),
      playing: parseList(json[jsonKeyPlaying]),
      played: parseList(json[jsonKeyPlayed]),
      counts: GameCollectionCounts.fromJson(countsData),
      pagination: PaginationData.fromJson(paginationData),
    );
  }

  Map<String, dynamic> toJson() => {
        // 使用常量引用
        jsonKeyWantToPlay: wantToPlay.map((gwc) => gwc.toJson()).toList(),
        jsonKeyPlaying: playing.map((gwc) => gwc.toJson()).toList(),
        jsonKeyPlayed: played.map((gwc) => gwc.toJson()).toList(),
        jsonKeyCounts: counts.toJson(),
        jsonKeyPagination: pagination.toJson(),
      };
}

class GameCollectionCounts {
  // 提取 JSON 字段名为 static const String 常量
  static const String jsonKeyWantToPlay = 'want_to_play';
  static const String jsonKeyWantToPlayCamelCaseFallback =
      'wantToPlay'; // want_to_play 的备用名
  static const String jsonKeyWantToPlayKebabCaseFallback =
      'want-to-play'; // want_to_play 的备用名

  static const String jsonKeyPlaying = 'playing';
  static const String jsonKeyPlayed = 'played';
  static const String jsonKeyTotal = 'total';

  final int wantToPlay;
  final int playing;
  final int played;
  final int total;

  GameCollectionCounts({
    required this.wantToPlay,
    required this.playing,
    required this.played,
    required this.total,
  });

  factory GameCollectionCounts.fromJson(Map<String, dynamic> json) {
    // 业务逻辑: 兼容后端可能传入的不同风格的键名
    // 使用常量引用
    int wantToPlayCount = UtilJson.parseIntSafely(json[jsonKeyWantToPlay]);
    if (wantToPlayCount == 0 &&
        json[jsonKeyWantToPlayCamelCaseFallback] != null) {
      wantToPlayCount =
          UtilJson.parseIntSafely(json[jsonKeyWantToPlayCamelCaseFallback]);
    }
    if (wantToPlayCount == 0 &&
        json[jsonKeyWantToPlayKebabCaseFallback] != null) {
      wantToPlayCount =
          UtilJson.parseIntSafely(json[jsonKeyWantToPlayKebabCaseFallback]);
    }

    // 使用常量引用
    int playingCount = UtilJson.parseIntSafely(json[jsonKeyPlaying]);
    int playedCount = UtilJson.parseIntSafely(json[jsonKeyPlayed]);

    // 业务逻辑: 如果后端提供了 'total' 字段，则优先使用；否则根据各状态数量自行计算
    // 使用常量引用
    int totalCount = UtilJson.parseIntSafely(json[jsonKeyTotal]);
    if (totalCount == 0 &&
        (wantToPlayCount > 0 || playingCount > 0 || playedCount > 0)) {
      totalCount = wantToPlayCount + playingCount + playedCount;
    }

    return GameCollectionCounts(
      wantToPlay: wantToPlayCount,
      playing: playingCount,
      played: playedCount,
      total: totalCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 使用常量引用
      jsonKeyWantToPlay: wantToPlay,
      jsonKeyPlaying: playing,
      jsonKeyPlayed: played,
      // 'total' 通常是计算出来的，不一定需要提交给后端，如果后端需要，可以添加 jsonKeyTotal: total,
    };
  }

  @override
  String toString() {
    return 'GameCollectionCounts{wantToPlay: $wantToPlay, playing: $playing, played: $played, total: $total}';
  }
}
