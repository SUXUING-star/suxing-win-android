// lib/models/game/game_collection_review.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

@immutable
class GameCollectionReviewEntry {
  final String userId;
  final String gameId;
  final String status;
  final String? reviewContent;
  final double? rating;
  final String? notes;
  final DateTime createTime;
  final DateTime updateTime;

  const GameCollectionReviewEntry({
    required this.userId,
    required this.gameId,
    required this.status,
    this.reviewContent,
    this.rating,
    this.notes,
    required this.createTime,
    required this.updateTime,
  });

  factory GameCollectionReviewEntry.fromJson(Map<String, dynamic> json) {
    return GameCollectionReviewEntry(
      // 业务逻辑: userId 和 gameId 是 ObjectId
      userId: UtilJson.parseId(json['userId']),
      gameId: UtilJson.parseId(json['gameId']),
      status: UtilJson.parseStringSafely(json['status']),
      // 业务逻辑: json 里的键是 'review', 对应模型的 'reviewContent'
      reviewContent: UtilJson.parseNullableStringSafely(json['review']),
      rating: UtilJson.parseNullableDoubleSafely(json['rating']),
      notes: UtilJson.parseNullableStringSafely(json['notes']),
      createTime: UtilJson.parseDateTime(json['createTime']),
      updateTime: UtilJson.parseDateTime(json['updateTime']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'gameId': gameId,
        'status': status,
        'review': reviewContent,
        'rating': rating,
        'notes': notes,
        'createTime': createTime.toUtc().toIso8601String(),
        'updateTime': updateTime.toUtc().toIso8601String(),
      };
}
