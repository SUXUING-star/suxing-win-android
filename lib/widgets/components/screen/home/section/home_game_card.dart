// lib/widgets/components/screen/home/section/home_game_card.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
// 废话不多说，先把大哥请过来
import 'package:suxingchahui/widgets/components/screen/game/card/base_game_card.dart';

/// 首页专用的游戏卡片，一个有固定尺寸的展示组件。
///
/// 这玩意儿也他妈的继承了 BaseGameCard，代码清爽得一批。
/// 它唯一的特殊之处就是需要一个固定的尺寸，所以我们重写了 build 方法，
/// 用一个 SizedBox 把大哥（BaseGameCard）的成果包起来。
class HomeGameCard extends BaseGameCard {
  /// 卡片的固定宽度
  static const double cardWidth = 160.0;
  /// 卡片的固定高度
  static const double cardHeight = 210;

  /// 构造函数。
  ///
  /// 接收 game 和 onTap，然后把一堆预设好的配置喂给大哥 BaseGameCard。
  const HomeGameCard({
    super.key,
    required super.game,
    VoidCallback? onTap,
  }) : super(
    // --- 把核心数据和回调传给大哥 ---
    onTapOverride: onTap, // 把自己的 onTap 传给大哥的 onTapOverride，完美对接

    // --- 根据 HomeGameCard 的样式，把参数写死 ---
    isGridItem: true, // 必须是网格布局
    showTags: true, // 首页卡片不显示那一长串标签
    maxTags: 1,
    showCollectionStats: true, // 封面上的统计数据要显示
    currentUser: null, // 没用户，禁用所有编辑/删除功能
    showNewBadge: false, // 不显示“新”徽章
    showUpdatedBadge: false, // 不显示“更新”徽章
  );

  /// 重写 build 方法，这是与 CommonGameCard 唯一的不同之处。
  ///
  /// 因为首页卡片需要固定大小，我们不能直接用大哥的 build 结果。
  /// 我们得先调用 `super.build(context)` 拿到大哥渲染好的卡片，
  /// 然后再用一个 `SizedBox`把它框在一个固定的尺寸里。
  @override
  Widget build(BuildContext context) {
    // 调用 super.build(context) 让大哥先把卡片UI造出来
    final Widget baseCardFromSuper = super.build(context);

    // 然后我们把大哥的作品放进一个固定大小的盒子里，搞定。
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Padding(
        // 这个 Padding 是为了让卡片之间有间距，因为SizedBox会撑满空间
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: baseCardFromSuper,
      ),
    );
  }
}