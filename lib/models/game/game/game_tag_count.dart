// lib/models/game/game/game_tag_count.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/preset/simple_color_theme.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/game/game/enrich_game_tag.dart';
import 'package:suxingchahui/models/extension/json/to_json_extension.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class GameTagCount implements ToJsonExtension, SimpleColorThemeExtension {
  // 定义 JSON 字段的 static const String 常量
  static const String jsonKeyName = 'tag'; // JSON 字段名为 'tag' 对应 Dart 属性 'name'
  static const String jsonKeyCount = 'count';

  final String tagLabel;
  final int count;

  GameTagCount({
    required this.tagLabel,
    required this.count,
  });

  factory GameTagCount.fromJson(Map<String, dynamic> json) {
    return GameTagCount(
      tagLabel: UtilJson.parseStringSafely(json[jsonKeyName]), // 使用常量
      count: UtilJson.parseIntSafely(json[jsonKeyCount]), // 使用常量
    );
  }

  static List<GameTagCount> fromListJson(dynamic json) {
    return UtilJson.parseObjectList(
        json, (listJson) => GameTagCount.fromJson(listJson));
  }

  static List<String> fromObjectListToStringList(List<GameTagCount> list) {
    final newList = list.map((gt) {
      return gt.tagLabel;
    }).toList();
    return newList;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      jsonKeyName: tagLabel, // 使用常量
      jsonKeyCount: count, // 使用常量
    };
  }

  @override
  Color getBackgroundColor() => enrichTag.backgroundColor;

  @override
  Color getTextColor() => enrichTag.textColor;

  @override
  String getTextLabel() => enrichTag.textLabel;
}

extension GameTagCountExtension on GameTagCount {
  EnrichGameTag get enrichTag => EnrichGameTag.fromTag(tagLabel);
}
