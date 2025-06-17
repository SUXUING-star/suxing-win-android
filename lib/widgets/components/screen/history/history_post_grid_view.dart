// lib/widgets/components/screen/history/history_post_grid_view.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_masonry_grid_view.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/base_post_card.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';

class _LoadingIndicatorPlaceholder {
  const _LoadingIndicatorPlaceholder();
}

class HistoryPostGridView extends StatelessWidget {
  final List<Post> posts;
  final User? currentUser;
  final UserFollowService followService;
  final ScrollController? scrollController;
  final bool isLoading;
  final bool hasMoreData;
  final UserInfoService infoService;
  final bool isDesktopLayout;
  final double availableWidth; // 核心改动：直接接收可用宽度

  const HistoryPostGridView({
    super.key,
    required this.posts,
    required this.currentUser,
    required this.followService,
    required this.infoService,
    required this.isDesktopLayout,
    required this.availableWidth, // 核心改动：变为必传参数
    this.scrollController,
    this.isLoading = false,
    this.hasMoreData = false,
  });

  @override
  Widget build(BuildContext context) {
    // 不再自己判断，直接用传入的宽度计算
    final crossAxisCount = DeviceUtils.calculatePostCardsPerRow(
      context,
      directAvailableWidth: availableWidth,
    );

    // 准备要显示的所有项目
    final List<Object> displayItems = [...posts];
    if (isLoading && hasMoreData) {
      displayItems.add(const _LoadingIndicatorPlaceholder());
    }

    // 使用封装好的带动画的瀑布流组件，去掉了外层的 LazyLayoutBuilder
    return AnimatedMasonryGridView<Object>(
      gridKey: key, // 使用 widget 的 key
      items: displayItems,
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: isDesktopLayout ? 16 : 8,
      crossAxisSpacing: isDesktopLayout ? 16 : 8,
      padding: EdgeInsets.all(isDesktopLayout ? 16 : 8),
      itemBuilder: (context, index, item) {
        // 如果项目是帖子
        if (item is Post) {
          final post = item;
          final DateTime? lastViewTime =
              post.currentUserLastViewTime ?? post.lastViewedAt;

          return Stack(
            children: [
              BasePostCard(
                currentUser: currentUser,
                infoService: infoService,
                followService: followService,
                post: post,
                availableWidth: availableWidth, // 把这里的 screenWidth 也换成 availableWidth
                onDeleteAction: null,
                onEditAction: null,
                onToggleLockAction: null,
              ),
              if (lastViewTime != null)
                Positioned(
                  bottom: isDesktopLayout ? 8 : 4,
                  right: isDesktopLayout ? 8 : 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: isDesktopLayout ? 8 : 6,
                        vertical: isDesktopLayout ? 3 : 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withSafeOpacity(0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '上次浏览: ${DateTimeFormatter.formatShort(lastViewTime)}',
                      style: TextStyle(
                        fontSize: isDesktopLayout ? 9 : 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }

        // 如果项目是加载指示器
        if (item is _LoadingIndicatorPlaceholder) {
          return const LoadingWidget(message: "加载中...");
        }

        return const SizedBox.shrink();
      },
    );
  }
}