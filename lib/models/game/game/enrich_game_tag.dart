// lib/models/game/game/enrich_game_tag.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/preset/simple_color_theme.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class EnrichGameTag implements SimpleColorThemeExtension {
  final String tag;
  EnrichGameTag({
    required this.tag,
  });

  @override
  Color getTextColor() {
    return getTagTextColorForBackground(getTagBackgroundColor(tag));
  }

  @override
  Color getBackgroundColor() {
    return getTagBackgroundColor(tag);
  }

  @override
  String getTextLabel() {
    return tag;
  }

  /// 默认标签颜色列表。
  static const List<Color> _defaultTagColors = [
    Color(0xFF64B5F6),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFF4DB6AC),
    Color(0xFF7986CB),
    Color(0xFFBA68C8),
    Color(0xFFF06292),
    Color(0xFFE57373),
    Color(0xFFFF8A65),
    Color(0xFF90A4AE),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFF26C6DA),
    Color(0xFFAB47BC),
    Color(0xFFFFA726),
    Color(0xFF7E57C2),
    Color(0xFF5C6BC0),
    Color(0xFF78909C),
  ];

  /// 根据标签字符串的哈希值获取一个稳定的颜色。
  ///
  /// [tag]：标签字符串。
  /// 返回对应的颜色。
  static Color getTagBackgroundColor(String tag) {
    final colorIndex =
        tag.hashCode.abs() % _defaultTagColors.length; // 根据哈希值计算颜色索引
    return _defaultTagColors[colorIndex]; // 返回对应颜色
  }

  /// 根据背景颜色计算合适的文本颜色。
  ///
  /// [backgroundColor]：背景颜色。
  /// 返回白色。
  static Color getTagTextColorForBackground(Color color) {
    return Colors.white; // 返回白色
  }

  factory EnrichGameTag.fromTag(String tag) {
    return EnrichGameTag(
      tag: tag,
    );
  }

  static List<EnrichGameTag> fromTags(List<String>? tags) =>
      UtilJson.fromListStringToListObject(
        tags,
        (s) => EnrichGameTag.fromTag(s),
      );
}
