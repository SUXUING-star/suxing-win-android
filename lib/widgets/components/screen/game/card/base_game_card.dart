// 这是定制ui游戏卡片
// lib/widgets/components/screen/game/card/base_game_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 需要 Provider 获取 AuthProvider
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 需要 AuthProvider 判断权限
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/custom_popup_menu_button.dart'; // 引入自定义菜单按钮
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';
import '../../../../../models/game/game.dart';
import '../../../../../routes/app_routes.dart'; // 需要路由
import '../../../../../utils/device/device_utils.dart';
import '../../../../ui/image/safe_cached_image.dart';
import 'game_category_tag.dart';
import 'game_stats_widget.dart';
import 'game_tag_list.dart';
import 'game_collection_dialog.dart'; // 保留，用于显示收藏统计

/// 基础游戏卡片组件，提供共享的UI结构和功能
class BaseGameCard extends StatelessWidget {
  final Game game;
  final bool isGridItem;
  final bool adaptForPanels;
  final bool showTags;
  final int maxTags;
  final bool forceCompact;
  final bool showCollectionStats;
  final VoidCallback? onDeleteAction; // 删除按钮点击回调
  // final VoidCallback? onEditAction; // 编辑按钮点击回调
  // 通常gamelist后端返回的字段里不包含description字段，所以直接进行编辑回调，这里的game有些字段会缺失

  const BaseGameCard({
    Key? key,
    required this.game,
    this.isGridItem = true,
    this.adaptForPanels = false,
    this.showTags = true,
    this.maxTags = 2,
    this.forceCompact = false,
    this.showCollectionStats = true,
    this.onDeleteAction,
    //this.onEditAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- 新增加的保险判断 ---
    // 如果游戏状态是 'pending' (待审核)，则不显示此卡片
    if (game.approvalStatus == 'pending') {
      // 返回一个空的、不占空间的Widget
      return const SizedBox.shrink();
    } else {
      return isGridItem ? _buildGridCard(context) : _buildListCard(context);
    }
  }

  // --- 列表布局卡片 ---
  Widget _buildListCard(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop; // 传入 context
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _onCardTap(context), // 点击卡片跳转详情
        child: IntrinsicHeight(
          // 确保 Row 子项等高
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 子项垂直拉伸
            children: [
              _buildGameCover(context, isDesktop), // 左侧封面
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _buildGameInfo(context), // 右侧信息
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 网格布局卡片 ---
  Widget _buildGridCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onCardTap(context), // 点击卡片跳转详情
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图区域 (Expanded)
            Expanded(
              flex: 3, // 根据需要调整比例
              child: Stack(
                fit: StackFit.expand, // 图片填满区域
                children: [
                  SafeCachedImage(
                      imageUrl: game.coverImage, fit: BoxFit.cover), // 封面图
                  Positioned(
                      top: 8,
                      left: 8,
                      child: GameCategoryTag(category: game.category)), // 类别
                  Positioned(
                      top: 4,
                      right: 4,
                      child: _buildPopupMenu(context)), // <--- 添加菜单按钮
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      // 包裹统计信息以便点击
                      onTap: () {
                        if (showCollectionStats && game.totalCollections > 0) {
                          showGameCollectionDialog(context, game);
                        }
                      },
                      child: GameStatsWidget(
                          game: game,
                          showCollectionStats: showCollectionStats,
                          isGrid: true),
                    ),
                  ),
                ],
              ),
            ),
            // 游戏信息区域 (Expanded)
            Expanded(
              flex: 3, // 根据需要调整比例
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildGridInfoSection(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 构建封面图 (通用) ---
  Widget _buildGameCover(BuildContext context, bool isDesktop) {
    final coverWidth = isDesktop ? 120.0 : 100.0;
    return SizedBox(
      // 使用 SizedBox 限制大小
      width: coverWidth,
      // height: double.infinity, // 在 Row 中由 IntrinsicHeight 控制高度
      child: Stack(
        fit: StackFit.expand, // 图片填满 SizedBox
        children: [
          SafeCachedImage(
            imageUrl: game.coverImage,
            fit: BoxFit.cover,
            memCacheWidth: isDesktop ? 240 : 200,
            backgroundColor: Colors.grey[200],
          ),
          Positioned(
              top: 8, left: 8, child: GameCategoryTag(category: game.category)),
        ],
      ),
    );
  }

  // --- 构建游戏信息 (列表布局) ---
  Widget _buildGameInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 让内容上下分布
      children: [
        // 顶部：标题和操作按钮
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
          children: [
            Expanded(
              child: Text(
                game.title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // --- !!! 列表布局右上角操作按钮 !!! ---
            _buildPopupMenu(context), // <--- 添加菜单按钮
          ],
        ),
        // 中部：描述和标签 (如果空间允许)
        if (game.summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              game.summary,
              style:
                  TextStyle(fontSize: 10, color: Colors.grey[700], height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (showTags && game.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2.0, bottom: 4.0), // 调整间距
            child: GameTagList(tags: game.tags, maxTags: maxTags),
          ),
        // 底部：统计信息 (使用 Spacer 推到底部)
        // Spacer(), // 如果上面内容可能为空，Spacer 会有问题，改为 MainAxisAlignment.spaceBetween
        GestureDetector(
          onTap: () {
            if (showCollectionStats && game.totalCollections > 0) {
              showGameCollectionDialog(context, game);
            }
          },
          child: GameStatsWidget(
              game: game,
              showCollectionStats: showCollectionStats,
              isGrid: false),
        ),
      ],
    );
  }

  // --- 构建游戏信息 (网格布局) ---
  Widget _buildGridInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 上下分布
      children: [
        // 顶部标题和描述
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(game.title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: 4),
            Text(game.summary,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        // 底部标签
        if (showTags && game.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 0), // 调整间距
            // 网格布局标签不需要 Expanded
            child: GameTagList(
                tags: game.tags, maxTags: maxTags, isScrollable: true),
          ),
      ],
    );
  }

  // 卡片点击事件
  void _onCardTap(BuildContext context) {
    NavigationUtils.pushNamed(
      context,
      '/game/detail',
      arguments: game,
    );
  }

  // --- !!! 构建右上角弹出菜单 !!! ---
  Widget _buildPopupMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;
    final canModify = (game.authorId.toString() == currentUserId) || isAdmin;
    // *** 直接检查 onDeleteAction 是否非 null ***
    final hasDeleteAction = onDeleteAction != null;

    // 如果不能修改或者没有删除回调，不显示
    if (!canModify || !hasDeleteAction) {
      return const SizedBox.shrink();
    }

    return Container( // 可以保留 Container 做微调，或者直接返回 Button
      child: StylishPopupMenuButton<String>( // *** 使用新组件 ***
        icon: Icons.more_vert,
        iconSize: 20,
        triggerPadding: const EdgeInsets.all(4.0), // 使用 triggerPadding
        tooltip: '选项',
        elevation: 2.0,                          // 设置阴影
        itemHeight: 40,                          // 设置项高

        // *** 直接提供数据列表 ***
        items: [
          // 删除选项
          if (hasDeleteAction) // 使用计算好的变量
            StylishMenuItemData( // **提供数据**
              value: 'delete',
              // **提供内容**
              child: AppText('删除', type: AppTextType.error), // 使用主题颜色
            ),
          // 注意：编辑功能已注释掉，如果需要加回来，也用 StylishMenuItemData
        ],

        // onSelected 逻辑不变
        onSelected: (value) {
          if (value == 'delete') {
            onDeleteAction?.call(); // 直接调用
          }
          // else if (value == 'edit') { ... }
        },
      ),
    );
  }
}
