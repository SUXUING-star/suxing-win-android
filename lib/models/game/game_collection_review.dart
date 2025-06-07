// lib/models/game/game_collection_review.dart

class GameCollectionReviewEntry {
  final String userId;
  final String gameId;
  final String status;
  final String? reviewContent;
  final double? rating;
  final String? notes;
  final DateTime createTime;
  final DateTime updateTime;

  GameCollectionReviewEntry({
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
    String parsedUserId = json['userId']?.toString() ?? 'unknown_user_id';
    String parsedGameId = json['gameId']?.toString() ?? 'unknown_game_id';
    String parsedStatus = json['status'] ?? 'unknown';

    double? parsedRating;
    final rawRating = json['rating'];
    if (rawRating is num) {
      parsedRating = rawRating.toDouble();
    } else if (rawRating is String) {
      parsedRating = double.tryParse(rawRating);
    }

    DateTime parsedCreateTime = DateTime.now();
    if (json['createTime'] is String) {
      try {
        parsedCreateTime = DateTime.parse(json['createTime']).toLocal();
      } catch (e) {
        // print("Warning: Failed to parse createTime ('${json['createTime']}'), using default. Error: $e");
      }
    }

    DateTime parsedUpdateTime = DateTime.now();
    if (json['updateTime'] is String) {
      try {
        parsedUpdateTime = DateTime.parse(json['updateTime']).toLocal();
      } catch (e) {
        // print("Warning: Failed to parse updateTime ('${json['updateTime']}'), using default. Error: $e");
      }
    }

    return GameCollectionReviewEntry(
      userId: parsedUserId,
      gameId: parsedGameId,
      status: parsedStatus,
      reviewContent: json['review'],
      rating: parsedRating,
      notes: json['notes'],
      createTime: parsedCreateTime,
      updateTime: parsedUpdateTime,
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