// lib/widgets/game/tag/game_tags.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import '../../../../../../models/game/game.dart';
import '../../../../../../utils/navigation/navigation_utils.dart';

class GameTags extends StatelessWidget {
  final Game game;
  final double? fontSize;
  final bool wrap;
  final int? maxTags;
  final EdgeInsets? padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool navigateToGameListOnClick;

  const GameTags({
    super.key,
    required this.game,
    this.fontSize,
    this.wrap = true,
    this.maxTags,
    this.padding,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.navigateToGameListOnClick = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> tags = game.tags ;

    if (tags.isEmpty) {
      return SizedBox.shrink();
    }

    final displayTags = maxTags != null && tags.length > maxTags!
        ? tags.sublist(0, maxTags)
        : tags;

    // *** 修改这里，传递 context 给 _buildTag ***
    final tagWidgets = displayTags.map((tag) => _buildTag(context, tag)).toList();

    // 如果需要显示更多标签的指示器
    if (maxTags != null && tags.length > maxTags!) {
      tagWidgets.add(_buildMoreIndicator(context, tags.length - maxTags!));
    }

    if (wrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: tagWidgets,
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: tagWidgets.map((tag) {
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: tag,
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildTag(BuildContext context, String tag) {

    const int gamesListTabIndex = 1;
    // *** 使用 InkWell 包裹，使其可点击 ***
    return InkWell(
      onTap: !navigateToGameListOnClick ? null : () { // 根据新参数决定是否响应点击

        // 1. 更新 Provider 中的状态
        Provider.of<GameListFilterProvider>(context, listen: false).setTag(tag);

        // 2. 使用 navigateToHome 切换 Tab
        NavigationUtils.navigateToHome(context, tabIndex: gamesListTabIndex);
      },
      borderRadius: BorderRadius.circular(12), // 匹配 Container 的圆角
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: GameTagUtils.getTagColor(tag),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor.withSafeOpacity(0.3),
            width: 1,
          ),
        ),
        child: AppText(
          tag,
          style: TextStyle(
            fontSize: fontSize ?? 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // _buildMoreIndicator 不变
  Widget _buildMoreIndicator(BuildContext context, int moreCount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withSafeOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withSafeOpacity(0.3),
          width: 1,
        ),
      ),
      child: AppText(
        "+$moreCount",
        style: TextStyle(
          fontSize: fontSize ?? 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}