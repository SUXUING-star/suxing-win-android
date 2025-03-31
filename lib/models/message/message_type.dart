import 'package:flutter/material.dart';
// 注意：这里不直接依赖 AppRoutes，导航信息在 Message 模型中处理
// import 'package:suxingchahui/routes/app_routes.dart';

/// 消息类型枚举
enum MessageType {
  commentReply,         // 评论收到回复
  postReply,            // 帖子收到回复
  follow_notification,  // 关注通知 (保持与后端一致)
  game_approved,        // 游戏审核通过
  game_rejected,        // 游戏审核拒绝
  game_review_pending,  // 游戏待审核
  unknown,              // 未知类型
  // 在此添加其他消息类型枚举...
}

/// MessageType 扩展，提供显示信息、图标和辅助方法
extension MessageTypeInfo on MessageType {

  /// 获取用户友好的中文显示名称
  String get displayName {
    switch (this) {
      case MessageType.commentReply: return '评论回复';
      case MessageType.postReply: return '帖子回复';
      case MessageType.follow_notification: return '关注通知';
      case MessageType.game_approved: return '游戏审核通过';
      case MessageType.game_rejected: return '游戏审核不通过';
      case MessageType.game_review_pending: return '游戏待审核';
      case MessageType.unknown: return '未知消息';
    // 为新增的枚举类型添加 case
    // default: return '系统消息'; // 可以为没有明确匹配的类型提供默认值
    }
  }

  /// 获取对应的图标
  IconData get iconData {
    switch (this) {
      case MessageType.commentReply: return Icons.comment_outlined;
      case MessageType.postReply: return Icons.article_outlined;
      case MessageType.follow_notification: return Icons.person_add_alt_1_outlined;
      case MessageType.game_approved: return Icons.check_circle_outline;
      case MessageType.game_rejected: return Icons.highlight_off_outlined;
      case MessageType.game_review_pending: return Icons.hourglass_top_outlined;
      case MessageType.unknown: return Icons.help_outline;
    // 为新增的枚举类型添加 case
    // default: return Icons.notifications_outlined;
    }
  }

  /// 获取对应的背景颜色 (用于 MessageDetail 标签等)
  Color get labelBackgroundColor {
    switch (this) {
      case MessageType.commentReply: return Colors.blue[100]!;
      case MessageType.postReply: return Colors.indigo[100]!; // 区分一下颜色
      case MessageType.follow_notification: return Colors.orange[100]!;
      case MessageType.game_approved: return Colors.green[100]!;
      case MessageType.game_rejected: return Colors.red[100]!;
      case MessageType.game_review_pending: return Colors.yellow[200]!; // 调亮一点
      case MessageType.unknown: return Colors.grey[300]!;
    // 为新增的枚举类型添加 case
    // default: return Colors.grey[200]!;
    }
  }

  /// 获取对应的文字颜色 (用于 MessageDetail 标签等)
  Color get labelTextColor {
    switch (this) {
      case MessageType.commentReply: return Colors.blue[700]!;
      case MessageType.postReply: return Colors.indigo[700]!;
      case MessageType.follow_notification: return Colors.orange[800]!; // 加深一点
      case MessageType.game_approved: return Colors.green[700]!;
      case MessageType.game_rejected: return Colors.red[700]!;
      case MessageType.game_review_pending: return Colors.yellow[900]!; // 再加深
      case MessageType.unknown: return Colors.grey[800]!;
    // 为新增的枚举类型添加 case
    // default: return Colors.grey[800]!;
    }
  }

  /// 将后端返回的字符串类型安全转换为 MessageType 枚举
  /// **重要:** 此方法需要根据你后端实际存储和返回的 `type` 字符串进行调整。
  static MessageType fromString(String? typeString) {
    if (typeString == null || typeString.isEmpty) {
      return MessageType.unknown;
    }

    // 示例：假设后端返回的是枚举的 .name (例如 "commentReply", "postReply")
    for (MessageType type in MessageType.values) {
      if (type.name == typeString) {
        return type;
      }
    }

    // 示例：如果后端返回的是自定义字符串（如下划线）
    // switch (typeString) {
    //   case 'comment_reply': return MessageType.commentReply;
    //   case 'post_reply': return MessageType.postReply;
    //   case 'follow_notification': return MessageType.follow_notification;
    //   case 'game_approved': return MessageType.game_approved;
    //   case 'game_rejected': return MessageType.game_rejected;
    //   case 'game_review_pending': return MessageType.game_review_pending;
    //   // ... 其他自定义类型映射
    //   default:
    //     print("警告: 未知的消息类型字符串 '$typeString', 返回 MessageType.unknown");
    //     return MessageType.unknown;
    // }

    // 如果以上都不匹配，作为未知类型处理
    print("警告: 未能将字符串 '$typeString' 匹配到任何 MessageType 枚举值, 返回 MessageType.unknown");
    return MessageType.unknown;
  }
}