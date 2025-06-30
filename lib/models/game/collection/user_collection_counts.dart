// lib/models/game/collection/user_collection_counts.dart

import 'package:suxingchahui/models/utils/util_json.dart';

class UserCollectionCounts {
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

  UserCollectionCounts({
    required this.wantToPlay,
    required this.playing,
    required this.played,
    required this.total,
  });

  factory UserCollectionCounts.fromJson(Map<String, dynamic> json) {
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

    return UserCollectionCounts(
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
