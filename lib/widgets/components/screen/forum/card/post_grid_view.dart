// lib/widgets/components/screen/forum/card/post_grid_view.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_masonry_grid_view.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'base_post_card.dart';

class _LoadingIndicatorPlaceholder {
  const _LoadingIndicatorPlaceholder();
}

class PostGridView extends StatelessWidget {
  final List<Post> posts;
  final User? currentUser;
  final UserFollowService followService;
  final ScrollController? scrollController;
  final bool isLoading; // 用于显示加载更多指示器
  final bool hasMoreData; // 是否还有更多数据可加载
  final UserInfoService infoService;
  final Future<void> Function(Post post)? onDeleteAction;
  final void Function(Post post)? onEditAction;
  final Future<void> Function(Post post)? onToggleLockAction;
  final bool isDesktopLayout;
  final double availableWidth;

  const PostGridView({
    super.key,
    required this.posts,
    required this.currentUser,
    required this.followService,
    required this.infoService,
    required this.isDesktopLayout,
    required this.availableWidth,
    this.scrollController,
    this.isLoading = false,
    this.hasMoreData = false,
    this.onDeleteAction, // 设为 required
    this.onEditAction, // 设为 required
    this.onToggleLockAction,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = DeviceUtils.calculatePostCardsPerRow(
      context,
      directAvailableWidth: availableWidth,
    );

    // 准备要显示的所有项目
    final List<Object> displayItems = [...posts];
    if (isLoading && hasMoreData) {
      displayItems.add(const _LoadingIndicatorPlaceholder());
    }

    // 使用封装好的带动画的瀑布流组件

    return AnimatedMasonryGridView<Object>(
      gridKey: key,
      // 使用 widget 的 key
      items: displayItems,
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 8,
      crossAxisSpacing: isDesktopLayout ? 16 : 8,
      padding: EdgeInsets.all(isDesktopLayout ? 16 : 8),
      itemBuilder: (context, index, item) {
        // 如果项目是帖子
        if (item is Post) {
          return BasePostCard(
            currentUser: currentUser,
            infoService: infoService,
            followService: followService,
            availableWidth: availableWidth,
            post: item,
            onDeleteAction: onDeleteAction,
            onEditAction: onEditAction,
            onToggleLockAction: onToggleLockAction,
          );
        }

        // 如果项目是加载指示器
        if (item is _LoadingIndicatorPlaceholder) {
          return Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: const LoadingWidget(message: "加载中..."),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
