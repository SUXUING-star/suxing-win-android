// lib/models/game/game/game_details_response.dart

import 'package:suxingchahui/models/game/game/game.dart';
import 'package:suxingchahui/models/game/collection/collection_item.dart';
import 'package:suxingchahui/models/game/game/game_navigation_info.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class GameDetailsResponse {
  static const String jsonKeyGame = 'game';
  static const String jsonKeyCollectionStatus = 'collectionStatus';
  static const String jsonKeyNavigationInfo = 'navigation';
  static const String jsonKeyIsLiked = 'isLiked';
  static const String jsonKeyIsCoined = 'isCoined';

  final Game game;
  final CollectionItem? collectionStatus;
  final GameNavigationInfo? navigationInfo;
  final bool isLiked;
  final bool isCoined;

  GameDetailsResponse({
    required this.game,
    this.collectionStatus,
    this.navigationInfo,
    required this.isLiked,
    required this.isCoined,
  });

  factory GameDetailsResponse.fromJson(dynamic response) {
    if (response is Map) {
      final json = Map<String, dynamic>.from(response);
      return GameDetailsResponse(
        game: Game.fromJson(json[jsonKeyGame]),
        isLiked: UtilJson.parseBoolSafely(json[jsonKeyIsLiked]),
        isCoined: UtilJson.parseBoolSafely(json[jsonKeyIsCoined]),
        navigationInfo:
            GameNavigationInfo.fromJson(json[jsonKeyNavigationInfo]),
        collectionStatus:
            CollectionItem.fromJson(json[jsonKeyCollectionStatus]),
      );
    }
    return GameDetailsResponse.empty();
  }

  static GameDetailsResponse empty() {
    return GameDetailsResponse(
      game: Game.empty(),
      isLiked: false,
      isCoined: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonKeyGame: game.toJson(),
      jsonKeyIsLiked: isLiked,
      jsonKeyIsCoined: isCoined,
      jsonKeyCollectionStatus: collectionStatus?.toJson(),
      jsonKeyNavigationInfo: navigationInfo?.toJson(),
    };
  }
}
