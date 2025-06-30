// lib/models/activity/activity_extension.dart

import 'package:suxingchahui/models/activity/activity.dart';
import 'package:suxingchahui/models/activity/activity_target_navigation_route.dart';
import 'package:suxingchahui/models/activity/check_in_meta_detail.dart';

import 'enrich_activity_type.dart';

extension ActivityExtension on Activity {
  bool get isTargetGame => targetType == Activity.targetGame;
  bool get isTargetPost => targetType == Activity.targetPost;
  bool get isTargetUser => targetType == Activity.targetUser;

  String? get gameTitle => metadata?[Activity.metadataKeyGameTitle] as String?;
  String? get gameCoverImage =>
      metadata?[Activity.metadataKeyGameCoverImage] as String?;
  String? get postTitle => metadata?[Activity.metadataKeyPostTitle] as String?;
  String? get targetUsername =>
      metadata?[Activity.metadataKeyTargetUsername] as String?;
  String? get userRelationshipAction =>
      metadata?[Activity.metadataKeyUserRelationshipAction] as String?;

  CheckInActivityDetails? get checkInDetails {
    if (type == EnrichActivityType.checkIn && metadata != null) {
      try {
        return CheckInActivityDetails.fromMetadata(metadata!);
      } catch (e) {
        // print(
        //     "Error creating CheckInActivityDetails from UserActivity.metadata: $e. Metadata: $metadata");
        return null;
      }
    }
    return null;
  }

  /// 获取活动描述。
  ///
  /// [activity]：用户动态活动。
  /// 返回活动描述字符串。
  static String getActivityDescription(Activity activity) {
    switch (activity.type) {
      case EnrichActivityType.gameComment:
        return '评论了游戏 ${activity.gameTitle ?? '未知游戏'}';
      case EnrichActivityType.gameLike:
        return '点赞了游戏 ${activity.gameTitle ?? '未知游戏'}';
      case EnrichActivityType.postCreate:
        return '发布了帖子 ${activity.postTitle ?? '未知帖子'}';
      case EnrichActivityType.postReply:
        return '回复了帖子 ${activity.postTitle ?? '未知帖子'}';
      case EnrichActivityType.checkIn:
        return '完成了每日签到';
      case EnrichActivityType.collection:
        return '收藏了游戏 ${activity.gameTitle ?? '未知游戏'}';
      case EnrichActivityType.follow:
        return '关注了用户 ${activity.targetUsername ?? '未知用户'}';
      default:
        return '发布了动态';
    }
  }

  static String getActivityTargetText(Activity activity) {
    final String title;
    switch (activity.targetType) {
      case Activity.targetGame:
        title = '相关游戏';
        break;
      case Activity.targetPost:
        title = '相关帖子';
        break;
      case Activity.targetUser:
        title = '相关用户';
        break;
      default:
        title = '相关内容';
    }
    return title;
  }

  String get targetText => getActivityTargetText(this);

  String get descriptionByType => getActivityDescription(this);

  ActivityTargetNavigationRoute get targetNavigation =>
      ActivityTargetNavigationRoute.fromActivity(this);
  EnrichActivityType get enrichActivityType =>
      EnrichActivityType.fromType(type);
}
