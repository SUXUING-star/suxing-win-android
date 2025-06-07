// lib/widgets/components/screen/history/game_history_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_content_grid.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';

class GameHistoryLayout extends StatefulWidget {
  final List<Game> gameHistoryItems;
  final PaginationData? paginationData;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryInitialLoad;
  final String? errorMessage;
  final ScrollController scrollController;

  const GameHistoryLayout({
    super.key,
    required this.gameHistoryItems,
    required this.paginationData,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onRetryInitialLoad,
    this.errorMessage,
    required this.scrollController,
  });

  @override
  _GameHistoryLayoutState createState() => _GameHistoryLayoutState();
}

class _GameHistoryLayoutState extends State<GameHistoryLayout>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.isLoadingInitial) {
      return Center(child: LoadingWidget.fullScreen(message: "正在加载游戏浏览记录"));
    }

    if (widget.errorMessage != null && widget.gameHistoryItems.isEmpty) {
      return Center(
        child: FunctionalTextButton(
          label: '加载失败: ${widget.errorMessage}. 点击重试',
          onPressed: widget.onRetryInitialLoad,
        ),
      );
    }

    if (widget.gameHistoryItems.isEmpty) {
      return FadeInSlideUpItem(
        child: EmptyStateWidget(
          message: '暂无游戏浏览记录',
          iconData: Icons.history_edu_outlined,
          iconColor: Colors.grey[400],
          iconSize: 64,
        ),
      );
    }

    final isDesktop = DeviceUtils.isDesktopScreen(context);

    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: _buildGameHistoryStatistics(context, isDesktop: true),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 0.5),
        Expanded(
          flex: 3,
          child: _buildHistoryContent(context, isDesktop: true),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _buildGameHistoryStatistics(context, isDesktop: false),
        ),
        Expanded(
          child: _buildHistoryContent(context, isDesktop: false),
        ),
      ],
    );
  }

  Widget _buildGameHistoryStatistics(BuildContext context,
      {required bool isDesktop}) {
    DateTime? earliestViewTime;
    DateTime? latestViewTime;

    if (widget.gameHistoryItems.isNotEmpty) {
      for (var item in widget.gameHistoryItems) {
        final DateTime? viewTime =
            item.currentUserLastViewTime ?? item.lastViewedAt;
        if (viewTime == null) continue;

        if (earliestViewTime == null || viewTime.isBefore(earliestViewTime)) {
          earliestViewTime = viewTime;
        }
        if (latestViewTime == null || viewTime.isAfter(latestViewTime)) {
          latestViewTime = viewTime;
        }
      }
    }

    if (isDesktop) {
      final cardPadding = const EdgeInsets.all(16);
      final titleStyle = TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      );
      return Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('游戏历史统计', style: titleStyle),
              const SizedBox(height: 16),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.playlist_play,
                  title: '总记录数',
                  value: widget.paginationData?.total.toString() ?? '0',
                  color: Colors.blueAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.calendar_today_outlined,
                  title: '最早浏览',
                  value: earliestViewTime != null
                      ? DateTimeFormatter.formatShort(earliestViewTime)
                      : '无记录',
                  color: Colors.orangeAccent),
              const Divider(height: 20, thickness: 0.5),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.access_time_outlined,
                  title: '最近浏览',
                  value: latestViewTime != null
                      ? DateTimeFormatter.formatShort(latestViewTime)
                      : '无记录',
                  color: Colors.green),
            ],
          ),
        ),
      );
    } else {
      // Mobile layout using ExpansionTile
      final titleStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      );
      final totalCountStyle = TextStyle(
        fontSize: 14,
        color: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withSafeOpacity(0.85),
      );

      return Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key:
              const PageStorageKey<String>('game_history_stats_expansion_tile'),
          title: Text('游戏历史统计', style: titleStyle),
          trailing: Text(
            '总记录: ${widget.paginationData?.total.toString() ?? '0'}',
            style: totalCountStyle,
          ),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          childrenPadding:
              const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
          children: <Widget>[
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.calendar_today_outlined,
                title: '最早浏览',
                value: earliestViewTime != null
                    ? DateTimeFormatter.formatShort(earliestViewTime)
                    : '无记录',
                color: Colors.orangeAccent),
            const Divider(height: 12, thickness: 0.3),
            _buildStatRow(context,
                isDesktop: false,
                icon: Icons.access_time_outlined,
                title: '最近浏览',
                value: latestViewTime != null
                    ? DateTimeFormatter.formatShort(latestViewTime)
                    : '无记录',
                color: Colors.green),
          ],
        ),
      );
    }
  }

  Widget _buildStatRow(BuildContext context,
      {required bool isDesktop,
      required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    final titleTextStyle = TextStyle(
        color:
            Theme.of(context).textTheme.bodyMedium?.color?.withSafeOpacity(0.7),
        fontSize: isDesktop ? 14 : 13);
    final valueTextStyle = TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isDesktop ? 16 : 15,
        color: Theme.of(context).textTheme.bodyLarge?.color);
    final iconSize = isDesktop ? 22.0 : 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withSafeOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleTextStyle),
                const SizedBox(height: 2),
                Text(value, style: valueTextStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent(BuildContext context, {required bool isDesktop}) {
    final crossAxisCount =
        DeviceUtils.calculateGameCardsInGameListPerRow(context);
    final cardRatio = DeviceUtils.calculateSimpleGameCardRatio(context);

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(isDesktop ? 16 : 8),
      children: [
        // 使用升级后的 AnimatedContentGrid
        AnimatedContentGrid<Game>(
          items: widget.gameHistoryItems,
          crossAxisCount: crossAxisCount,
          childAspectRatio: cardRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: isDesktop ? 16 : 8,
          padding: EdgeInsets.zero, // 外部 ListView 已有 padding
          shrinkWrap: true, // 关键：使其在 ListView 内正常工作
          physics: const NeverScrollableScrollPhysics(), // 关键：禁用其内部滚动
          itemBuilder: (context, index, gameItem) {
            final DateTime? lastViewTime =
                gameItem.currentUserLastViewTime ?? gameItem.lastViewedAt;
            return _buildGameCardWithViewTime(
              context,
              gameItem,
              isDesktop,
              lastViewTime,
            );
          },
        ),

        // 加载更多的逻辑保持不变
        if (widget.isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: LoadingWidget.inline(message: "正在加载记录"),
          ),
        if (!widget.isLoadingMore &&
            (widget.paginationData?.hasNextPage() ?? false) &&
            widget.gameHistoryItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: FunctionalTextButton(
                onPressed: widget.onLoadMore,
                label: '加载更多',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameCardWithViewTime(
      BuildContext context, Game gameItem, bool isDesktop, DateTime? viewTime) {
    Widget commonGameCardWidget = CommonGameCard(
      game: gameItem,
      showTags: true,
      maxTags: isDesktop ? 2 : 3,
    );

    // Note: AspectRatio for desktop was removed from here as it's better handled by the GridView's childAspectRatio.
    // If specific aspect ratio is needed per card, it can be re-added.

    return Stack(
      children: [
        commonGameCardWidget,
        if (viewTime != null)
          Positioned(
            bottom: isDesktop ? 8 : 4,
            right: isDesktop ? 8 : 4,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 8 : 6, vertical: isDesktop ? 3 : 2),
              decoration: BoxDecoration(
                color: Colors.black.withSafeOpacity(0.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '上次浏览: ${DateTimeFormatter.formatShort(viewTime)}',
                style: TextStyle(
                  fontSize: isDesktop ? 9 : 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
