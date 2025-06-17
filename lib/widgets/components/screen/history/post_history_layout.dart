// lib/widgets/components/screen/history/post_history_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/components/screen/history/history_post_grid_view.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart'; // 引入 LazyLayoutBuilder

class PostHistoryLayout extends StatefulWidget {
  final List<Post> postHistoryItems;
  final PaginationData? paginationData;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryInitialLoad;
  final String? errorMessage;
  final ScrollController scrollController;
  final User? currentUser;
  final WindowStateProvider windowStateProvider;
  final UserInfoService userInfoService;
  final UserFollowService userFollowService;

  // 定义 flex 和 divider 宽度为 static const
  static const int desktopStatsFlex = 1;
  static const int desktopGridFlex = 3;
  static const double desktopDividerWidth = 1.0;

  const PostHistoryLayout({
    super.key,
    required this.postHistoryItems,
    required this.paginationData,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onRetryInitialLoad,
    this.errorMessage,
    required this.scrollController,
    required this.currentUser,
    required this.windowStateProvider,
    required this.userInfoService,
    required this.userFollowService,
  });

  @override
  _PostHistoryLayoutState createState() => _PostHistoryLayoutState();
}

class _PostHistoryLayoutState extends State<PostHistoryLayout>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ... (加载、错误、空状态逻辑不变)
    if (widget.isLoadingInitial) {
      return const FadeInItem(
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      );
    }

    if (widget.errorMessage != null && widget.postHistoryItems.isEmpty) {
      return Center(
        child: FunctionalTextButton(
          label: '加载失败: ${widget.errorMessage}. 点击重试',
          onPressed: widget.onRetryInitialLoad,
        ),
      );
    }

    if (widget.postHistoryItems.isEmpty) {
      return FadeInSlideUpItem(
        child: EmptyStateWidget(
          message: '暂无帖子浏览记录',
          iconColor: Colors.grey[400],
          iconData: Icons.article_outlined,
          iconSize: 64,
        ),
      );
    }

    // 核心改动：用 LazyLayoutBuilder 包裹，判断布局模式
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = DeviceUtils.isDesktopInThisWidth(screenWidth);

        if (isDesktop) {
          return _buildDesktopLayout(context, isDesktop, screenWidth);
        } else {
          return _buildMobileLayout(context, isDesktop, screenWidth);
        }
      },
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, bool isDesktop, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: PostHistoryLayout.desktopStatsFlex,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: _buildPostHistoryStatistics(context, isDesktop: isDesktop),
          ),
        ),
        const VerticalDivider(
            width: PostHistoryLayout.desktopDividerWidth, thickness: 0.5),
        Expanded(
          flex: PostHistoryLayout.desktopGridFlex,
          child: _buildHistoryContent(context,
              isDesktop: isDesktop, screenWidth: screenWidth),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, bool isDesktop, double screenWidth) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _buildPostHistoryStatistics(context, isDesktop: isDesktop),
        ),
        Expanded(
          child: _buildHistoryContent(context,
              isDesktop: isDesktop, screenWidth: screenWidth),
        ),
      ],
    );
  }

  // _buildPostHistoryStatistics 和 _buildStatRow 方法完全不变 ...
  Widget _buildPostHistoryStatistics(BuildContext context,
      {required bool isDesktop}) {
    DateTime? earliestViewTime;
    DateTime? latestViewTime;

    if (widget.postHistoryItems.isNotEmpty) {
      for (var item in widget.postHistoryItems) {
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
              Text('帖子历史统计', style: titleStyle),
              const SizedBox(height: 16),
              _buildStatRow(context,
                  isDesktop: true,
                  icon: Icons.playlist_add_check,
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
              const PageStorageKey<String>('post_history_stats_expansion_tile'),
          title: Text('帖子历史统计', style: titleStyle),
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

  // 核心改动：_buildHistoryContent 现在也接收 screenWidth 并进行计算
  Widget _buildHistoryContent(BuildContext context,
      {required bool isDesktop, required double screenWidth}) {
    double gridAvailableWidth;
    if (isDesktop) {
      // 数学家上线
      gridAvailableWidth =
          (screenWidth - PostHistoryLayout.desktopDividerWidth) *
              PostHistoryLayout.desktopGridFlex /
              (PostHistoryLayout.desktopStatsFlex +
                  PostHistoryLayout.desktopGridFlex);
    } else {
      // 移动端，网格占满全部宽度
      gridAvailableWidth = screenWidth;
    }

    return HistoryPostGridView(
      posts: widget.postHistoryItems,
      currentUser: widget.currentUser,
      infoService: widget.userInfoService,
      followService: widget.userFollowService,
      scrollController: widget.scrollController,
      isLoading: widget.isLoadingMore,
      hasMoreData: widget.paginationData?.hasNextPage() ?? false,
      isDesktopLayout: isDesktop,
      availableWidth: gridAvailableWidth, // 把计算好的宽度传下去
    );
  }
}
