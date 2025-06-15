// lib/models/message/message.dart

import 'package:flutter/foundation.dart';
import 'package:suxingchahui/models/util_json.dart';
import 'package:suxingchahui/routes/app_routes.dart'; // 确保路径正确
import 'message_type.dart';

/// 封装导航所需的信息
@immutable
class MessageNavigationInfo {
  final String routeName;
  final Object? arguments;

  const MessageNavigationInfo({
    required this.routeName,
    this.arguments,
  });
}

/// 消息数据模型

@immutable
class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final String type; // 存储从后端获取的原始类型字符串
  final bool isRead;
  final DateTime createTime;
  final DateTime? updateTime; // 消息更新时间 (例如分组消息更新)
  final DateTime? readTime;
  final String? gameId; // 关联的游戏ID
  final String? postId; // 关联的帖子ID
  final String? sourceItemId; // 新增: 关联的源项目ID (例如被回复的评论ID，被回复的回复ID等)
  final int? groupCount; // 分组消息数量 (如果 > 1)
  final List<String> references;
  final String? lastContent; // 分组消息的最新内容摘要

  /// 解析后的消息类型枚举 (在构造函数中初始化)
  late final MessageType messageType;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.type, // 接收原始字符串
    required this.isRead,
    required this.createTime,
    this.updateTime,
    this.readTime,
    this.gameId,
    this.postId,
    this.sourceItemId, // 新增
    this.groupCount,
    List<String>? references,
    this.lastContent,
  }) : references = references ?? [] {
    // 在构造函数中解析并缓存 MessageType
    messageType = MessageTypeInfo.fromString(type);
    // 可以在这里添加一些断言或日志，帮助调试类型解析
    if (messageType == MessageType.unknown && kDebugMode && type.isNotEmpty) {
      // print('Debug: Message ID $id created with unknown type string: "$type"');
    }
  }

  /// 从 JSON 数据创建 Message 实例
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: UtilJson.parseId(json['_id'] ?? json['id']),
      senderId: UtilJson.parseId(json['senderId']),
      recipientId: UtilJson.parseId(json['recipientId']),
      content: UtilJson.parseStringSafely(json['content']),
      type: UtilJson.parseStringSafely(json['type']),
      isRead: json['isRead'] as bool? ?? false, // Dart 原生解析 bool 最简洁
      createTime: UtilJson.parseDateTime(json['createTime']),
      updateTime: UtilJson.parseNullableDateTime(json['updateTime']),
      readTime: UtilJson.parseNullableDateTime(json['readTime']),
      gameId: UtilJson.parseNullableId(json['gameId']),
      postId: UtilJson.parseNullableId(json['postId']),
      sourceItemId: UtilJson.parseNullableId(json['sourceItemId']),
      groupCount: UtilJson.parseIntSafely(json['groupCount']),
      references: UtilJson.parseListString(
          json['references']), // 已经改了 Message 字段为非空 List
      lastContent: UtilJson.parseNullableStringSafely(json['lastContent']),
    );
  }

  /// 将 Message 实例转换为 JSON (用于本地存储或调试)
  Map<String, dynamic> toJson() {
    return {
      'id': id, // 你可以选择用 '_id' 如果想和MongoDB字段名一致
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'type': type, // 存储原始类型字符串
      'isRead': isRead,
      'createTime': createTime.toUtc().toIso8601String(), // 存储为UTC ISO格式
      'updateTime': updateTime?.toUtc().toIso8601String(),
      'readTime': readTime?.toUtc().toIso8601String(),
      'gameId': gameId,
      'postId': postId,
      'sourceItemId': sourceItemId, // 新增
      'groupCount': groupCount,
      'references': references,
      'lastContent': lastContent,
    };
  }

  /// 获取用于列表预览的截断内容
  String getPreviewContent({int maxLength = 47}) {
    // 后端 GetPreviewContent 有特定逻辑，这里简化处理
    // 如果需要完全一致，需要把后端的Go逻辑翻译过来
    String source = lastContent ?? content;
    if (source.isEmpty) return "(无内容)";

    // 简单的截断
    if (source.length > maxLength) {
      return '${source.substring(0, maxLength)}...';
    }
    return source;
  }

  /// 判断是否为分组消息 (数量大于1)
  bool get isGrouped => (groupCount != null && groupCount! > 1);

  /// 获取消息用于排序和显示的最终时间 (优先使用更新时间)
  DateTime get displayTime => updateTime ?? createTime;

  /// 获取此消息的导航信息 (如果可导航)
  /// 返回 null 表示此消息类型或状态下没有关联页面可跳转
  /// 注意: sourceItemId 如何影响导航，需要根据你的业务逻辑决定
  MessageNavigationInfo? get navigationDetails {
    switch (messageType) {
      case MessageType.postReplyToPost:
      case MessageType.postReplyToParentReply: // 假设父回复也导航到帖子详情
        if (postId != null && postId!.isNotEmpty) {
          // 如果sourceItemId是父回复的ID，你可能想把它也传过去用于定位
          return MessageNavigationInfo(
            routeName: AppRoutes.postDetail,
            arguments: {'postId': postId, 'sourceItemId': sourceItemId}
                .removeNullValues(), // 示例
          );
        }
        break;

      case MessageType.commentToParentReply: // 回复的是评论
      case MessageType.commentToGame: // 评论的是游戏
        // 逻辑: sourceItemId 可能是被回复的评论ID，或者被评论的游戏/帖子ID
        // 优先判断postId，然后gameId。sourceItemId可以作为辅助参数。
        if (postId != null && postId!.isNotEmpty) {
          return MessageNavigationInfo(
            routeName: AppRoutes.postDetail,
            arguments: {'postId': postId, 'sourceItemId': sourceItemId}
                .removeNullValues(),
          );
        } else if (gameId != null && gameId!.isNotEmpty) {
          return MessageNavigationInfo(
            routeName: AppRoutes.gameDetail,
            arguments: {'gameId': gameId, 'sourceItemId': sourceItemId}
                .removeNullValues(),
          );
        }
        // 如果只有 sourceItemId，可能需要更复杂的逻辑来确定导航目标
        break;

      case MessageType.followTargetUser:
        if (senderId.isNotEmpty) {
          return MessageNavigationInfo(
              routeName: AppRoutes.openProfile, arguments: senderId);
        }
        break;

      case MessageType.gameApprovedToAuthor:
      case MessageType.gameRejectedToAuthor:
      case MessageType.gameResubmitToAdmin:
      case MessageType.gameCoinedToAuthor:
      case MessageType.gameLikedToAuthor:
        if (gameId != null && gameId!.isNotEmpty) {
          return MessageNavigationInfo(
              routeName: AppRoutes.gameDetail, arguments: gameId);
        }
        break;

      case MessageType.unknown:
        return null;
    }

    // if (kDebugMode && messageType != MessageType.unknown) {
    //   // print('Debug: Message ID $id (Type: $messageType, raw: "$type") did not generate navigation details.');
    // }
    return null;
  }

  /// 创建一个消息副本，可以覆盖某些字段
  /// 注意：当 `type` 字段被覆盖时，新实例的 `messageType` 会被重新计算
  Message copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? content,
    String? type,
    bool? isRead,
    DateTime? createTime,
    DateTime? updateTime,
    // 使用 ValueGetter 允许显式将 nullable 字段设置为 null
    // 例如: readTime: () => null 表示设置为null
    // readTime: () => newDateTime 表示设置为 newDateTime
    // 如果不传 readTime，则保持不变或根据 isRead 逻辑更新
    ValueGetter<DateTime?>? readTime,
    String? gameId,
    String? postId,
    String? sourceItemId, // 新增
    int? groupCount,
    List<String>? references,
    String? lastContent,
  }) {
    final newIsRead = isRead ?? this.isRead;
    DateTime? newReadTime;

    if (readTime != null) {
      // 如果显式传递了 readTime 的 ValueGetter
      newReadTime = readTime();
    } else if (isRead != null) {
      // 如果 isRead 状态改变了
      newReadTime = newIsRead ? (this.readTime ?? DateTime.now()) : null;
    } else {
      // isRead 和 readTime 都没有显式改变，保持原来的 readTime
      newReadTime = this.readTime;
    }

    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      type: type ?? this.type, // 使用新的或旧的原始 type 字符串
      isRead: newIsRead,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      readTime: newReadTime,
      gameId: gameId ?? this.gameId,
      postId: postId ?? this.postId,
      sourceItemId: sourceItemId ?? this.sourceItemId, // 新增
      groupCount: groupCount ?? this.groupCount,
      references: references ?? this.references,
      lastContent: lastContent ?? this.lastContent,
    );
  }

  // 为了方便比较和在 Set 中使用，可以重写 == 和 hashCode
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ValueGetter 定义，用于 copyWith 中处理 nullable 字段
typedef ValueGetter<T> = T Function();

// 扩展 Map 以方便移除 null 值的键，用于构造 arguments
extension MapUpdate<K, V> on Map<K, V> {
  Map<K, V> removeNullValues() {
    return Map.fromEntries(entries.where((entry) => entry.value != null));
  }
}
