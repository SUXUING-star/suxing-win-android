// lib/models/game_history.dart
import 'package:mongo_dart/mongo_dart.dart';

class GameHistory {
  final String id;
  final String userId;
  final String gameId;
  final DateTime lastViewTime;

  GameHistory({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.lastViewTime,
  });

  factory GameHistory.fromJson(Map<String, dynamic> json) {
    return GameHistory(
      id: json['_id'] is ObjectId
          ? json['_id'].toHexString()
          : (json['_id'] ?? '').toString(),
      userId: json['userId'] is ObjectId
          ? json['userId'].toHexString()
          : (json['userId'] ?? '').toString(),
      gameId: json['gameId'] ?? '',
      lastViewTime: json['lastViewTime'] is DateTime
          ? json['lastViewTime']
          : DateTime.parse(json['lastViewTime'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': ObjectId.fromHexString(id),
      'userId': ObjectId.fromHexString(userId),
      'gameId': gameId,
      'lastViewTime': lastViewTime.toIso8601String(),
    };
  }
}