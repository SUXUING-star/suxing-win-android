// lib/models\game\game_collection_item.dart

// 游戏收藏状态常量
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GameCollectionItem {
  static const String statusAll = "all";
  static const String statusWantToPlay = 'want_to_play';
  static const String statusPlaying = 'playing';
  static const String statusPlayed = 'played';

  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyGameId = 'gameId';
  static const String jsonKeyStatus = 'status';
  static const String jsonKeyNotes = 'notes';
  static const String jsonKeyReview = 'review';
  static const String jsonKeyRating = 'rating';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyUpdateTime = 'updateTime';

  final String gameId;
  final String status;
  final String? notes;
  final String? review;
  final double? rating;
  final DateTime createTime;
  final DateTime updateTime;

  const GameCollectionItem({
    required this.gameId,
    required this.status,
    this.notes,
    this.review,
    this.rating,
    required this.createTime,
    required this.updateTime,
  });

  factory GameCollectionItem.fromJson(Map<String, dynamic> json) {
    return GameCollectionItem(
      gameId: UtilJson.parseId(json[jsonKeyGameId]), // 使用常量
      status: UtilJson.parseStringSafely(json[jsonKeyStatus]), // 使用常量
      notes: UtilJson.parseNullableStringSafely(json[jsonKeyNotes]), // 使用常量
      review: UtilJson.parseNullableStringSafely(json[jsonKeyReview]), // 使用常量
      rating: UtilJson.parseNullableDoubleSafely(json[jsonKeyRating]), // 使用常量
      createTime: UtilJson.parseDateTime(json[jsonKeyCreateTime]), // 使用常量
      updateTime: UtilJson.parseDateTime(json[jsonKeyUpdateTime]), // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      jsonKeyGameId: gameId, // 使用常量
      jsonKeyStatus: status, // 使用常量
      jsonKeyCreateTime: createTime.toIso8601String(), // 使用常量
      jsonKeyUpdateTime: updateTime.toIso8601String(), // 使用常量
    };

    if (notes != null) {
      data[jsonKeyNotes] = notes; // 使用常量
    }
    if (review != null) {
      data[jsonKeyReview] = review; // 使用常量
    }

    if (rating != null) {
      data[jsonKeyRating] = rating; // 使用常量
    }

    return data;
  }
}
