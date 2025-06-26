// lib/models/game/game_collection_form_data.dart

import 'package:meta/meta.dart';
import 'package:suxingchahui/models/util_json.dart';

import 'game_collection_item.dart';



@immutable
class GameCollectionFormData {
  static const String setCollectionAction = "set";
  static const String removeCollectionAction = "remove";

  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyAction = 'action';
  static const String jsonKeyGameId = 'gameId';
  static const String jsonKeyStatus = 'status';
  static const String jsonKeyNotes = 'notes';
  static const String jsonKeyReview = 'review';
  static const String jsonKeyRating = 'rating';

  final String action;
  final String gameId;
  final String status;
  final String? notes;
  final String? review;
  final double? rating;

  const GameCollectionFormData({
    required this.action,
    required this.gameId,
    this.status = GameCollectionItem.statusWantToPlay,
    this.notes,
    this.review,
    this.rating,
  });

  factory GameCollectionFormData.fromJson(Map<String, dynamic> json) {
    return GameCollectionFormData(
      action: UtilJson.parseStringSafely(json[jsonKeyAction]), // 使用常量
      gameId: UtilJson.parseId(json[jsonKeyGameId]), // 使用常量
      status: UtilJson.parseStringSafely(json[jsonKeyStatus]), // 使用常量
      notes: UtilJson.parseNullableStringSafely(json[jsonKeyNotes]), // 使用常量
      review: UtilJson.parseNullableStringSafely(json[jsonKeyReview]), // 使用常量
      rating: UtilJson.parseNullableDoubleSafely(json[jsonKeyRating]), // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      jsonKeyAction: action, // 使用常量
      jsonKeyStatus: status, // 使用常量
      jsonKeyGameId: gameId, // 使用常量
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

  Map<String, dynamic> toRequestJson() {
    final Map<String, dynamic> data = {
      jsonKeyStatus: status, // 使用常量
      jsonKeyGameId: gameId, // 使用常量
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
