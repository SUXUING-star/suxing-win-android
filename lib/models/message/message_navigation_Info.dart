// lib/models/message/message_navigation_Info.dart

import 'package:suxingchahui/models/game/game/game_detail_param.dart';
import 'package:suxingchahui/models/message/message.dart';
import 'package:suxingchahui/models/message/message_extension.dart';
import 'package:suxingchahui/routes/app_routes.dart';

/// 封装导航所需的信息
class MessageNavigationInfo {
  final String routeName;
  final Object? arguments;

  const MessageNavigationInfo({
    required this.routeName,
    this.arguments,
  });

  /// 获取此消息的导航信息 (如果可导航)
  /// 返回 null 表示此消息类型或状态下没有关联页面可跳转
  /// 注意: sourceItemId 如何影响导航，需要根据你的业务逻辑决定
  static MessageNavigationInfo? navigationDetails(Message message) {
    if (message.isPostReply) {
      if (message.postId != null && message.postId!.isNotEmpty) {
        return MessageNavigationInfo(
            routeName: AppRoutes.postDetail,
            arguments: {
              Message.jsonKeyPostId: message.postId,
            });
      }
    }

    if (message.isGameComment) {
      if (message.gameId != null && message.gameId!.isNotEmpty) {
        return MessageNavigationInfo(
          routeName: AppRoutes.gameDetail,
          arguments: GameDetailParam(gameId: message.gameId!),
        );
      }
    }

    if (message.isFollow) {
      if (message.senderId.isNotEmpty) {
        return MessageNavigationInfo(
            routeName: AppRoutes.openProfile, arguments: message.senderId);
      }
    }

    if (message.isGameNotification) {
      if (message.gameId != null && message.gameId!.isNotEmpty) {
        return MessageNavigationInfo(
          routeName: AppRoutes.gameDetail,
          arguments: GameDetailParam(gameId: message.gameId!),
        );
      }
    }
    if (message.isGameAction) {
      if (message.gameId != null && message.gameId!.isNotEmpty) {
        return MessageNavigationInfo(
          routeName: AppRoutes.gameDetail,
          arguments: GameDetailParam(gameId: message.gameId!),
        );
      }
    }

    return null;
  }
}
