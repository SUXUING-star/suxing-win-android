// lib/models/message/message_type.dart
import 'package:flutter/material.dart';

/// 消息类型枚举 (与后端字符串对应)
enum MessageType {
  commentToParentReply, // 后端: "comment_to_reply" - 父评论收到回复
  commentToGame, // 后端: "comment_to_game" - 游戏收到评论/回复
  postReplyToPost, // 后端: "post_reply_to_post" - 帖子收到回复
  postReplyToParentReply, // 后端: "post_reply_reply" - (帖子的)父回复收到回复
  followTargetUser, // 后端: "follow_target_user" - 关注消息
  gameApprovedToAuthor, // 后端: "game_approved_to_author" - 游戏审核通过
  gameRejectedToAuthor, // 后端: "game_rejected_to_author" - 游戏审核拒绝
  gameResubmitToAdmin, // 后端: "game_resubmit_to_admin" - 游戏重新进入审核状态
  gameLikedToAuthor, // 后端: "game_liked_to_author" - 游戏被点赞
  gameCoinedToAuthor, // game_coined_to_author
  unknown, // 未知类型
}

/// MessageType 扩展，提供显示信息、图标和辅助方法
extension MessageTypeInfo on MessageType {
  /// 获取用户友好的中文显示名称
  String get displayName {
    switch (this) {
      case MessageType.commentToParentReply:
        return '评论有了新回复';
      case MessageType.commentToGame:
        return '游戏有了新评论'; // 或 '游戏收到回复'，根据实际业务
      case MessageType.postReplyToPost:
        return '帖子有了新回复';
      case MessageType.postReplyToParentReply:
        return '回复有了新回复';
      case MessageType.followTargetUser:
        return '新的关注';
      case MessageType.gameApprovedToAuthor:
        return '游戏已通过审核';
      case MessageType.gameRejectedToAuthor:
        return '游戏未通过审核';
      case MessageType.gameResubmitToAdmin:
        return '游戏已重新提交审核';
      case MessageType.gameLikedToAuthor:
        return '游戏收到了点赞';
      case MessageType.gameCoinedToAuthor:
        return '游戏收到了投币';
      case MessageType.unknown:
        // 确保总有一个返回值
        return '系统消息';
    }
  }

  /// 获取对应的图标
  IconData get iconData {
    switch (this) {
      case MessageType.commentToParentReply:
      case MessageType.commentToGame:
      case MessageType.postReplyToParentReply:
        return Icons.comment_outlined;
      case MessageType.postReplyToPost:
        return Icons.article_outlined;
      case MessageType.followTargetUser:
        return Icons.person_add_alt_1_outlined;
      case MessageType.gameApprovedToAuthor:
        return Icons.check_circle_outline;
      case MessageType.gameRejectedToAuthor:
        return Icons.highlight_off_outlined;
      case MessageType.gameResubmitToAdmin:
        return Icons.hourglass_top_outlined; // 之前是 game_review_pending
      case MessageType.gameLikedToAuthor:
        return Icons.favorite_border_outlined;
      case MessageType.gameCoinedToAuthor:
        return Icons.monetization_on;
      case MessageType.unknown:
        return Icons.notifications_outlined;
    }
  }

  /// 获取对应的背景颜色 (用于 MessageDetail 标签等)
  Color get labelBackgroundColor {
    switch (this) {
      case MessageType.commentToParentReply:
      case MessageType.commentToGame:
        return Colors.blue[100]!;
      case MessageType.postReplyToPost:
      case MessageType.postReplyToParentReply:
        return Colors.indigo[100]!;
      case MessageType.followTargetUser:
        return Colors.orange[100]!;
      case MessageType.gameApprovedToAuthor:
        return Colors.green[100]!;
      case MessageType.gameRejectedToAuthor:
        return Colors.red[100]!;
      case MessageType.gameResubmitToAdmin:
        return Colors.yellow[200]!;
      case MessageType.gameLikedToAuthor:
        return Colors.pink[100]!;
      case MessageType.gameCoinedToAuthor:
        return Colors.amber[100]!;
      case MessageType.unknown:
        return Colors.grey[200]!;
    }
  }

  /// 获取对应的文字颜色 (用于 MessageDetail 标签等)
  Color get labelTextColor {
    switch (this) {
      case MessageType.commentToParentReply:
      case MessageType.commentToGame:
        return Colors.blue[700]!;
      case MessageType.postReplyToPost:
      case MessageType.postReplyToParentReply:
        return Colors.indigo[700]!;
      case MessageType.followTargetUser:
        return Colors.orange[800]!;
      case MessageType.gameApprovedToAuthor:
        return Colors.green[700]!;
      case MessageType.gameRejectedToAuthor:
        return Colors.red[700]!;
      case MessageType.gameResubmitToAdmin:
        return Colors.yellow[900]!;
      case MessageType.gameLikedToAuthor:
        return Colors.pink[700]!;
      case MessageType.gameCoinedToAuthor:
        return Colors.amber[700]!;
      case MessageType.unknown:
        return Colors.grey[800]!;
    }
  }

  /// 将后端返回的字符串类型安全转换为 MessageType 枚举
  static MessageType fromString(String? typeString) {
    if (typeString == null || typeString.isEmpty) {
      return MessageType.unknown;
    }
    switch (typeString) {
      case "comment_to_reply":
        return MessageType.commentToParentReply;
      case "comment_to_game":
        return MessageType.commentToGame;
      case "post_reply_to_post":
        return MessageType.postReplyToPost;
      case "post_reply_reply": // 后端: MessageTypePostReplyToParentReply
        return MessageType.postReplyToParentReply;
      case "follow_target_user":
        return MessageType.followTargetUser;
      case "game_approved_to_author":
        return MessageType.gameApprovedToAuthor;
      case "game_rejected_to_author":
        return MessageType.gameRejectedToAuthor;
      case "game_resubmit_to_admin":
        return MessageType.gameResubmitToAdmin;
      case "game_liked_to_author":
        return MessageType.gameLikedToAuthor;
      case "game_coined_to_author":
        return MessageType.gameCoinedToAuthor;
      default:
        // if (kDebugMode) { // 仅在调试模式下打印未知类型警告
        //   print("警告: 未能将字符串 '$typeString' 匹配到任何 MessageType 枚举值, 返回 MessageType.unknown");
        // }
        return MessageType.unknown;
    }
  }
}
