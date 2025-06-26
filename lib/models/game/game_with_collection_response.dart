// lib/models/game/game_with_collection_response.dart

import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection_item.dart';
import 'package:suxingchahui/models/game/game_navigation_info.dart';

class GameDetailsWithStatus {
  final Game game;
  final GameCollectionItem? collectionStatus;
  final GameNavigationInfo? navigationInfo;
  final bool isLiked;
  final bool isCoined;

  GameDetailsWithStatus({
    required this.game,
    this.collectionStatus,
    this.navigationInfo,
    required this.isLiked,
    required this.isCoined,
  });
}
