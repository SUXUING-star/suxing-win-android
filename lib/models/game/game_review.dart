// 可以放在 lib/models/game/game_review.dart 或者 game_collection.dart 里

import 'package:intl/intl.dart'; // 可能需要用于日期解析

class GameReview {
  final String userId; // 后端返回的是 userID，在 Dart 中常用 userId
  final String review;
  final double? rating; // 评分可能是 null
  final String? notes;   // 笔记可能是 null
  final DateTime createTime;
  final DateTime updateTime;

  GameReview({
    required this.userId,
    required this.review,
    this.rating,
    this.notes,
    required this.createTime,
    required this.updateTime,
  });

  factory GameReview.fromJson(Map<String, dynamic> json) {
    // 安全地解析 userId (后端是 'userID', 类型是 primitive.ObjectID)
    String parsedUserId;
    if (json['userID'] is String) {
      parsedUserId = json['userID'];
    } else if (json['userID'] != null) {
      // 如果后端ObjectID转成了特殊对象，确保能拿到字符串形式
      parsedUserId = json['userID'].toString();
    } else {
      // 提供一个默认值或者抛出错误，取决于你的健壮性需求
      print("警告：GameReview.fromJson 收到无效或缺失的 userID: ${json['userID']}");
      parsedUserId = 'unknown_user_id'; // 或者 throw FormatException('Missing userID');
    }

    // 安全地解析评分 (可能是 int 或 double)
    double? parsedRating;
    final rawRating = json['rating'];
    if (rawRating is num) {
      parsedRating = rawRating.toDouble();
    } else if (rawRating is String) {
      parsedRating = double.tryParse(rawRating);
    }

    // 安全地解析日期 (后端是 ISO 8601 格式)
    DateTime parsedCreateTime;
    try {
      // 尝试直接解析，如果失败，可能需要指定格式或处理时区
      parsedCreateTime = DateTime.parse(json['createTime']).toLocal();
    } catch (e) {
      print("警告：解析 createTime 失败 ('${json['createTime']}'), 使用默认时间. 错误: $e");
      parsedCreateTime = DateTime.now(); // 提供默认值
    }

    DateTime parsedUpdateTime;
    try {
      parsedUpdateTime = DateTime.parse(json['updateTime']).toLocal();
    } catch (e) {
      print("警告：解析 updateTime 失败 ('${json['updateTime']}'), 使用默认时间. 错误: $e");
      parsedUpdateTime = DateTime.now(); // 提供默认值
    }


    return GameReview(
      userId: parsedUserId,
      review: json['review'] ?? '', // 提供默认空字符串
      rating: parsedRating,
      notes: json['notes'], // notes 可以为 null
      createTime: parsedCreateTime,
      updateTime: parsedUpdateTime,
    );
  }

  // (可选) 添加 toJson 方法，如果缓存服务需要序列化对象
  Map<String, dynamic> toJson() => {
    'userID': userId, // 保持和后端（或API响应）一致
    'review': review,
    'rating': rating,
    'notes': notes,
    'createTime': createTime.toUtc().toIso8601String(), // 存储时用 UTC
    'updateTime': updateTime.toUtc().toIso8601String(),
  };
}