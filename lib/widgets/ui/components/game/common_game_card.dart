// lib/widgets/ui/components/common_game_card.dart

import 'package:suxingchahui/widgets/components/screen/game/card/base_game_card.dart';

/// 常规游戏卡片，一个纯粹的展示组件。
///
/// 这玩意儿现在牛逼了，直接继承 BaseGameCard。
/// 它就是一个预设好参数的 BaseGameCard，专门用来展示，
/// 把编辑、删除、新旧徽章这些花里胡哨的功能全都关了。
class CommonGameCard extends BaseGameCard {
  /// 构造函数。
  ///
  /// 它只接收展示所必需的参数，然后调用大哥（BaseGameCard）的构造函数，
  /// 并把那些不需要的功能参数全部设为 null 或 false。
  const CommonGameCard({
    super.key,
    required super.game,
    super.param,
    super.isGridItem,
    super.adaptForPanels,
    super.showTags,
    super.maxTags,
    super.forceCompact,
    super.onTapOverride,
  }) : super(
          // --- 核心在这儿：把 game 传给大哥 ---
          currentUser: null, // CommonCard 不需要知道当前用户，设为 null 就自动禁用了编辑/删除菜单
          onDeleteAction: null, // 禁用删除
          onEditAction: null, // 禁用编辑
          showNewBadge: false, // 不显示“新发布”徽章
          showUpdatedBadge: false, // 不显示“最近更新”徽章
          showCollectionStats: true, // 收藏数还是可以显示的，这个不影响
        );
}
