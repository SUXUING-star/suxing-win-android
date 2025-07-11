// lib/models/message/message.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/preset/common_color_theme.dart';
import 'package:suxingchahui/models/extension/theme/base/icon_data_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/message/message_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

/// 消息数据模型

class Message implements CommonColorThemeExtension {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyId = 'id';
  static const String jsonKeyMongoId = '_id'; // MongoDB 默认的 _id 字段
  static const String jsonKeySenderId = 'senderId';
  static const String jsonKeyRecipientId = 'recipientId';
  static const String jsonKeyContent = 'content';
  static const String jsonKeyType = 'type';
  static const String jsonKeyIsRead = 'isRead';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyUpdateTime = 'updateTime';
  static const String jsonKeyReadTime = 'readTime';
  static const String jsonKeyGameId = 'gameId';
  static const String jsonKeyPostId = 'postId';
  static const String jsonKeySourceItemId = 'sourceItemId';
  static const String jsonKeyGroupCount = 'groupCount';
  static const String jsonKeyReferences = 'references';
  static const String jsonKeyLastContent = 'lastContent';

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
  }) : references = references ?? [];

  /// 从 JSON 数据创建 Message 实例
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: UtilJson.parseId(json[jsonKeyMongoId] ?? json[jsonKeyId]), // 使用常量
      senderId: UtilJson.parseId(json[jsonKeySenderId]), // 使用常量
      recipientId: UtilJson.parseId(json[jsonKeyRecipientId]), // 使用常量
      content: UtilJson.parseStringSafely(json[jsonKeyContent]), // 使用常量
      type: UtilJson.parseStringSafely(json[jsonKeyType]), // 使用常量
      isRead: json[jsonKeyIsRead] as bool? ?? false, // 使用常量
      createTime: UtilJson.parseDateTime(json[jsonKeyCreateTime]), // 使用常量
      updateTime:
          UtilJson.parseNullableDateTime(json[jsonKeyUpdateTime]), // 使用常量
      readTime: UtilJson.parseNullableDateTime(json[jsonKeyReadTime]), // 使用常量
      gameId: UtilJson.parseNullableId(json[jsonKeyGameId]), // 使用常量
      postId: UtilJson.parseNullableId(json[jsonKeyPostId]), // 使用常量
      sourceItemId: UtilJson.parseNullableId(json[jsonKeySourceItemId]), // 使用常量
      groupCount: UtilJson.parseIntSafely(json[jsonKeyGroupCount]), // 使用常量
      references: UtilJson.parseListString(json[jsonKeyReferences]), // 使用常量
      lastContent:
          UtilJson.parseNullableStringSafely(json[jsonKeyLastContent]), // 使用常量
    );
  }

  /// 将 Message 实例转换为 JSON (用于本地存储或调试)
  Map<String, dynamic> toJson() {
    return {
      jsonKeyId: id, // 使用常量
      jsonKeySenderId: senderId, // 使用常量
      jsonKeyRecipientId: recipientId, // 使用常量
      jsonKeyContent: content, // 使用常量
      jsonKeyType: type, // 使用常量
      jsonKeyIsRead: isRead, // 使用常量
      jsonKeyCreateTime: createTime.toUtc().toIso8601String(), // 使用常量
      jsonKeyUpdateTime: updateTime?.toUtc().toIso8601String(), // 使用常量
      jsonKeyReadTime: readTime?.toUtc().toIso8601String(), // 使用常量
      jsonKeyGameId: gameId, // 使用常量
      jsonKeyPostId: postId, // 使用常量
      jsonKeySourceItemId: sourceItemId, // 使用常量
      jsonKeyGroupCount: groupCount, // 使用常量
      jsonKeyReferences: references, // 使用常量
      jsonKeyLastContent: lastContent, // 使用常量
    };
  }

  @override
  String getTextLabel() => enrichMessageType.textLabel;

  @override
  Color getTextColor() => enrichMessageType.textColor;

  @override
  IconData getIconData() => enrichMessageType.iconData;

  @override
  Color getBackgroundColor() => enrichMessageType.backgroundColor;

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
