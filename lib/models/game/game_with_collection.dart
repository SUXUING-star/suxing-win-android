// lib/models/game/game_with_collection.dart
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GameWithCollection {
  final Game? game;
  final GameCollectionItem collection;

  const GameWithCollection({
    this.game,
    required this.collection,
  });

  factory GameWithCollection.fromJson(Map<String, dynamic> json) {
    Game? parsedGame;
    if (json['game'] is Map<String, dynamic>) {
      parsedGame = Game.fromJson(json['game'] as Map<String, dynamic>);
    }
    return GameWithCollection(
      game: parsedGame,
      // 业务逻辑: GameCollectionItem 的字段直接在 GameWithCollection 的顶层 JSON 中，而不是嵌套在 'collection' 键下
      collection: GameCollectionItem.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = collection.toJson();
    if (game != null) {
      data['game'] = game!.toJson();
    } else {
      data['game'] = null;
    }
    return data;
  }
}

class GroupedGameCollections {
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

  factory GroupedGameCollections.fromJson(Map<String, dynamic> json) {
    List<GameWithCollection> parseList(dynamic listData) {
      if (listData is List) {
        return listData
            .map((item) {
              if (item is Map<String, dynamic>) {
                return GameWithCollection.fromJson(item);
              }
              return null;
            })
            .whereType<GameWithCollection>()
            .toList();
      }
      return [];
    }

    // 明确指定空 Map 的类型为 <String, dynamic>，以确保类型推断正确
    final countsData = json['counts'] is Map<String, dynamic>
        ? json['counts'] as Map<String, dynamic>
        : <String, dynamic>{};
    final paginationData = json['pagination'] is Map<String, dynamic>
        ? json['pagination'] as Map<String, dynamic>
        : <String, dynamic>{};

    return GroupedGameCollections(
      wantToPlay: parseList(json['want_to_play']),
      playing: parseList(json['playing']),
      played: parseList(json['played']),
      counts: GameCollectionCounts.fromJson(countsData),
      pagination: PaginationData.fromJson(paginationData),
    );
  }

  Map<String, dynamic> toJson() => {
        'want_to_play': wantToPlay.map((gwc) => gwc.toJson()).toList(),
        'playing': playing.map((gwc) => gwc.toJson()).toList(),
        'played': played.map((gwc) => gwc.toJson()).toList(),
        'counts': counts.toJson(),
        'pagination': pagination.toJson(),
      };
}

class GameCollectionCounts {
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
    int wantToPlayCount = UtilJson.parseIntSafely(json['want_to_play']);
    if (wantToPlayCount == 0 && json['wantToPlay'] != null) {
      wantToPlayCount = UtilJson.parseIntSafely(json['wantToPlay']);
    }
    if (wantToPlayCount == 0 && json['want-to-play'] != null) {
      wantToPlayCount = UtilJson.parseIntSafely(json['want-to-play']);
    }

    int playingCount = UtilJson.parseIntSafely(json['playing']);
    int playedCount = UtilJson.parseIntSafely(json['played']);

    // 业务逻辑: 如果后端提供了 'total' 字段，则优先使用；否则根据各状态数量自行计算
    int totalCount = UtilJson.parseIntSafely(json['total']);
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
      'want_to_play': wantToPlay,
      'playing': playing,
      'played': played,
    };
  }

  @override
  String toString() {
    return 'GameCollectionCounts{wantToPlay: $wantToPlay, playing: $playing, played: $played, total: $total}';
  }
}
