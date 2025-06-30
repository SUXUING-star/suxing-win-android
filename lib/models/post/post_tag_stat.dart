// lib/models/post/post_tag_stat.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/post/enrich_post_tag.dart';

import '../extension/theme/preset/simple_color_theme.dart';

class PostTagStat implements SimpleColorThemeExtension {
  final int count;
  final String tag;

  PostTagStat({
    required this.tag,
    required this.count,
  });

  @override
  Color getBackgroundColor() => enrichTag.backgroundColor;

  @override
  Color getTextColor() => enrichTag.textColor;

  @override
  String getTextLabel() => enrichTag.textLabel;
}

extension PostTagStatExtension on PostTagStat {
  EnrichPostTag get enrichTag => EnrichPostTag.fromTag(tag);
}
