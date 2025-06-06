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



// 游戏收藏统计（单个游戏的收藏人数）
class GameCollectionStats {
  final int wantToPlayCount;
  final int playingCount;
  final int playedCount;
  final int totalCount;

  GameCollectionStats({
    required this.wantToPlayCount,
    required this.playingCount,
    required this.playedCount,
    required this.totalCount,
  });

  factory GameCollectionStats.fromJson(Map<String, dynamic> json) {
    // 安全地解析各个计数字段，确保类型正确
    int wantToPlayCount = 0;
    int playingCount = 0;
    int playedCount = 0;
    int totalCount = 0;

    // 尝试读取wantToPlayCount，确保类型转换
    if (json['wantToPlayCount'] != null) {
      if (json['wantToPlayCount'] is int) {
        wantToPlayCount = json['wantToPlayCount'];
      } else if (json['wantToPlayCount'] is num) {
        wantToPlayCount = (json['wantToPlayCount'] as num).toInt();
      } else if (json['wantToPlayCount'] is String) {
        try {
          wantToPlayCount = int.parse(json['wantToPlayCount']);
        } catch (e) {
          // print('无法解析wantToPlayCount: ${json['wantToPlayCount']}');
        }
      }
    }

    // 尝试读取playingCount，确保类型转换
    if (json['playingCount'] != null) {
      if (json['playingCount'] is int) {
        playingCount = json['playingCount'];
      } else if (json['playingCount'] is num) {
        playingCount = (json['playingCount'] as num).toInt();
      } else if (json['playingCount'] is String) {
        try {
          playingCount = int.parse(json['playingCount']);
        } catch (e) {
          // print('无法解析playingCount: ${json['playingCount']}');
        }
      }
    }

    // 尝试读取playedCount，确保类型转换
    if (json['playedCount'] != null) {
      if (json['playedCount'] is int) {
        playedCount = json['playedCount'];
      } else if (json['playedCount'] is num) {
        playedCount = (json['playedCount'] as num).toInt();
      } else if (json['playedCount'] is String) {
        try {
          playedCount = int.parse(json['playedCount']);
        } catch (e) {
          // print('无法解析playedCount: ${json['playedCount']}');
        }
      }
    }

    // 尝试读取totalCount，确保类型转换
    if (json['totalCount'] != null) {
      if (json['totalCount'] is int) {
        totalCount = json['totalCount'];
      } else if (json['totalCount'] is num) {
        totalCount = (json['totalCount'] as num).toInt();
      } else if (json['totalCount'] is String) {
        try {
          totalCount = int.parse(json['totalCount']);
        } catch (e) {
          //   print('无法解析totalCount: ${json['totalCount']}');
        }
      }
    } else {
      // 如果totalCount不存在，计算总和
      totalCount = wantToPlayCount + playingCount + playedCount;
    }

    return GameCollectionStats(
      wantToPlayCount: wantToPlayCount,
      playingCount: playingCount,
      playedCount: playedCount,
      totalCount: totalCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wantToPlayCount': wantToPlayCount,
      'playingCount': playingCount,
      'playedCount': playedCount,
      'totalCount': totalCount,
    };
  }

  @override
  String toString() {
    return 'GameCollectionStats{wantToPlayCount: $wantToPlayCount, playingCount: $playingCount, playedCount: $playedCount, totalCount: $totalCount}';
  }
}


