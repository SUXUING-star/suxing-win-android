// lib/models/game/collection/collection_item_extension.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/icon_data_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/game/collection/collection_item.dart';
import 'package:suxingchahui/models/game/collection/collection_status_extension.dart';

abstract class CollectionItemExtension {
  late CollectionItem collectionItem;
}

extension EasilyGetCollectionItemExtension<T extends CollectionItemExtension>
    on T {
  String get gameId => collectionItem.gameId;
  String get collectionStatus => collectionItem.status;
  String? get collectionReview => collectionItem.review;
  String? get collectionNotes => collectionItem.notes;
  double? get collectionRating => collectionItem.rating;
  DateTime? get collectionCreateTime => collectionItem.createTime;
  DateTime? get collectionUpdateTime => collectionItem.updateTime;

  IconData get collectionIcon => collectionItem.enrichCollectionStatus.iconData;
  Color get collectionTextColor =>
      collectionItem.enrichCollectionStatus.textColor;
  String get collectionTextLabel =>
      collectionItem.enrichCollectionStatus.textLabel;
  Color get collectionBackgroundColor =>
      collectionItem.enrichCollectionStatus.backgroundColor;

  bool get isPlayed => collectionStatus == CollectionItem.statusPlayed;
  bool get isPlaying => collectionStatus == CollectionItem.statusPlaying;
  bool get isWantToPlay => collectionStatus == CollectionItem.statusWantToPlay;
}
