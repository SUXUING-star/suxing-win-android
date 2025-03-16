// lib/models/activity/user_activity_stats.dart

class UserActivityStats {
  final String userId;
  final int totalActivities;
  final int gameComments;
  final int gameLikes;
  final int gameCollections;
  final int postReplies;
  final int userFollows;
  final int checkIns;

  UserActivityStats({
    required this.userId,
    this.totalActivities = 0,
    this.gameComments = 0,
    this.gameLikes = 0,
    this.gameCollections = 0,
    this.postReplies = 0,
    this.userFollows = 0,
    this.checkIns = 0,
  });

  factory UserActivityStats.fromJson(Map<String, dynamic> json) {
    return UserActivityStats(
      userId: json['userId'] ?? '',
      totalActivities: json['totalActivities'] ?? 0,
      gameComments: json['gameComments'] ?? 0,
      gameLikes: json['gameLikes'] ?? 0,
      gameCollections: json['gameCollections'] ?? 0,
      postReplies: json['postReplies'] ?? 0,
      userFollows: json['userFollows'] ?? 0,
      checkIns: json['checkIns'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalActivities': totalActivities,
      'gameComments': gameComments,
      'gameLikes': gameLikes,
      'gameCollections': gameCollections,
      'postReplies': postReplies,
      'userFollows': userFollows,
      'checkIns': checkIns,
    };
  }
}