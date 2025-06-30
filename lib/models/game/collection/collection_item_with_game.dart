// lib/models/game/collection/collection_item_with_game.dart

import 'package:suxingchahui/models/game/collection/collection_item_extension.dart';
import 'package:suxingchahui/models/game/game/game.dart';
import 'package:suxingchahui/models/game/collection/collection_item.dart';
import 'package:suxingchahui/models/extension/json/to_json_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class CollectionItemWithGame implements ToJsonExtension, CollectionItemExtension {
  // 提取 JSON 字段名为 static const String 常量
  static const String jsonKeyGame = 'game';
  static const String jsonKeyGameCollection = 'collectionItem';

  final Game? game;
  @override
  late final CollectionItem collectionItem;

  CollectionItemWithGame({
    this.game,
    required this.collectionItem,
  });

  factory CollectionItemWithGame.fromJson(Map<String, dynamic> json) {
    return CollectionItemWithGame(
      game: Game.fromJson(json[jsonKeyGame] as Map<String, dynamic>),
      // 业务逻辑: GameCollectionItem 的字段直接在 GameWithCollection 的顶层 JSON 中，而不是嵌套在 'collection' 键下
      collectionItem: CollectionItem.fromJson(
          json[jsonKeyGameCollection] as Map<String, dynamic>),
    );
  }

  static List<CollectionItemWithGame> fromListJson(dynamic json) {
    return UtilJson.parseObjectList(
      json,
      (i) => CollectionItemWithGame.fromJson(i),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      jsonKeyGameCollection: collectionItem.toJson(),
    };

    // 使用常量引用
    if (game != null) {
      data[jsonKeyGame] = game!.toJson();
    } else {
      data[jsonKeyGame] = null;
    }
    return data;
  }
}
