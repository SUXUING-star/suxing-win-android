class GlobalReplyItem {
  final String id;
  final String postId;
  final String postTitle;
  final String content;
  final String authorId;
  final DateTime createTime;

  GlobalReplyItem({
    required this.id,
    required this.postId,
    required this.postTitle,
    required this.content,
    required this.authorId,
    required this.createTime,
  });

  factory GlobalReplyItem.fromJson(Map<String, dynamic> json) {
    return GlobalReplyItem(
      id: json['id'],
      postId: json['postId'],
      postTitle: json['postTitle'] ?? '未知帖子',
      content: json['content'],
      authorId: json['authorId'],
      createTime: json['createTime'] is String
          ? DateTime.parse(json['createTime'])
          : json['createTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'postTitle': postTitle,
      'content': content,
      'authorId': authorId,
      'createTime': createTime.toIso8601String(),
    };
  }
}