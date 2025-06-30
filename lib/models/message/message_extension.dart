// lib/models/message/message_extension.dart

import 'package:suxingchahui/models/message/enrich_message_type.dart';
import 'package:suxingchahui/models/message/message.dart';
import 'package:suxingchahui/models/message/message_navigation_Info.dart';

extension MessageExtension on Message {
  EnrichMessageType get enrichMessageType => EnrichMessageType.fromType(type);

  bool get isTargetGame => gameId != null;

  bool get isTargetPost => postId != null;

  bool get isGameComment => enrichMessageType.isGameComment;

  bool get isPostReply => enrichMessageType.isPostReply;

  bool get isFollow => enrichMessageType.isFollow;

  bool get isGameAction => enrichMessageType.isGameAction;

  bool get isGameNotification => enrichMessageType.isGameNotification;

  MessageNavigationInfo? get navigationInfo =>
      MessageNavigationInfo.navigationDetails(this);
}
