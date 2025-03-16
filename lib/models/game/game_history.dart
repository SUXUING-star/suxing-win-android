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
          : (json['_id'] ?? json['historyId'] ?? json['id'] ?? '').toString(),
      userId: json['userId'] is ObjectId
          ? json['userId'].toHexString()
          : (json['userId'] ?? '').toString(),
      gameId: json['gameId'] is ObjectId
          ? json['gameId'].toHexString()
          : json['gameId']?.toString() ?? json['itemId']?.toString() ?? '',
      lastViewTime: json['lastViewTime'] is DateTime
          ? json['lastViewTime']
          : (json['lastViewTime'] != null
          ? DateTime.parse(json['lastViewTime'].toString())
          : DateTime.now()),
    );
  }

  // 修改 GameHistory 的 toJson 方法
  Map<String, dynamic> toJson() {
    // 检查 ID 是否为有效的 ObjectId 格式
    bool isValidObjectId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);

    return {
      // 如果 ID 是有效的 ObjectId 格式，则转换为 ObjectId，否则使用字符串
      '_id': isValidObjectId ? ObjectId.fromHexString(id) : id,
      'userId': RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(userId)
          ? ObjectId.fromHexString(userId)
          : userId,
      'gameId': gameId,
      'lastViewTime': lastViewTime.toIso8601String(),
    };
  }
}