// lib/models/message/enrich_message_type.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/preset/common_color_theme.dart';

class EnrichMessageType implements CommonColorThemeExtension {
  static const String messageTypeCommentToParentReply =
      "comment_to_reply"; // 用户在游戏的某个评论下收到了回复 (二级评论回复一级评论，一级评论的作者收到通知)
  static const String messageTypeCommentToGame =
      "comment_to_game"; // 游戏的作者收到了新的游戏评论 (评论人对游戏直接评论，游戏作者收到通知)

  static const List<String> gameCommentTypes = [
    messageTypeCommentToParentReply,
    EnrichMessageType.messageTypeCommentToGame,
  ];

  static const String messageTypePostReplyToPost =
      "post_reply_to_post"; // 帖子的作者收到了新的回复 (回复人回复楼主的帖子，楼主收到通知)
  static const String messageTypePostReplyToParentReply =
      "post_reply_to_reply"; // 用户在帖子的某个回复下收到了回复 (回复人回复评论人的评论，评论人收到通知)

  static const List<String> postReplyTypes = [
    messageTypePostReplyToPost,
    messageTypePostReplyToParentReply,
  ];

  // 社交相关的通知消息
  static const String messageTypeFollowToTargetUser =
      "follow_to_target_user"; // 用户被其他用户关注了

  static const List<String> followTypes = [
    messageTypeFollowToTargetUser,
  ];

  // 游戏审核相关的通知消息
  static const String messageTypeGameApprovedToAuthor =
      "game_approved_to_author"; // 用户提交的游戏通过了审核，通知作者
  static const String messageTypeGameRejectedToAuthor =
      "game_rejected_to_author"; // 用户提交的游戏被拒绝，通知作者
  static const String messageTypeGameResubmitToAdmin =
      "game_resubmit_to_admin"; // 用户重新提交了之前被拒绝的游戏，通知先前处理的管理员进行二次审核

  static const List<String> gameNotificationTypes = [
    messageTypeGameApprovedToAuthor,
    messageTypeGameRejectedToAuthor,
    messageTypeGameResubmitToAdmin,
  ];

  // 游戏互动相关的通知消息
  static const String messageTypeGameLikedToAuthor =
      "game_liked_to_author"; // 用户创建的游戏被点赞了，通知作者
  static const String messageTypeGameCoinedToAuthor =
      "game_coined_to_author"; // 用户创建的游戏被投币了，通知作者

  static const List<String> gameActionsTypes = [
    messageTypeGameLikedToAuthor,
    messageTypeGameCoinedToAuthor,
  ];

  final String type;

  EnrichMessageType({
    required this.type,
  });

  factory EnrichMessageType.fromType(String type) =>
      EnrichMessageType(type: type);

  @override
  Color getBackgroundColor() {
    return getTypeBackgroundColor(type);
  }

  @override
  IconData getIconData() {
    return getTypeIconData(type);
  }

  @override
  Color getTextColor() {
    return getTypeTextColor(type);
  }

  @override
  String getTextLabel() {
    return type;
  }

  static bool isGroup(String type, List<String> group) => group.contains(type);

  bool get isGameComment => isGroup(type, gameCommentTypes);

  bool get isPostReply => isGroup(type, postReplyTypes);

  bool get isFollow => isGroup(type, followTypes);

  bool get isGameAction => isGroup(type, gameActionsTypes);

  bool get isGameNotification => isGroup(type, gameNotificationTypes);

  static IconData getTypeIconData(String type) {
    switch (type) {
      case messageTypeCommentToParentReply:
      case messageTypeCommentToGame:
        return Icons.comment_outlined;
      case messageTypePostReplyToPost:
      case messageTypePostReplyToParentReply:
        return Icons.article_outlined;
      case messageTypeFollowToTargetUser:
        return Icons.person_add_alt_1_outlined;
      case messageTypeGameApprovedToAuthor:
        return Icons.check_circle_outline;
      case messageTypeGameRejectedToAuthor:
        return Icons.highlight_off_outlined;
      case messageTypeGameResubmitToAdmin:
        return Icons.hourglass_top_outlined; // 之前是 game_review_pending
      case messageTypeGameLikedToAuthor:
        return Icons.favorite_border_outlined;
      case messageTypeGameCoinedToAuthor:
        return Icons.monetization_on;
      default:
        return Icons.notifications_outlined;
    }
  }

  static Color getTypeTextColor(String type) {
    switch (type) {
      case messageTypeCommentToParentReply:
      case messageTypeCommentToGame:
        return Colors.blue[700]!;
      case messageTypePostReplyToPost:
      case messageTypePostReplyToParentReply:
        return Colors.indigo[700]!;
      case messageTypeFollowToTargetUser:
        return Colors.orange[800]!;
      case messageTypeGameApprovedToAuthor:
        return Colors.green[700]!;
      case messageTypeGameRejectedToAuthor:
        return Colors.red[700]!;
      case messageTypeGameResubmitToAdmin:
        return Colors.yellow[900]!;
      case messageTypeGameLikedToAuthor:
        return Colors.pink[700]!;
      case messageTypeGameCoinedToAuthor:
        return Colors.amber[700]!;
      default:
        return Colors.grey[800]!;
    }
  }

  /// 获取对应的背景颜色
  static Color getTypeBackgroundColor(String type) {
    switch (type) {
      case messageTypeCommentToParentReply:
      case messageTypeCommentToGame:
        return Colors.blue[100]!;
      case messageTypePostReplyToPost:
      case messageTypePostReplyToParentReply:
        return Colors.indigo[100]!;
      case messageTypeFollowToTargetUser:
        return Colors.orange[100]!;
      case messageTypeGameApprovedToAuthor:
        return Colors.green[100]!;
      case messageTypeGameRejectedToAuthor:
        return Colors.red[100]!;
      case messageTypeGameResubmitToAdmin:
        return Colors.yellow[200]!;
      case messageTypeGameLikedToAuthor:
        return Colors.pink[100]!;
      case messageTypeGameCoinedToAuthor:
        return Colors.amber[100]!;
      default:
        return Colors.grey[200]!;
    }
  }
}
