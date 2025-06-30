// lib/models/game/game/game_tag_stat.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/game/game/enrich_game_tag.dart';

import '../../extension/theme/preset/simple_color_theme.dart';

class GameTagStat implements SimpleColorThemeExtension {
  final int count;
  final String tag;

  GameTagStat({
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

extension GameTagStatExtension on GameTagStat {
  EnrichGameTag get enrichTag => EnrichGameTag.fromTag(tag);
}
