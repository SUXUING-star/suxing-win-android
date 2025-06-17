// lib/models\game\game_collection.dart

// 游戏收藏状态常量
import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GameCollectionStatus {
  static const String all = "all";
  static const String wantToPlay = 'want_to_play'; // 修改为与后端一致
  static const String playing = 'playing';
  static const String played = 'played';
}

@immutable
class GameCollectionItem {
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
      gameId: UtilJson.parseId(json['gameId']),
      status: UtilJson.parseStringSafely(json['status']),
      notes: UtilJson.parseNullableStringSafely(json['notes']),
      review: UtilJson.parseNullableStringSafely(json['review']),
      rating: UtilJson.parseNullableDoubleSafely(json['rating']),
      createTime: UtilJson.parseDateTime(json['createTime']),
      updateTime: UtilJson.parseDateTime(json['updateTime']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'gameId': gameId,
      'status': status,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
    };

    if (notes != null) {
      data['notes'] = notes;
    }
    if (review != null) {
      data['review'] = review;
    }

    if (rating != null) {
      data['rating'] = rating;
    }

    return data;
  }
}
