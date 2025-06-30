// lib/models/game/game/game_extension.dart

import 'package:suxingchahui/models/game/game/enrich_game_category.dart';
import 'package:suxingchahui/models/game/game/enrich_game_status.dart';
import 'package:suxingchahui/models/game/game/enrich_game_tag.dart';
import 'package:suxingchahui/models/game/game/game.dart';
import 'package:suxingchahui/models/utils/util_json.dart';
import 'package:suxingchahui/utils/share/share_utils.dart';

extension GameExtention on Game {
  String get toShareMessage => ShareUtils.generateShareMessage(
        id: id,
        title: title,
        shareType: ShareUtils.shareGame, // 明确告诉工具类，我分享的是个游戏
      );

  /// 判断游戏是否为创建时间一周内的新游戏。
  static bool isGameNew(Game game) {
    final now = DateTime.now(); // 当前时间
    final sevenDaysAgo = now.subtract(const Duration(days: 7)); // 七天前的时间
    return game.createTime.isAfter(sevenDaysAgo) &&
        game.createTime.isBefore(now); // 游戏创建时间在七天内
  }

  bool get isNewCreated => isGameNew(this);

  /// 判断游戏是否为更新时间一周内且非新游戏的更新游戏。
  static bool isGameRecentlyUpdated(Game game) {
    final now = DateTime.now(); // 当前时间
    final sevenDaysAgo = now.subtract(const Duration(days: 7)); // 七天前的时间
    if (isGameNew(game)) return false; // 如果是新游戏，则不是最近更新
    return game.updateTime.isAfter(sevenDaysAgo) &&
        game.updateTime.isBefore(now); // 游戏更新时间在七天内
  }

  bool get isRecentlyUpdated => isGameRecentlyUpdated(this);

  String? get neteaseMusicEmbedUrl => UtilJson.parseBvidToUrl(bvid);
  String? get bilibiliVideoUrl => UtilJson.parseNeteaseMusicUrl(musicUrl);

  EnrichGameCategory get enrichCategory =>
      EnrichGameCategory.fromCategory(category);

  EnrichGameStatus get enrichStatus =>
      EnrichGameStatus.fromStatus(approvalStatus);

  List<EnrichGameTag> get enrichTags => EnrichGameTag.fromTags(tags);
}
