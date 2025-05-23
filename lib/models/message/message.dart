import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:suxingchahui/routes/app_routes.dart'; // 引入 AppRoutes 定义的常量
import 'message_type.dart'; // 引入 MessageType 和扩展

/// 封装导航所需的信息
class NavigationInfo {
  final String routeName; // 目标路由名称 (来自 AppRoutes)
  final Object? arguments; // 传递给目标路由的参数

  NavigationInfo({required this.routeName, this.arguments});
}

/// 消息数据模型
class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final String type; // 存储从后端获取的原始类型字符串
  final bool isRead;
  final DateTime createTime;
  final DateTime? readTime;
  final String? gameId;    // 关联的游戏ID
  final String? postId;    // 关联的帖子ID
  final int? groupCount;   // 分组消息数量 (如果 > 1)
  final List<String>? references; // 相关引用ID或摘要
  final String? lastContent; // 分组消息的最新内容摘要
  final DateTime? updateTime; // 消息更新时间 (例如分组消息更新)

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
    this.readTime,
    this.gameId,
    this.postId,
    this.groupCount,
    this.references,
    this.lastContent,
    this.updateTime,
  }) {
    // 在构造函数中解析并缓存 MessageType
    messageType = MessageTypeInfo.fromString(type);
    // 可以在这里添加一些断言或日志，帮助调试类型解析
    // assert(this.messageType != MessageType.unknown, 'Message ID $id has an unknown type string: $type');
    if (messageType == MessageType.unknown && kDebugMode) {
      // print('Debug: Message ID $id created with unknown type string: "$type"');
    }
  }

  /// 从 JSON 数据创建 Message 实例
  factory Message.fromJson(Map<String, dynamic> json) {
    // --- 复用你原来的安全解析函数 ---
    String safeParseId(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      try {
        if (value.toString().contains('ObjectId')) {
          final idStr = value.toString();
          final matches = RegExp(r'ObjectId\("([a-f0-9]{24})"\)').firstMatch(idStr);
          if (matches != null && matches.groupCount >= 1) return matches.group(1) ?? '';
        }
        return value.toHexString();
      } catch (e) {
        if (kDebugMode) print('Error parsing ID ($value): $e');
        return value.toString();
      }
    }

    DateTime safeParseDateTime(dynamic value) {
      if (value == null) return DateTime.now(); // 或者抛出错误？取决于业务
      if (value is DateTime) return value;
      if (value is String) {
        try { return DateTime.parse(value); } catch (e) {
          if (kDebugMode) print('Error parsing datetime string ($value): $e');
          return DateTime.now(); // 备用值
        }
      }
      try {
        final timestamp = int.tryParse(value.toString());
        if (timestamp != null) return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (e) { if (kDebugMode) print('Error parsing timestamp ($value): $e'); }
      return DateTime.now(); // 最终备用值
    }

    List<String>? safeParseReferences(dynamic value) {
      if (value == null) return null;
      if (value is List) return value.map((item) => item.toString()).toList();
      return null;
    }
    // --- 安全解析结束 ---

    String rawType = json['type'] ?? ''; // 获取原始类型字符串

    return Message(
      id: safeParseId(json['_id'] ?? json['id']),
      senderId: safeParseId(json['senderId']),
      recipientId: safeParseId(json['recipientId']),
      content: json['content'] ?? '',
      type: rawType, // 存储原始字符串
      isRead: json['isRead'] ?? false,
      createTime: safeParseDateTime(json['createTime']),
      readTime: json['readTime'] != null ? safeParseDateTime(json['readTime']) : null,
      gameId: json['gameId'] != null ? safeParseId(json['gameId']) : null,
      postId: json['postId'] != null ? safeParseId(json['postId']) : null,
      groupCount: json['groupCount'] is int ? json['groupCount'] : (int.tryParse(json['groupCount']?.toString() ?? '')), // 尝试转换
      references: safeParseReferences(json['references']),
      lastContent: json['lastContent'],
      updateTime: json['updateTime'] != null ? safeParseDateTime(json['updateTime']) : null,
    );
  }

  /// 将 Message 实例转换为 JSON (用于本地存储或调试)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'type': type, // 存储原始类型字符串
      'isRead': isRead,
      'createTime': createTime.toIso8601String(),
      'readTime': readTime?.toIso8601String(),
      'gameId': gameId,
      'postId': postId,
      'groupCount': groupCount,
      'references': references,
      'lastContent': lastContent,
      'updateTime': updateTime?.toIso8601String(),
    };
  }

  /// 获取用于列表预览的截断内容
  String getPreviewContent({int maxLength = 47}) {
    String source = lastContent ?? content; // 优先用 lastContent
    if (source.isEmpty) return "(无内容)"; // 处理空内容

    // 简单的截断逻辑
    if (source.length > maxLength + 3) { // +3 为 "..." 的长度
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
  NavigationInfo? get navigationDetails {
    switch (messageType) {
      case MessageType.postReply:
        if (postId != null && postId!.isNotEmpty) {
          return NavigationInfo(routeName: AppRoutes.postDetail, arguments: postId);
        }
        break; // 如果 postId 无效，则不导航

      case MessageType.commentReply:
      // 评论回复可能关联帖子或游戏，优先判断 postId
        if (postId != null && postId!.isNotEmpty) {
          return NavigationInfo(routeName: AppRoutes.postDetail, arguments: postId);
        } else if (gameId != null && gameId!.isNotEmpty) {
          // 假设评论回复也可以跳转到游戏详情 (需要确认业务逻辑)
          return NavigationInfo(routeName: AppRoutes.gameDetail, arguments: gameId);
        }
        break; // 如果 postId 和 gameId 都无效，则不导航

      case MessageType.follow_notification:
        if (senderId.isNotEmpty) {
          // 确保 senderId 不是接收者自己 (如果业务需要)
          // if (senderId != recipientId) {
          return NavigationInfo(routeName: AppRoutes.openProfile, arguments: senderId);
          // }
        }
        break; // 如果 senderId 无效，则不导航

      case MessageType.game_approved:
      case MessageType.game_rejected:
      case MessageType.game_review_pending:
        if (gameId != null && gameId!.isNotEmpty) {
          return NavigationInfo(routeName: AppRoutes.gameDetail, arguments: gameId);
        }
        break; // 如果 gameId 无效，则不导航

      case MessageType.unknown:
      // 未知类型通常不可导航
        return null;

    // 为其他需要导航的 MessageType 添加 case
    // case MessageType.someOtherType:
    //   if (/* 满足导航条件 */) {
    //     return NavigationInfo(routeName: AppRoutes.someRoute, arguments: /* 参数 */);
    //   }
    //   break;
    }

    // 如果没有任何 case 返回 NavigationInfo，则返回 null
    if (kDebugMode && messageType != MessageType.unknown) {
      // 对于已知类型但未能生成导航信息的，打印日志帮助排查
      // print('Debug: Message ID $id (Type: $messageType) did not generate navigation details.');
    }
    return null;
  }

  /// 创建一个消息副本，可以覆盖某些字段
  /// 注意：当 `type` 字段被覆盖时，新实例的 `messageType` 会被重新计算
  Message copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? content,
    String? type, // 允许传入新的原始类型字符串
    bool? isRead,
    DateTime? createTime,
    DateTime? readTime, // 允许直接设置已读时间
    String? gameId,
    String? postId,
    int? groupCount,
    List<String>? references,
    String? lastContent,
    DateTime? updateTime,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      type: type ?? this.type, // 使用新的或旧的原始 type 字符串
      isRead: isRead ?? this.isRead,
      createTime: createTime ?? this.createTime,
      // 注意 readTime 的处理: 如果 isRead 变为 true，应该设置 readTime；如果 isRead 变 false，应该清除 readTime
      readTime: (isRead ?? this.isRead)
          ? (readTime ?? (this.isRead ? this.readTime : DateTime.now())) // 如果已读，保留或设置新时间
          : null, // 如果未读，强制为 null
      gameId: gameId ?? this.gameId,
      postId: postId ?? this.postId,
      groupCount: groupCount ?? this.groupCount,
      references: references ?? this.references,
      lastContent: lastContent ?? this.lastContent,
      updateTime: updateTime ?? this.updateTime,
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