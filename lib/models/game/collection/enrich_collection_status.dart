// lib/models/game/collection/enrich_collection_status.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/preset/common_color_theme.dart';

import 'collection_item.dart';

class EnrichCollectionStatus implements CommonColorThemeExtension {
  //
  final String status;
  // 不构建实例

  EnrichCollectionStatus({
    required this.status,
  });

  factory EnrichCollectionStatus.fromStatus(String status) {
    return EnrichCollectionStatus(status: status);
  }

  @override
  IconData getIconData() {
    // <- 告诉底层的扩展魔法的施展方式
    final colorTheme = getTheme(status);
    return colorTheme.iconData;
  }

  @override
  Color getBackgroundColor() {
    // <- 告诉底层的扩展魔法的施展方式
    final colorTheme = getTheme(status);
    return colorTheme.backgroundColor;
  }

  @override
  Color getTextColor() {
    // <- 告诉底层的扩展魔法的施展方式
    final colorTheme = getTheme(status);
    return colorTheme.textColor;
  }

  @override
  String getTextLabel() {
    // <- 告诉底层的扩展魔法的施展方式
    final colorTheme = getTheme(status);
    return colorTheme.textLabel;
  }

  /// “想玩”状态的显示主题。
  static const CommonColorTheme wantToPlayTheme = CommonColorTheme(
    backgroundColor: Color(0xFFE6F0FF),
    textColor: Color(0xFF3D8BFF),
    iconData: Icons.star_border,
    textLabel: '想玩',
  );

  /// “在玩”状态的显示主题。
  static const CommonColorTheme playingTheme = CommonColorTheme(
    backgroundColor: Color(0xFFE8F5E9),
    textColor: Color(0xFF4CAF50),
    iconData: Icons.sports_esports,
    textLabel: '在玩',
  );

  /// “玩过”状态的显示主题。
  static CommonColorTheme playedTheme = CommonColorTheme(
    backgroundColor: Color(0xFFF3E5F5),
    textColor: Color(0xFF9C27B0),
    iconData: Icons.check_circle_outline,
    textLabel: '玩过',
  );

  /// “未知状态”的显示主题。
  static CommonColorTheme unknownTheme = CommonColorTheme(
    backgroundColor: Color(0xFFF5F5F5),
    textColor: Color(0xFF616161),
    iconData: Icons.bookmark_border,
    textLabel: '状态未知',
  );

  /// “评分”的显示主题。
  static CommonColorTheme ratingDisplayTheme = CommonColorTheme(
    backgroundColor: Color(0xFFFFF3E0),
    textColor: Color(0xFFF57C00),
    iconData: Icons.star,
    textLabel: '评分',
  );

  /// “总计”的显示主题。
  static CommonColorTheme totalTheme = CommonColorTheme(
    backgroundColor: Color(0xFFFFF8E1),
    textColor: Color(0xFFFFAB00),
    iconData: Icons.collections_bookmark_outlined,
    textLabel: '总计',
  );

  /// 根据状态字符串返回对应的显示主题。
  ///
  /// [status]：状态字符串。
  /// 返回对应的 `GameCollectionStatusTheme`。
  static CommonColorTheme getTheme(String? status) {
    status ??= '';
    switch (status) {
      case CollectionItem.statusWantToPlay:
        return wantToPlayTheme;
      case CollectionItem.statusPlaying:
        return playingTheme;
      case CollectionItem.statusPlayed:
        return playedTheme;
      default:
        return unknownTheme;
    }
  }

  static EnrichCollectionStatus wantToPlayCollection =
      EnrichCollectionStatus(status: CollectionItem.statusWantToPlay);
  static EnrichCollectionStatus playingCollection =
      EnrichCollectionStatus(status: CollectionItem.statusPlaying);
  static EnrichCollectionStatus playedCollection =
      EnrichCollectionStatus(status: CollectionItem.statusPlayed);

  static EnrichCollectionStatus totalCollection =
      EnrichCollectionStatus(status: CollectionItem.statusAll);
}
