// lib/models/post/enrich_post_tag.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/preset/simple_color_theme.dart';

class EnrichPostTag implements SimpleColorThemeExtension {
  final String tag;
  EnrichPostTag({
    required this.tag,
  });

  static const String all = '全部';
  static const String discussion = '讨论'; // 讨论标签
  static const String guide = '攻略'; // 攻略标签
  static const String sharing = '分享'; // 分享标签
  static const String help = '帮助'; // 求助标签
  static const String patch = '补丁'; // 补丁标签
  static const String other = '其他'; // 其他标签

  static const String fallbackDiscussion = 'discussion';
  static const String fallbackGuide = 'guide';
  static const String fallbackSharing = 'sharing';
  static const String fallbackHelp = 'help';
  static const String fallbackPatch = 'patch';
  static const String fallbackOther = 'other';
  static const String fallbackAll = 'all';
  static const List<String> availableTags = [
    discussion,
    guide,
    sharing,
    help,
    patch,
    other,
  ];

  static final List<EnrichPostTag> availableEnrichTags =
      fromTags(availableTags);

  static const List<String> filterTags = [
    all,
    ...availableTags,
  ];

  static final List<EnrichPostTag> filterEnrichTags = fromTags(filterTags);

  @override
  Color getBackgroundColor() {
    return getTagBackgroundColor(tag);
  }

  @override
  Color getTextColor() {
    final back = getTagBackgroundColor(tag);
    return getTextColorForBackground(back);
  }

  @override
  String getTextLabel() {
    return getTagTextLabel(tag);
  }

  /// 获取标签对应的颜色。
  static Color getTagBackgroundColor(String tag) {
    switch (tag) {
      case discussion || fallbackDiscussion:
        return const Color(0xFF4FC3F7);
      case guide || fallbackGuide:
        return const Color(0xFFFFB74D);
      case sharing || fallbackSharing:
        return const Color(0xFF81C784);
      case help || fallbackHelp:
        return const Color(0xFFE57373);
      case patch || fallbackPatch:
        return const Color(0xFFBA68C8);
      case other || fallbackOther:
      default:
        return const Color(0xFF90A4AE);
    }
  }

  /// 获取标签对应的显示文本（中文）。
  static String getTagTextLabel(String tag) {
    switch (tag) {
      case discussion || fallbackDiscussion:
        return discussion;
      case guide || fallbackGuide:
        return guide;
      case sharing || fallbackSharing:
        return sharing;
      case help || fallbackHelp:
        return help;
      case patch || fallbackPatch:
        return patch;
      case other || fallbackOther:
      default:
        return other;
    }
  }

  /// 根据背景颜色计算合适的文本颜色。
  ///
  /// [backgroundColor]：背景颜色。
  /// 返回黑色或白色，以确保文本可读性。
  static Color getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
  }

  factory EnrichPostTag.fromTag(String tag) {
    return EnrichPostTag(
      tag: tag,
    );
  }

  static List<EnrichPostTag> fromTags(List<String>? tags) {
    if (tags == null) return [];
    return tags.map((t) => EnrichPostTag.fromTag(t)).toList();
  }

  bool get isAll => tag == all;
}

extension PostTagExtention on String {
  bool get isAllTag =>
      this == EnrichPostTag.all || this == EnrichPostTag.fallbackAll;

  EnrichPostTag enrichTag() => EnrichPostTag.fromTag(this);
}
