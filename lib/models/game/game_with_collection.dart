// lib/models/game/game_with_collection.dart
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';

class GameWithCollection {
  final Game? game;
  final GameCollectionItem collection;

  GameWithCollection({
    this.game,
    required this.collection,
  });

  factory GameWithCollection.fromJson(Map<String, dynamic> json) {
    Game? parsedGame;
    if (json['game'] != null && json['game'] is Map<String, dynamic>) {
      parsedGame = Game.fromJson(json['game'] as Map<String, dynamic>);
    }
    return GameWithCollection(
      game: parsedGame,
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
      if (listData is List && listData.isNotEmpty) {
        return listData
            .map((item) {
              try {
                return GameWithCollection.fromJson(
                    item as Map<String, dynamic>);
              } catch (e) {
                return null;
              }
            })
            .whereType<GameWithCollection>()
            .toList();
      }
      return [];
    }

    final countsData = json['counts'] as Map<String, dynamic>? ?? {};
    final paginationData = json['pagination'] as Map<String, dynamic>? ?? {};

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
    int wantToPlayCount = 0;
    int playingCount = 0;
    int playedCount = 0;
    int totalCount = 0;

    if (json['want_to_play'] != null) {
      wantToPlayCount = (json['want_to_play'] as num).toInt();
    } else if (json['wantToPlay'] != null) {
      wantToPlayCount = (json['wantToPlay'] as num).toInt();
    } else if (json['want-to-play'] != null) {
      wantToPlayCount = (json['want-to-play'] as num).toInt();
    }

    if (json['playing'] != null) {
      playingCount = (json['playing'] as num).toInt();
    }

    if (json['played'] != null) {
      playedCount = (json['played'] as num).toInt();
    }

    if (json['total'] != null) {
      totalCount = (json['total'] as num).toInt();
    } else {
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
