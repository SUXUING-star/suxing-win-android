// lib/models/history.dart
import 'package:mongo_dart/mongo_dart.dart';

class History {
  final String id;
  final String userId;
  final String gameId;
  final DateTime lastViewTime;

  History({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.lastViewTime,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    String historyId = json['_id'] is ObjectId
        ? json['_id'].toHexString()
        : (json['_id']?.toString() ?? json['id']?.toString() ?? '');

    String gameId = json['gameId'] is ObjectId
        ? json['gameId'].toHexString()
        : json['gameId']?.toString() ?? '';

    String userId = json['userId'] is ObjectId
        ? json['userId'].toHexString()
        : json['userId']?.toString() ?? '';

    return History(
      id: historyId,
      userId: userId,
      gameId: gameId,
      lastViewTime: json['lastViewTime'] is DateTime
          ? json['lastViewTime']
          : DateTime.parse(json['lastViewTime'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'gameId': gameId,
      'lastViewTime': lastViewTime.toIso8601String(),
    };
  }
}