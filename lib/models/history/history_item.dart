// lib/models/history_item.dart

class HistoryItem {
  final String id;
  final String itemId;
  final String userId;
  final DateTime lastViewTime;
  final String title;
  final String? coverImage;
  final int viewCount;
  final List<String> tags;
  final String authorId;
  final DateTime createTime;

  // 游戏特有字段
  final String? summary;
  final String? category;
  final int? likeCount;

  // 帖子特有字段
  final int? replyCount;
  final String? status;

  HistoryItem({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.lastViewTime,
    required this.title,
    this.coverImage,
    required this.viewCount,
    required this.tags,
    required this.authorId,
    required this.createTime,
    this.summary,
    this.category,
    this.likeCount,
    this.replyCount,
    this.status,
  });

  factory HistoryItem.fromGameJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? '',
      itemId: json['gameId'] ?? '',
      userId: json['authorId'] ?? '',
      lastViewTime: json['lastViewTime'] is DateTime
          ? json['lastViewTime']
          : DateTime.parse(json['lastViewTime']),
      title: json['title'] ?? '',
      summary: json['summary'],
      coverImage: json['coverImage'],
      category: json['category'],
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      authorId: json['authorId'] ?? '',
      createTime: json['createTime'] is DateTime
          ? json['createTime']
          : DateTime.parse(json['createTime']),
    );
  }

  factory HistoryItem.fromPostJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? '',
      itemId: json['postId'] ?? '',
      userId: json['authorId'] ?? '',
      lastViewTime: json['lastViewTime'] is DateTime
          ? json['lastViewTime']
          : DateTime.parse(json['lastViewTime']),
      title: json['title'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      replyCount: json['replyCount'] ?? 0,
      status: json['status'],
      tags: List<String>.from(json['tags'] ?? []),
      authorId: json['authorId'] ?? '',
      createTime: json['createTime'] is DateTime
          ? json['createTime']
          : DateTime.parse(json['createTime']),
    );
  }

  // 从API响应中创建游戏历史记录列表
  static List<HistoryItem> gameHistoryFromResponse(dynamic historyData) {
    if (historyData == null) return [];

    return (historyData as List)
        .map((item) => HistoryItem.fromGameJson(item))
        .toList();
  }

  // 从API响应中创建帖子历史记录列表
  static List<HistoryItem> postHistoryFromResponse(dynamic historyData) {
    if (historyData == null) return [];

    return (historyData as List)
        .map((item) => HistoryItem.fromPostJson(item))
        .toList();
  }
}