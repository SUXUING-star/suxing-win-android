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
    return PostHistory(
      id: json['_id'] is ObjectId
          ? json['_id'].toHexString()
          : (json['_id'] ?? '').toString(),
      userId: json['userId'] is ObjectId
          ? json['userId'].toHexString()
          : (json['userId'] ?? '').toString(),
      postId: json['postId'] ?? '',
      lastViewTime: json['lastViewTime'] is DateTime
          ? json['lastViewTime']
          : DateTime.parse(json['lastViewTime'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': ObjectId.fromHexString(id),
      'userId': ObjectId.fromHexString(userId),
      'postId': postId,
      'lastViewTime': lastViewTime.toIso8601String(),
    };
  }
}