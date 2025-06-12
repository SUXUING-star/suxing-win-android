// lib/models/game/game_collection_form_data.dart

import 'game_collection.dart';

class CollectionActionType {
  static const String setCollectionAction = "set";
  static const String removeCollectionAction = "remove";
}

class GameCollectionFormData {
  final String action;
  final String status;
  final String? notes;
  final String? review;
  final double? rating;

  GameCollectionFormData({
    required this.action,
    this.status = GameCollectionStatus.wantToPlay,
    this.notes,
    this.review,
    this.rating,
  });

  factory GameCollectionFormData.fromJson(Map<String, dynamic> json) {
    String status;
    if (json['status'] != null) {
      status = json['status'] ?? '';
    } else {
      status = '';
    }

    // 安全解析可空字段
    String? notes = json['notes'];
    String? review = json['review'];

    String action = json['action'] ?? 'unknown';

    // 安全解析评分
    double? rating;
    if (json['rating'] != null) {
      if (json['rating'] is num) {
        rating = (json['rating'] as num).toDouble();
      } else if (json['rating'] is String) {
        try {
          rating = double.parse(json['rating']);
        } catch (e) {
          // print('评分 "${json['rating']}" 不是有效的数字');
        }
      }
    }

    return GameCollectionFormData(
      action: action,
      status: status,
      notes: notes,
      review: review,
      rating: rating,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'action': action,
    };

    data['status'] = status;

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
