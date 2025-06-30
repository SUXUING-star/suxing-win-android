// lib/widgets/components/screen/home/section/home_hot_posts.dart

/// 该文件定义了 HomeHotPosts 组件，用于显示主页的热门帖子板块。
/// HomeHotPosts 包含加载、错误、空状态和正常显示帖子卡片列表的逻辑。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/models/post/post.dart'; // 帖子模型
import 'package:suxingchahui/models/user/user/user.dart'; // 用户模型
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息 Provider
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/widgets/components/screen/forum/card/base_post_card.dart'; // 基础帖子卡片组件
import 'package:suxingchahui/widgets/ui/animation/animated_list_view.dart'; // 动画列表视图
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法

/// `HomeHotPosts` 类：主页热门帖子板块组件。
///
/// 该组件负责展示热门帖子，并处理加载、错误和空状态。
class HomeHotPosts extends StatelessWidget {
  final List<Post>? posts; // 热门帖子列表
  final User? currentUser; // 当前登录用户
  final UserFollowService followService; // 用户关注服务
  final UserInfoService infoService; // 用户信息 Provider
  final double screenWidth; // 屏幕宽度
  final bool isLoading; // 是否正在加载
  final String? errorMessage; // 错误消息
  final Function(bool) onRetry; // 重试回调

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [posts]：热门帖子列表。
  /// [currentUser]：当前登录用户。
  /// [infoProvider]：用户信息 Provider。
  /// [followService]：用户关注服务。
  /// [isLoading]：是否正在加载。
  /// [screenWidth]：屏幕宽度。
  /// [errorMessage]：错误消息。
  /// [onRetry]：重试回调。
  const HomeHotPosts({
    super.key,
    required this.posts,
    required this.currentUser,
    required this.infoService,
    required this.followService,
    required this.isLoading,
    required this.screenWidth,
    this.errorMessage,
    required this.onRetry,
  });

  /// 构建 Widget。
  ///
  /// 渲染热门帖子板块，包含标题和帖子列表。
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // 内边距
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.9), // 背景颜色
        borderRadius: BorderRadius.circular(12), // 圆角
        boxShadow: [
          // 阴影
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴对齐
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8), // 垂直内边距
            decoration: BoxDecoration(
              border: Border(
                bottom:
                    BorderSide(color: Colors.grey.shade200, width: 1), // 底部边框
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor, // 主题色
                    borderRadius: BorderRadius.circular(3), // 圆角
                  ),
                ),
                const SizedBox(width: 12), // 间距
                Text(
                  '热门帖子', // 标题文本
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                const Spacer(), // 占据剩余空间
              ],
            ),
          ),
          const SizedBox(height: 16), // 间距
          _buildPostListArea(context), // 构建帖子列表区域
        ],
      ),
    );
  }

  /// 构建帖子列表区域。
  ///
  /// [context]：Build 上下文。
  /// 根据加载、错误、空状态和正常状态渲染不同的内容。
  Widget _buildPostListArea(BuildContext context) {
    if (isLoading && posts == null) {
      // 加载中且无数据时
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0), // 垂直内边距
        child: LoadingWidget(
          message: '加载热门帖子...',
          size: 24,
        ),
      );
    }

    if (errorMessage != null && posts == null) {
      // 错误状态且无数据时
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0), // 垂直内边距
        child: InlineErrorWidget(
          errorMessage: errorMessage!,
          onRetry: () => onRetry(true),
        ),
      );
    }

    final displayPosts = posts ?? []; // 待显示帖子列表
    if (!isLoading && displayPosts.isEmpty) {
      // 空状态时
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0), // 垂直内边距
        child: InlineErrorWidget(
          errorMessage: '暂无热门帖子',
          icon: Icons.forum_outlined,
          iconSize: 30,
          iconColor: Colors.grey[400],
          onRetry: () => onRetry(true),
        ),
      );
    }

    final itemsToShow = displayPosts.take(5).toList(); // 取前 5 个帖子显示

    return Stack(
      children: [
        AnimatedListView<Post>(
          // 动画列表视图
          listKey: const ValueKey('home_hot_posts_list'), // 列表 Key
          items: itemsToShow, // 列表项
          shrinkWrap: true, // 在 Column 内正常工作
          physics: const NeverScrollableScrollPhysics(), // 禁用其内部滚动
          padding: EdgeInsets.zero, // 无内边距
          itemBuilder: (ctx, index, post) {
            return Column(
              children: [
                _buildPostListItem(ctx, post), // 构建帖子列表项
                if (index < itemsToShow.length - 1) // 非最后一项时显示分割线
                  Divider(
                    height: 20,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.withSafeOpacity(0.15),
                  ),
              ],
            );
          },
        ),
        if (isLoading && displayPosts.isNotEmpty) // 加载中且有数据时显示加载指示器
          Positioned.fill(
              child: Container(
            color: Colors.white.withSafeOpacity(0.5), // 半透明背景
            child: const LoadingWidget(size: 30), // 加载指示器
          )),
      ],
    );
  }

  /// 构建帖子列表项。
  ///
  /// [context]：Build 上下文。
  /// [post]：帖子数据。
  /// 返回一个 `BasePostCard` Widget。
  Widget _buildPostListItem(
    BuildContext context,
    Post post,
  ) {
    return BasePostCard(
      followService: followService, // 用户关注服务
      infoService: infoService, // 用户信息 Provider
      availableWidth: screenWidth, // 可用宽度
      post: post, // 帖子数据
      currentUser: currentUser, // 当前用户
    );
  }
}
