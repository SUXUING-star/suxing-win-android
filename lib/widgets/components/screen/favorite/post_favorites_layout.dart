// lib/widgets/components/screen/favorite/post_favorites_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/base_post_card.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

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
  final UserInfoProvider userInfoProvider;
  final UserFollowService userFollowService;

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
    required this.userInfoProvider,
    required this.userFollowService,
  });

  @override
  _PostFavoritesLayoutState createState() => _PostFavoritesLayoutState();
}

class _PostFavoritesLayoutState extends State<PostFavoritesLayout> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.isLoadingInitial) {
      return Center(child: LoadingWidget.fullScreen(message: "正在加载收藏帖子"));
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
            child: _buildPostFavoritesStatistics(context, isDesktop: true),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 0.5),
        Expanded(
          flex: 3,
          child: _buildFavoritesContent(context, isDesktop: true),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _buildPostFavoritesStatistics(context, isDesktop: false),
        ),
        Expanded(
          child: _buildFavoritesContent(context, isDesktop: false),
        ),
      ],
    );
  }

  Widget _buildPostFavoritesStatistics(BuildContext context, {required bool isDesktop}) {
    final cardPadding = isDesktop ? const EdgeInsets.all(16) : const EdgeInsets.all(12);
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
            _buildStatRow(context, isDesktop: isDesktop, icon: Icons.star, title: '总收藏数', value: widget.paginationData?.total.toString() ?? widget.favoritePosts.length.toString(), color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, {required bool isDesktop, required IconData icon, required String title, required String value, required Color color}) {
    final titleTextStyle = TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withSafeOpacity(0.7), fontSize: isDesktop ? 14 : 13);
    final valueTextStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: isDesktop ? 16 : 15, color: Theme.of(context).textTheme.bodyLarge?.color);
    final iconSize = isDesktop ? 22.0 : 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withSafeOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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

  Widget _buildFavoritesContent(BuildContext context, {required bool isDesktop}) {
    final crossAxisCount = DeviceUtils.calculatePostCardsPerRow(context);
    final cardRatio = DeviceUtils.calculatePostCardRatio(context);

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(isDesktop ? 16 : 8),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: cardRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: isDesktop ? 16 : 8,
          ),
          itemCount: widget.favoritePosts.length,
          itemBuilder: (context, index) {
            final postItem = widget.favoritePosts[index];
            return FadeInSlideUpItem(
              delay: Duration(milliseconds: 50 * index),
              duration: const Duration(milliseconds: 350),
              child: _buildPostCard(postItem, isDesktop),
            );
          },
        ),
        if (widget.isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: FadeInItem(child: LoadingWidget.inline(message: "正在加载更多")),
          ),
        if (!widget.isLoadingMore && (widget.paginationData?.hasNextPage() ?? false) && widget.favoritePosts.isNotEmpty)
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

  Widget _buildPostCard(Post postItem, bool isDesktop) {
    return Stack(
      children: [
        BasePostCard(
          post: postItem,
          currentUser: widget.currentUser,
          infoProvider: widget.userInfoProvider,
          followService: widget.userFollowService,
          isDesktopLayout: isDesktop,
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