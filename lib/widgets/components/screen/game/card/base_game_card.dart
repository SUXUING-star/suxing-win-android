// lib/widgets/components/screen/game/card/base_game_card.dart

/// 该文件定义了 BaseGameCard 组件，一个用于展示游戏预览信息的卡片。
/// BaseGameCard 展示游戏封面、标题、摘要、标签和统计数据。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart'; // 导入自定义菜单按钮
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart'; // 导入应用文本类型
import 'package:suxingchahui/models/game/game.dart'; // 导入游戏模型
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart'; // 导入安全缓存图片组件
import 'package:suxingchahui/widgets/ui/components/game/game_category_tag_view.dart'; // 导入游戏分类标签视图
import 'game_stats_widget.dart'; // 导入游戏统计组件
import 'package:suxingchahui/widgets/ui/components/game/game_tag_list.dart'; // 导入游戏标签列表
import 'game_collection_dialog.dart'; // 导入游戏收藏对话框

/// `BaseGameCard` 类：基础游戏卡片组件。
///
/// 该组件展示单个游戏的预览信息，并提供导航到详情页、编辑和删除的操作入口。
class BaseGameCard extends StatelessWidget {
  final User? currentUser; // 当前用户
  final Game game; // 游戏数据
  final bool isGridItem; // 是否为网格项布局
  final bool adaptForPanels; // 是否适应面板布局
  final bool showTags; // 是否显示标签
  final int maxTags; // 最大显示标签数量
  final bool forceCompact; // 是否强制紧凑模式
  final bool showCollectionStats; // 是否显示收藏统计
  final VoidCallback? onDeleteAction; // 删除操作回调
  final VoidCallback? onEditAction; // 编辑操作回调
  final bool showNewBadge; // 是否显示新游戏徽章
  final bool showUpdatedBadge; // 是否显示更新游戏徽章

  /// 构造函数。
  ///
  /// [currentUser]：当前用户。
  /// [game]：游戏数据。
  /// [isGridItem]：是否网格项。
  /// [adaptForPanels]：是否适应面板。
  /// [showTags]：是否显示标签。
  /// [maxTags]：最大标签数。
  /// [forceCompact]：是否强制紧凑。
  /// [showCollectionStats]：是否显示收藏统计。
  /// [onDeleteAction]：删除回调。
  /// [onEditAction]：编辑回调。
  /// [showNewBadge]：是否显示新徽章。
  /// [showUpdatedBadge]：是否显示更新徽章。
  const BaseGameCard({
    super.key,
    required this.currentUser,
    required this.game,
    this.isGridItem = true,
    this.adaptForPanels = false,
    this.showTags = true,
    this.maxTags = 2,
    this.forceCompact = false,
    this.showCollectionStats = true,
    this.onDeleteAction,
    this.onEditAction,
    this.showNewBadge = false,
    this.showUpdatedBadge = false,
  });

  /// 构建游戏卡片。
  ///
  /// 根据游戏审核状态和布局类型选择构建不同样式的卡片。
  @override
  Widget build(BuildContext context) {
    if (game.approvalStatus == GameStatus.pending ||
        game.approvalStatus == GameStatus.rejected) {
      // 游戏处于待审核或已拒绝状态时
      return const SizedBox.shrink(); // 返回空组件
    }
    return isGridItem
        ? _buildGridCard(context)
        : _buildListCard(context); // 根据是否为网格项选择构建方法
  }

  /// 判断游戏是否为创建时间一周内的新游戏。
  bool _isGameNew() {
    final now = DateTime.now(); // 当前时间
    final sevenDaysAgo = now.subtract(const Duration(days: 7)); // 七天前的时间
    return game.createTime.isAfter(sevenDaysAgo) &&
        game.createTime.isBefore(now); // 游戏创建时间在七天内
  }

  /// 判断游戏是否为更新时间一周内且非新游戏的更新游戏。
  bool _isGameRecentlyUpdated() {
    final now = DateTime.now(); // 当前时间
    final sevenDaysAgo = now.subtract(const Duration(days: 7)); // 七天前的时间
    if (_isGameNew()) return false; // 如果是新游戏，则不是最近更新
    return game.updateTime.isAfter(sevenDaysAgo) &&
        game.updateTime.isBefore(now); // 游戏更新时间在七天内
  }

  /// 构建统一的徽章 UI。
  ///
  /// [text]：徽章文本。
  /// [color]：徽章背景颜色。
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // 内边距
      decoration: BoxDecoration(
        color: color, // 背景色
        borderRadius: BorderRadius.circular(4), // 圆角
        boxShadow: [
          // 阴影
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.2), // 阴影颜色
            blurRadius: 2, // 模糊半径
            offset: const Offset(0, 1), // 偏移量
          ),
        ],
      ),
      child: Text(
        text, // 文本
        style: const TextStyle(
          color: Colors.white, // 颜色
          fontSize: 10, // 字号
          fontWeight: FontWeight.bold, // 字重
        ),
      ),
    );
  }

  /// 构建列表布局卡片。
  ///
  /// [context]：Build 上下文。
  Widget _buildListCard(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop; // 判断是否为桌面平台
    return Card(
      elevation: 2, // 阴影
      clipBehavior: Clip.antiAlias, // 裁剪行为
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // 形状
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
                  padding: const EdgeInsets.all(10.0), // 内边距
                  child: _buildGameInfo(context), // 右侧信息
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建网格布局卡片。
  ///
  /// [context]：Build 上下文。
  Widget _buildGridCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // 裁剪行为
      elevation: 3, // 阴影
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 形状
      child: InkWell(
        onTap: () => _onCardTap(context), // 点击卡片跳转详情
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
          children: [
            Expanded(
              flex: 3, // 封面图区域比例
              child: Stack(
                fit: StackFit.expand, // 填充区域
                children: [
                  SafeCachedImage(
                    imageUrl: game.coverImage, // 封面图 URL
                    fit: BoxFit.cover, // 填充模式
                    memCacheWidth: DeviceUtils.isDesktop ? 480 : 280, // 内存缓存宽度
                  ),
                  Positioned(
                    top: 8, // 顶部偏移
                    left: 8, // 左侧偏移
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
                      children: [
                        if (showNewBadge && _isGameNew()) // 显示新游戏徽章
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4.0), // 底部内边距
                            child:
                                _buildBadge('新发布', Colors.red.shade700), // 徽章
                          )
                        else if (showUpdatedBadge &&
                            _isGameRecentlyUpdated()) // 显示更新游戏徽章
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4.0), // 底部内边距
                            child:
                                _buildBadge('最近更新', Colors.blue.shade700), // 徽章
                          ),
                        GameCategoryTagView(category: game.category), // 类别标签
                      ],
                    ),
                  ),
                  Positioned(
                      top: 4,
                      right: 4,
                      child: _buildPopupMenu(context)), // 右上角弹出菜单
                  Positioned(
                    bottom: 8, // 底部偏移
                    right: 8, // 右侧偏移
                    child: GestureDetector(
                      onTap: () {
                        // 点击手势
                        if (showCollectionStats && game.totalCollections > 0) {
                          showGameCollectionDialog(context, game); // 显示游戏收藏对话框
                        }
                      },
                      child: GameStatsWidget(
                          game: game,
                          showCollectionStats: showCollectionStats,
                          isGrid: true), // 游戏统计组件
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3, // 游戏信息区域比例
              child: Padding(
                padding: const EdgeInsets.all(12.0), // 内边距
                child: _buildGridInfoSection(context), // 网格信息区域
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建游戏封面图。
  ///
  /// [context]：Build 上下文。
  /// [isDesktop]：是否为桌面布局。
  Widget _buildGameCover(BuildContext context, bool isDesktop) {
    final coverWidth = isDesktop ? 120.0 : 100.0; // 封面宽度
    return SizedBox(
      width: coverWidth, // 宽度
      child: Stack(
        fit: StackFit.expand, // 填充
        children: [
          SafeCachedImage(
            imageUrl: game.coverImage, // 封面图 URL
            fit: BoxFit.cover, // 填充模式
            memCacheWidth: isDesktop ? 240 : 200, // 内存缓存宽度
            backgroundColor: Colors.grey[200], // 背景色
          ),
          Positioned(
            top: 8, // 顶部偏移
            left: 8, // 左侧偏移
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
              children: [
                if (showNewBadge && _isGameNew()) // 显示新徽章
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0), // 底部内边距
                    child: _buildBadge('新', Colors.red.shade700), // 徽章
                  )
                else if (showUpdatedBadge && _isGameRecentlyUpdated()) // 显示更新徽章
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0), // 底部内边距
                    child: _buildBadge('更新', Colors.blue.shade700), // 徽章
                  ),
                GameCategoryTagView(category: game.category), // 类别标签
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建游戏信息（列表布局）。
  ///
  /// [context]：Build 上下文。
  Widget _buildGameInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 垂直两端对齐
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 垂直顶部对齐
          children: [
            Expanded(
              child: Text(
                game.title, // 游戏标题
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13), // 样式
                maxLines: 1, // 最大行数
                overflow: TextOverflow.ellipsis, // 溢出显示省略号
              ),
            ),
            _buildPopupMenu(context), // 菜单按钮
          ],
        ),
        if (game.summary.isNotEmpty) // 描述非空时显示描述
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0), // 垂直内边距
            child: Text(
              game.summary, // 游戏摘要
              style: TextStyle(
                  fontSize: 10, color: Colors.grey[700], height: 1.2), // 样式
              maxLines: 2, // 最大行数
              overflow: TextOverflow.ellipsis, // 溢出显示省略号
            ),
          ),
        if (showTags && game.tags.isNotEmpty) // 显示标签
          Padding(
            padding: const EdgeInsets.only(top: 2.0, bottom: 4.0), // 顶部和底部内边距
            child: GameTagList(
              tags: game.tags,
              maxTags: maxTags,
              isCompact: false,
            ), // 游戏标签列表
          ),
        GestureDetector(
          onTap: () {
            // 点击手势
            if (showCollectionStats && game.totalCollections > 0) {
              showGameCollectionDialog(context, game); // 显示游戏收藏对话框
            }
          },
          child: GameStatsWidget(
            game: game,
            showCollectionStats: showCollectionStats,
            isGrid: false,
          ), // 游戏统计组件
        ),
      ],
    );
  }

  /// 构建游戏信息（网格布局）。
  ///
  /// [context]：Build 上下文。
  Widget _buildGridInfoSection(BuildContext context) {
    // 使用 Stack 布局，让内容和标签分层
    return Stack(
      children: [
        // 第一层：标题和摘要，作为基础内容
        Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
          children: [
            Text(
              game.title, // 游戏标题
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2), // 间距
            Text(
              game.summary, // 游戏摘要
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              // 为标签列表留出空间，这里限制摘要最多显示2行
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),

        // 第二层：游戏标签，使用 Positioned 定位到底部
        if (showTags && game.tags.isNotEmpty)
          Positioned(
            bottom: 0, // 紧贴底部
            left: 0, // 紧贴左边
            right: 0, // 紧贴右边
            child: GameTagList(
              tags: game.tags,
              maxTags: maxTags,
              isScrollable: true,
              isCompact: true,
            ),
          ),
      ],
    );
  }

  /// 卡片点击事件。
  ///
  /// [context]：Build 上下文。
  void _onCardTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.gameDetail, // 导航到游戏详情路由
      arguments: game, // 传递游戏数据
    );
  }

  /// 构建右上角弹出菜单。
  ///
  /// [context]：Build 上下文。
  Widget _buildPopupMenu(BuildContext context) {
    final String? currentUserId = currentUser?.id; // 当前用户ID
    final bool isAdmin = currentUser?.isAdmin ?? false; // 是否管理员
    final bool canModify =
        isAdmin ? true : game.authorId == currentUserId; // 是否可修改
    final bool hasDeleteAction = onDeleteAction != null; // 是否有删除操作
    final bool hasEditAction = onEditAction != null; // 是否有编辑操作

    if (!canModify || (!hasDeleteAction && !hasEditAction)) {
      // 无修改权限或无操作时隐藏
      return const SizedBox.shrink();
    }
    return StylishPopupMenuButton<String>(
      icon: Icons.more_vert, // 图标
      iconSize: 20, // 大小
      triggerPadding: const EdgeInsets.all(4.0), // 触发器内边距
      tooltip: '选项', // 提示
      elevation: 2.0, // 阴影
      itemHeight: 40, // 项高度

      items: [
        if (hasDeleteAction) // 显示删除选项
          StylishMenuItemData(
            value: 'delete', // 值
            child: AppText('删除', type: AppTextType.error), // 文本
          ),
        if (hasEditAction) // 显示编辑选项
          StylishMenuItemData(
            value: 'edit', // 值
            child: AppText('编辑', type: AppTextType.button), // 文本
          ),
      ],

      onSelected: (value) {
        // 选中回调
        if (value == 'delete') {
          onDeleteAction?.call(); // 调用删除回调
        } else if (value == 'edit') {
          onEditAction?.call(); // 调用编辑回调
        }
      },
    );
  }
}
