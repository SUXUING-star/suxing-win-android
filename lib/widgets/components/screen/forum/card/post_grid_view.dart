import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../models/post/post.dart';
import 'post_card.dart'; // 确保导入 PostCard

class PostGridView extends StatelessWidget {
  final List<Post> posts;
  final ScrollController? scrollController;
  final bool isLoading; // 用于显示加载更多指示器
  final bool hasMoreData; // 是否还有更多数据可加载
  // final VoidCallback? onLoadMore; // 这个似乎没在 MasonryGridView 中直接使用
  final bool isDesktopLayout;

  // --- 新增：接收来自父组件的回调函数 ---
  final Future<void> Function(String postId) onDeleteAction;
  final void Function(Post post) onEditAction;
  final Future<void> Function(String postId) onToggleLockAction;

  const PostGridView({
    super.key,
    required this.posts,
    this.scrollController,
    this.isLoading = false,
    this.hasMoreData = false,
    // this.onLoadMore,
    this.isDesktopLayout = true, // 桌面布局默认为 true? 检查默认值是否合适
    required this.onDeleteAction, // 设为 required
    required this.onEditAction,   // 设为 required
    required this.onToggleLockAction,
  });

  @override
  Widget build(BuildContext context) {
    // --- 动态计算列数 (可以移到这里，或者由父组件传入) ---
    // 这个计算逻辑可能更适合放在使用 PostGridView 的地方（如 ForumScreen）
    // 但如果 PostGridView 主要用于桌面，可以保留一个默认计算
    int crossAxisCount = 3; // 默认值
    // 示例：可以根据 isDesktopLayout 或 MediaQuery 调整
    if (!isDesktopLayout) {
      crossAxisCount = 1; // 移动端强制1列？或者用 ListView？
      // 注意：如果移动端用 ListView，这个组件就不合适了，需要条件渲染
      // 假设这里移动端也用 Grid，只是列数不同
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth < 600) crossAxisCount = 2; // 小屏幕2列
      if (screenWidth < 400) crossAxisCount = 1; // 更小屏幕1列
    } else {
      // 桌面端的复杂逻辑可能需要父组件传入列数
    }


    // 使用 MasonryGridView.count (瀑布流)
    return MasonryGridView.count(
      controller: scrollController, // 绑定滚动控制器
      crossAxisCount: crossAxisCount, // 使用计算出的列数
      mainAxisSpacing: 8, // 垂直间距
      crossAxisSpacing: isDesktopLayout ? 16 : 8, // 水平间距 (桌面宽点)
      padding: EdgeInsets.all(isDesktopLayout ? 16 : 8), // 内边距 (桌面大点)
      // itemCount 需要考虑加载指示器
      itemCount: posts.length + (isLoading && hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // --- 判断是显示帖子还是加载指示器 ---
        if (index < posts.length) {
          // 显示帖子卡片
          final post = posts[index];
          return PostCard(
            post: post,
            isDesktopLayout: isDesktopLayout,
            // --- 将接收到的回调传递给 PostCard ---
            onDeleteAction: onDeleteAction,
            onEditAction: onEditAction,
            onToggleLockAction: onToggleLockAction,
          );
        } else {
          // 显示加载更多指示器
          // 为了让加载指示器占据一整行（或合理位置），可能需要特殊处理
          // 在 Masonry Grid 中，它会尝试找到合适的位置插入
          // 可以简单地返回一个居中的 LoadingWidget
          return Container(
            // 可以设置一个最小高度，避免太小
            constraints: BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: LoadingWidget.inline(message: "加载中..."), // 使用 inline 版本
          );
        }
      },
    );
  }
}