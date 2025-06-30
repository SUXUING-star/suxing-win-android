// lib/models/game/collection/collection_item_response.dart

import 'package:suxingchahui/models/game/collection/collection_item_extension.dart';
import 'package:suxingchahui/models/game/collection/collection_item.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class CollectionItemResponse implements CollectionItemExtension {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyUserId = 'userId';

  final String userId;
  @override
  late final CollectionItem collectionItem;

  CollectionItemResponse({
    required this.userId,
    required this.collectionItem,
  });

  factory CollectionItemResponse.fromJson(Map<String, dynamic> json) {
    return CollectionItemResponse(
      // 业务逻辑: userId 和 gameId 是 ObjectId
      userId: UtilJson.parseId(json[jsonKeyUserId]),
      collectionItem: CollectionItem.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = collectionItem.toJson();
    map[jsonKeyUserId] = userId;
    return map;
  }

  static List<CollectionItemResponse> fromListJson(json) {
    return UtilJson.parseObjectList<CollectionItemResponse>(
      json, // 使用常量
      (itemJson) => CollectionItemResponse.fromJson(
          itemJson), // 告诉它怎么把一个 item 的 json 转成 GameCollectionReviewEntry 对象
    );
  }

  factory CollectionItemResponse.fromGameCollectionItem({
    required CollectionItem item,
    required String userId,
  }) {
    return CollectionItemResponse(
      // 构建新的或更新的评价条目
      userId: userId,
      collectionItem: item,
    );
  }
}
