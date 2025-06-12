// lib/models\game\game_collection.dart

// 游戏收藏状态常量
class GameCollectionStatus {
  static const String all = "all";
  static const String wantToPlay = 'want_to_play'; // 修改为与后端一致
  static const String playing = 'playing';
  static const String played = 'played';
}

class GameCollectionItem {
  final String gameId;
  final String status;
  final String? notes;
  final String? review;
  final double? rating;
  final DateTime createTime;
  final DateTime updateTime;

  GameCollectionItem({
    required this.gameId,
    required this.status,
    this.notes,
    this.review,
    this.rating,
    required this.createTime,
    required this.updateTime,
  });

  factory GameCollectionItem.fromJson(Map<String, dynamic> json) {
    // 确保gameId是字符串
    String gameId;
    if (json['gameId'] is String) {
      gameId = json['gameId'];
    } else if (json['gameId'] != null) {
      // 可能是ObjectId对象，转为字符串
      gameId = json['gameId'].toString();
    } else {
      throw FormatException('GameCollectionItem缺少gameId字段');
    }

    // 获取状态，使用默认值
    String status = json['status'] ?? 'unknown';

    // 安全解析日期
    DateTime createTime;
    DateTime updateTime;

    try {
      createTime = DateTime.parse(json['createTime']);
    } catch (e) {
      // print('解析createTime失败: ${json['createTime']}，使用当前时间');
      createTime = DateTime.now();
    }

    try {
      updateTime = DateTime.parse(json['updateTime']);
    } catch (e) {
      // print('解析updateTime失败: ${json['updateTime']}，使用当前时间');
      updateTime = DateTime.now();
    }

    // 安全解析可空字段
    String? notes = json['notes'];
    String? review = json['review'];

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

    return GameCollectionItem(
      gameId: gameId,
      status: status,
      notes: notes,
      review: review,
      rating: rating,
      createTime: createTime,
      updateTime: updateTime,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'gameId': gameId,
      'status': status,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
    };

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


