// lib/widgets/components/screen/game/history/responsive_history_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../utils/device/device_utils.dart';
import 'history_game_card.dart';
import 'history_game_grid_card.dart';

class ResponsiveHistoryLayout extends StatelessWidget {
  final List<Map<String, dynamic>> historyItems;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final Function(String) onDeleteItem;
  final VoidCallback? onLoadMore;
  final bool hasMoreItems;

  const ResponsiveHistoryLayout({
    super.key,
    required this.historyItems,
    required this.isLoading,
    this.error,
    required this.onRefresh,
    required this.onDeleteItem,
    this.onLoadMore,
    this.hasMoreItems = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && historyItems.isEmpty) {
      return _buildLoadingView();
    }

    if (error != null && historyItems.isEmpty) {
      return _buildErrorView(error!);
    }

    if (historyItems.isEmpty) {
      return _buildEmptyView();
    }

    // 根据设备类型选择不同的布局
    final isDesktop = DeviceUtils.isDesktop;
    final isTablet = DeviceUtils.isTablet(context);
    final isLandscape = DeviceUtils.isLandscape(context);

    if (isDesktop || (isTablet && isLandscape)) {
      return _buildGridLayout(context);
    } else {
      return _buildListLayout(context);
    }
  }

  Widget _buildLoadingView() {
    return LoadingWidget.inline(message: '正在加载浏览历史...');
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: RefreshIndicator(
        onRefresh: () async {
          onRefresh();
        },
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 100),
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: onRefresh,
                child: Text('重新加载'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: RefreshIndicator(
        onRefresh: () async {
          onRefresh();
        },
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 100),
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              '暂无浏览记录',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '开始浏览更多内容，您的历史记录将显示在这里',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 列表布局 - 适用于移动设备
  Widget _buildListLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              hasMoreItems &&
              !isLoading &&
              onLoadMore != null) {
            onLoadMore!();
          }
          return true;
        },
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: historyItems.length +
              (isLoading && historyItems.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == historyItems.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final historyItem = historyItems[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: HistoryGameCard(
                historyItem: historyItem,
                onDeletePressed: () =>
                    onDeleteItem(historyItem['gameId']?.toString() ?? ''),
              ),
            );
          },
        ),
      ),
    );
  }

  // 网格布局 - 适用于桌面和平板
  Widget _buildGridLayout(BuildContext context) {
    // 计算一行显示的卡片数量
    final crossAxisCount = DeviceUtils.calculateCardsPerRow(context);
    // 计算卡片比例
    final cardRatio = DeviceUtils.calculateSimpleCardRatio(context);

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              hasMoreItems &&
              !isLoading &&
              onLoadMore != null) {
            onLoadMore!();
          }
          return true;
        },
        child: GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: cardRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: historyItems.length +
              (isLoading && historyItems.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == historyItems.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final historyItem = historyItems[index];
            return HistoryGameGridCard(
              historyItem: historyItem,
              onDeletePressed: () =>
                  onDeleteItem(historyItem['gameId']?.toString() ?? ''),
            );
          },
        ),
      ),
    );
  }
}
