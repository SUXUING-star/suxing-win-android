// lib/models/game/collection/collection_item.dart

// 游戏收藏状态常量
import 'package:flutter/cupertino.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/preset/common_color_theme.dart';
import 'package:suxingchahui/models/extension/theme/base/icon_data_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/game/collection/collection_status_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class CollectionItem extends CommonColorThemeExtension {
  static const String statusAll = "all";
  static const String statusWantToPlay = 'want_to_play';
  static const String statusPlaying = 'playing';
  static const String statusPlayed = 'played';

  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyGameId = 'gameId';
  static const String jsonKeyStatus = 'status';
  static const String jsonKeyNotes = 'notes';
  static const String jsonKeyReview = 'review';
  static const String jsonKeyRating = 'rating';
  static const String jsonKeyCreateTime = 'createTime';
  static const String jsonKeyUpdateTime = 'updateTime';

  final String gameId;
  final String status;
  final String? notes;
  final String? review;
  final double? rating;
  final DateTime? createTime;
  final DateTime? updateTime;

  CollectionItem({
    required this.gameId,
    required this.status,
    this.notes,
    this.review,
    this.rating,
    this.createTime,
    this.updateTime,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      gameId: UtilJson.parseId(json[jsonKeyGameId]), // 使用常量
      status: UtilJson.parseStringSafely(json[jsonKeyStatus]), // 使用常量
      notes: UtilJson.parseNullableStringSafely(json[jsonKeyNotes]), // 使用常量
      review: UtilJson.parseNullableStringSafely(json[jsonKeyReview]), // 使用常量
      rating: UtilJson.parseNullableDoubleSafely(json[jsonKeyRating]), // 使用常量
      createTime:
          UtilJson.parseNullableDateTime(json[jsonKeyCreateTime]), // 使用常量
      updateTime:
          UtilJson.parseNullableDateTime(json[jsonKeyUpdateTime]), // 使用常量
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      jsonKeyGameId: gameId, // 使用常量
      jsonKeyStatus: status, // 使用常量
      jsonKeyCreateTime: createTime?.toIso8601String(), // 使用常量
      jsonKeyUpdateTime: updateTime?.toIso8601String(), // 使用常量
    };

    if (notes != null) {
      data[jsonKeyNotes] = notes; // 使用常量
    }
    if (review != null) {
      data[jsonKeyReview] = review; // 使用常量
    }

    if (rating != null) {
      data[jsonKeyRating] = rating; // 使用常量
    }

    return data;
  }

  Map<String, dynamic> toRequestJson() {
    final Map<String, dynamic> data = {
      jsonKeyGameId: gameId, // 使用常量
      jsonKeyStatus: status, // 使用常量
    };

    if (notes != null) {
      data[jsonKeyNotes] = notes; // 使用常量
    }
    if (review != null) {
      data[jsonKeyReview] = review; // 使用常量
    }

    if (rating != null) {
      data[jsonKeyRating] = rating; // 使用常量
    }

    return data;
  }

  @override
  String getTextLabel() => enrichCollectionStatus.textLabel;

  @override
  Color getTextColor() => enrichCollectionStatus.textColor;

  @override
  Color getBackgroundColor() => enrichCollectionStatus.backgroundColor;

  @override
  IconData getIconData() => enrichCollectionStatus.iconData;
}
