// lib/models/game/collection/collection_form_data.dart

import 'package:suxingchahui/models/utils/util_json.dart';

import 'collection_item.dart';

class CollectionFormData {
  static const String setCollectionAction = "set";
  static const String removeCollectionAction = "remove";

  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyAction = 'action';
  static const String jsonKeyGameId = 'gameId';

  final String action;
  final CollectionItem? collectionItem;
  final String gameId;

  CollectionFormData({
    required this.action,
    required this.gameId,
    this.collectionItem,
  });

  factory CollectionFormData.fromJson(Map<String, dynamic> json) {
    final collectionItem = CollectionItem.fromJson(json);
    return CollectionFormData(
      action: UtilJson.parseStringSafely(json[jsonKeyAction]), // 使用常量
      collectionItem: collectionItem,
      gameId: collectionItem.gameId,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data;
    if (collectionItem != null) {
      data = collectionItem!.toJson();
      data[jsonKeyAction] = action;
    } else {
      data = {
        jsonKeyGameId: gameId,
        jsonKeyAction: action,
      };
    }

    return data;
  }

  Map<String, dynamic> toRequestJson() {
    Map<String, dynamic> data;
    if (collectionItem != null) {
      data = collectionItem!.toRequestJson();
    } else {
      data = {
        jsonKeyGameId: gameId,
      };
    }

    return data;
  }

  static CollectionFormData set({
    required String gameId,
    String? status,
    required String action,
    String? notes,
    String? review,
    double? rating,
  }) {
    if (status != null) {
      return CollectionFormData(
        action: action,
        gameId: gameId,
        collectionItem: CollectionItem(
          gameId: gameId,
          status: status,
          notes: notes,
          rating: rating,
          review: review,
        ),
      );
    } else {
      return CollectionFormData(
        action: action,
        gameId: gameId,
      );
    }
  }

  static CollectionFormData remove({
    required String gameId,
    required String action,
  }) {
    return CollectionFormData(
      action: action,
      gameId: gameId,
    );
  }

  String? get status => collectionItem?.status;
  String? get reviewContent => collectionItem?.review;
  String? get notes => collectionItem?.notes;
  double? get rating => collectionItem?.rating;
  DateTime? get createTime => collectionItem?.createTime;
  DateTime? get updateTime => collectionItem?.updateTime;

  bool get isSet => action == setCollectionAction;
  bool get isRemove => action == removeCollectionAction;
}
