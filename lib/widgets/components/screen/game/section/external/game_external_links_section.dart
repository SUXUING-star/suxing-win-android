// lib/widgets/components/screen/game/section/external/game_external_links_section.dart

/// 该文件定义了 GameExternalLinks 组件，用于显示游戏的外部链接列表。
/// 该组件展示游戏的外部链接，链接列表为空时显示空状态提示。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/game/game/game_external_link.dart';
import 'package:suxingchahui/widgets/components/screen/game/section/external/game_external_link_card.dart'; // 游戏外部链接卡片组件所需
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart'; // 空状态组件所需

/// `GameExternalLinks` 类：显示游戏外部链接列表的 StatelessWidget。
///
/// 该组件负责渲染游戏的所有外部链接卡片。
class GameExternalLinks extends StatelessWidget {
  final List<GameExternalLink> externalLinks; // 外部链接数据列表

  /// 构造函数。
  ///
  /// [externalLinks]：外部链接数据列表。
  const GameExternalLinks({
    super.key,
    required this.externalLinks,
  });

  /// 构建组件的 UI。
  ///
  /// [context]：Build 上下文。
  @override
  Widget build(BuildContext context) {
    if (externalLinks.isEmpty) {
      // 外部链接列表为空时显示空状态组件
      return const EmptyStateWidget(
        message: '暂无相关链接',
        iconData: Icons.link_off,
      );
    }

    // 返回一个包含所有链接卡片的 Column。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // 让卡片水平撑满
      children: externalLinks
          .map((link) => GameExternalLinkCard(link: link))
          .toList(),
    );
  }
}
