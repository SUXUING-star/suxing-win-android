// lib/widgets/components/screen/favorite/post_favorites_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_content_grid.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/base_post_card.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';

class PostFavoritesLayout extends StatefulWidget {
  final List<Post> favoritePosts;
  final PaginationData? paginationData;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;
  final VoidCallback onRetryInitialLoad;
  final VoidCallback onLoadMore;
  final Function(String postId) onToggleFavorite;
  final ScrollController scrollController;
  final User? currentUser;
  final WindowStateProvider windowStateProvider;
  final UserInfoProvider userInfoProvider;
  final UserFollowService userFollowService;

  static const int leftFlex = 1;
  static const int rightFlex = 3;

  const PostFavoritesLayout({
    super.key,
    required this.favoritePosts,
    required this.paginationData,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    this.errorMessage,
    required this.onRetryInitialLoad,
    required this.onLoadMore,
    required this.onToggleFavorite,
    required this.scrollController,
    required this.currentUser,
    required this.windowStateProvider,
    required this.userInfoProvider,
    required this.userFollowService,
  });

  @override
  _PostFavoritesLayoutState createState() => _PostFavoritesLayoutState();
}

class _LoadingMorePlaceholder {
  const _LoadingMorePlaceholder();
}

class _LoadMoreButtonPlaceholder {
  const _LoadMoreButtonPlaceholder();
}

class _PostFavoritesLayoutState extends State<PostFavoritesLayout>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.isLoadingInitial) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    if (widget.errorMessage != null && widget.favoritePosts.isEmpty) {
      return Center(
        child: FunctionalTextButton(
          label: '加载失败: ${widget.errorMessage}. 点击重试',
          onPressed: widget.onRetryInitialLoad,
        ),
      );
    }

    if (widget.favoritePosts.isEmpty) {
      return FadeInSlideUpItem(
        child: EmptyStateWidget(
          message: '暂无收藏的帖子',
          iconData: Icons.star_border,
          iconColor: Colors.grey[400],
          iconSize: 64,
        ),
      );
    }

    // 这是她妈的获取屏幕的宽度
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktopLayout = DeviceUtils.isDesktopInThisWidth(screenWidth);
        return isDesktopLayout
            ? _buildDesktopLayout(context, isDesktopLayout, screenWidth)
            : _buildMobileLayout(context, isDesktopLayout, screenWidth);
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDesktopLayout,
    double screenWidth,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: PostFavoritesLayout.leftFlex,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: _buildPostFavoritesStatistics(context,
                isDesktop: isDesktopLayout),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 0.5),
        Expanded(
          flex: PostFavoritesLayout.rightFlex,
          child: _buildFavoritesContent(
            context,
            isDesktop: isDesktopLayout,
            screenWidth: screenWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    bool isDesktopLayout,
    double screenWidth,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _buildPostFavoritesStatistics(
            context,
            isDesktop: isDesktopLayout,
          ),
        ),
        Expanded(
          child: _buildFavoritesContent(
            context,
            isDesktop: isDesktopLayout,
            screenWidth: screenWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildPostFavoritesStatistics(BuildContext context,
      {required bool isDesktop}) {
    final cardPadding =
        isDesktop ? const EdgeInsets.all(16) : const EdgeInsets.all(12);
    final titleStyle = TextStyle(
      fontSize: isDesktop ? 18 : 16,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).textTheme.titleLarge?.color,
    );

    return Card(
      elevation: isDesktop ? 2 : 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
      ),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('收藏帖子统计', style: titleStyle),
            const SizedBox(height: 16),
            _buildStatRow(context,
                isDesktop: isDesktop,
                icon: Icons.star,
                title: '总收藏数',
                value: widget.paginationData?.total.toString() ??
                    widget.favoritePosts.length.toString(),
                color: Colors.blueAccent),
          ],
        ),
      ),
    );
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

  Widget _buildFavoritesContent(
    BuildContext context, {
    required bool isDesktop,
    required double screenWidth,
  }) {
    // 准备要显示的所有项目
    final List<Object> displayItems = [...widget.favoritePosts];
    if (widget.isLoadingMore) {
      displayItems.add(const _LoadingMorePlaceholder());
    } else if (widget.paginationData?.hasNextPage() ?? false) {
      displayItems.add(const _LoadMoreButtonPlaceholder());
    }

    // 这是她妈的手动计算,实际的网格布局的实际的宽度
    double availableWidth;
    if (isDesktop) {
      availableWidth = screenWidth *
          PostFavoritesLayout.rightFlex /
          (PostFavoritesLayout.leftFlex + PostFavoritesLayout.rightFlex);
    } else {
      availableWidth = screenWidth;
    }
    final crossAxisCount = DeviceUtils.calculatePostCardsPerRow(
      context,
      directAvailableWidth: availableWidth,
    );

    final cardRatio = DeviceUtils.calculatePostCardRatio(context,
        directAvailableWidth: availableWidth);
    return AnimatedContentGrid<Object>(
      items: displayItems,
      crossAxisCount: crossAxisCount,
      childAspectRatio: cardRatio,
      crossAxisSpacing: 8,
      mainAxisSpacing: isDesktop ? 16 : 8,
      padding: EdgeInsets.all(isDesktop ? 16 : 8),
      itemBuilder: (context, index, item) {
        // 如果项目是帖子
        if (item is Post) {
          return _buildPostCard(
            item,
            availableWidth,
            isDesktop,
          );
        }

        // 如果项目是加载指示器
        if (item is _LoadingMorePlaceholder) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: LoadingWidget(message: "正在加载更多"),
          );
        }

        // 如果项目是加载更多按钮
        if (item is _LoadMoreButtonPlaceholder) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: FunctionalTextButton(
                onPressed: widget.onLoadMore,
                label: '加载更多',
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPostCard(
    Post postItem,
    double postListWidth,
    bool isDesktop,
  ) {
    return Stack(
      children: [
        BasePostCard(
          post: postItem,
          currentUser: widget.currentUser,
          availableWidth: postListWidth,
          infoProvider: widget.userInfoProvider,
          followService: widget.userFollowService,
          onDeleteAction: null,
          onEditAction: null,
          onToggleLockAction: null,
        ),
        Positioned(
          top: isDesktop ? 8 : 4,
          right: isDesktop ? 8 : 4,
          child: IconButton(
            icon: Icon(Icons.favorite, color: Colors.red),
            iconSize: isDesktop ? 20 : 24,
            onPressed: () => widget.onToggleFavorite(postItem.id),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withSafeOpacity(0.4),
              minimumSize: Size.zero,
              padding: EdgeInsets.all(isDesktop ? 4 : 6),
            ),
          ),
        ),
      ],
    );
  }
}
