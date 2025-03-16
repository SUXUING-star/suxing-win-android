// lib/models/post_history.dart
import 'package:mongo_dart/mongo_dart.dart';

class PostHistory {
  final String id;
  final String userId;
  final String postId;
  final DateTime lastViewTime;

  PostHistory({
    required this.id,
    required this.userId,
    required this.postId,
    required this.lastViewTime,
  });

  factory PostHistory.fromJson(Map<String, dynamic> json) {
    // Handle both direct history item format and nested format from backend
    String itemId = '';
    DateTime viewTime;

    if (json.containsKey('itemId')) {
      // Direct format from history item
      itemId = json['itemId'] is ObjectId
          ? json['itemId'].toHexString()
          : (json['itemId'] ?? '').toString();
      viewTime = json['lastViewTime'] is DateTime
          ? json['lastViewTime']
          : DateTime.parse(json['lastViewTime'].toString());
    } else {
      // Format from backend history API
      itemId = json['postId'] is ObjectId
          ? json['postId'].toHexString()
          : (json['postId'] ?? '').toString();
      viewTime = json['lastViewTime'] is DateTime
          ? json['lastViewTime']
          : DateTime.parse(json['lastViewTime'].toString());
    }

    return PostHistory(
      id: json['_id'] is ObjectId
          ? json['_id'].toHexString()
          : (json['_id'] ?? '').toString(),
      userId: json['userId'] is ObjectId
          ? json['userId'].toHexString()
          : (json['userId'] ?? '').toString(),
      postId: itemId,
      lastViewTime: viewTime,
    );
  }

  // 修改 PostHistory 的 toJson 方法
  Map<String, dynamic> toJson() {
    // 检查 ID 是否为有效的 ObjectId 格式
    bool isValidObjectId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);

    return {
      // 如果 ID 是有效的 ObjectId 格式，则转换为 ObjectId，否则使用字符串
      '_id': isValidObjectId ? ObjectId.fromHexString(id) : id,
      'userId': RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(userId)
          ? ObjectId.fromHexString(userId)
          : userId,
      'postId': postId,
      'lastViewTime': lastViewTime.toIso8601String(),
    };
  }
}