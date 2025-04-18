// lib/screens/profile/my_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../utils/device/device_utils.dart';

// --- 确保导入正确的 Bloc 文件路径 ---
import 'blocs/my_posts_bloc.dart';
import 'blocs/my_posts_event.dart';
import 'blocs/my_posts_state.dart';
import '../../../widgets/components/screen/forum/card/post_grid_view.dart'; // 确认导入 PostGridView
import '../../../routes/app_routes.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';

class MyPostsScreen extends StatefulWidget {
  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  late MyPostsBloc _myPostsBloc;
  bool _isInitialized = false;
  final ScrollController _scrollController = ScrollController();
  String? _lastErrorDisplayed; // 用于防止重复显示相同的错误 SnackBar

  @override
  void initState() {
    super.initState();
    _myPostsBloc = BlocProvider.of<MyPostsBloc>(context);
    print("MyPostsScreen initState: Bloc instance obtained.");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      print(
          "MyPostsScreen didChangeDependencies: Initializing and loading posts.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _myPostsBloc.add(LoadMyPostsEvent()); // 发送加载事件
      });
    }
  }

  @override
  void dispose() {
    // 注意：如果 Bloc 是在这里创建的，需要 dispose
    // if (BlocProvider.of<MyPostsBloc>(context) == _myPostsBloc) { // 检查是否是自己创建的
    //   _myPostsBloc.close(); // 只有自己创建的才 close
    // }
    _scrollController.dispose();
    print("MyPostsScreen disposed.");
    super.dispose();
  }

  // --- 下拉刷新 ---
  Future<void> _refreshPosts() async {
    print("MyPostsScreen: Refresh triggered.");
    // 发送刷新事件给 Bloc
    _myPostsBloc.add(RefreshMyPostsEvent());
    // Bloc 会处理 isLoading 状态和数据加载
    // RefreshIndicator 会自动处理显示和隐藏
  }

  // --- 处理 PostCard 的删除请求 ---
  Future<void> _handleDeletePost(String postId) async {
    print("MyPostsScreen: Handling delete request for $postId");
    // 显示确认对话框
    final confirmed = await CustomConfirmDialog.show( // 调用 show 方法
      context: context,
      title: '确认删除',
      message: '确定要删除这篇帖子吗？此操作无法撤销。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      // --- 报错就是因为少了下面这行！！！ ---
      onConfirm: () async { // <--- 把这个 onConfirm 回调加上！
        print("MyPostsScreen: Delete confirmed for $postId. Dispatching event.");
        // 用户确认后，向 Bloc 发送删除事件
        _myPostsBloc.add(DeletePostEvent(postId));
        // Bloc 会处理实际的删除操作和状态更新
        // 注意：onConfirm 内部不需要 pop 了，Dialog 的 _handleConfirm 会处理
      },
      // onCancel 可以省略，如果不需要特殊处理的话
    );
  }

  // --- 处理 PostCard 的编辑请求 ---
  void _handleEditPost(Post post) async {
    print("MyPostsScreen: Handling edit request for ${post.id}");
    // 导航到编辑页面
    final result = await NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost,
      arguments: post.id, // 传递 Post ID
    );

    // 如果编辑成功返回，触发 Bloc 刷新事件
    if (result == true && mounted) {
      print(
          "MyPostsScreen: Edit successful for ${post.id}. Dispatching refresh event.");
      _myPostsBloc.add(RefreshMyPostsEvent()); // 触发刷新
    }
  }

  // --- 新增：处理来自 PostCard 的锁定/解锁请求 ---
  Future<void> _handleToggleLockAction(String postId) async {
    print("MyPostsScreen: Handling toggle lock action for $postId");
    if (!mounted) return;
    // 直接向 Bloc 发送事件，由 Bloc 处理 Service 调用和状态更新
    _myPostsBloc.add(TogglePostLockEvent(postId));
    // Bloc 的 listener 会处理 SnackBar 提示（如果需要）
  }

  @override
  Widget build(BuildContext context) {
    // 直接使用 Scaffold，假设 BlocProvider 在上层
    return Scaffold(
      appBar: CustomAppBar(
        title: '我的帖子',
        // 可选：添加刷新按钮
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _myPostsBloc.add(RefreshMyPostsEvent()),
            tooltip: '刷新',
          ),
        ],
      ),
      body: BlocConsumer<MyPostsBloc, MyPostsState>(
        // bloc: _myPostsBloc, // 如果 BlocProvider 在上层，则不需要指定 bloc
        listener: (context, state) {
          // --- 监听错误状态以显示 SnackBar ---
          if (state.error != null && state.error != _lastErrorDisplayed) {
            AppSnackBar.showError(context, state.error!);
            _lastErrorDisplayed = state.error; // 记录已显示的错误
            // 可选：发送事件清除错误，防止重复显示
            Future.delayed(const Duration(milliseconds: 100), () {
              // 延迟发送，避免 listener 冲突
              if (mounted) _myPostsBloc.add(ClearPostsErrorEvent());
            });
          } else if (state.error == null) {
            _lastErrorDisplayed = null; // 状态中没有错误了，重置记录
          }
          // 可选：监听特定成功操作（比如删除、锁定切换成功）来显示成功提示
          // 但通常 UI 的更新（列表项移除/状态改变）就是最好的反馈
        },
        builder: (context, state) {
          print(
              "MyPostsScreen BlocConsumer builder: isLoading=${state.isLoading}, posts=${state.posts.length}, error=${state.error}");
          // 使用 RefreshIndicator 包裹内容，下拉时触发刷新
          return RefreshIndicator(
            onRefresh: _refreshPosts, // 直接调用 stateful widget 的方法
            child: _buildContent(context, state), // 调用构建内容的方法
          );
        },
      ),
      floatingActionButton: GenericFloatingActionButton(
        onPressed: () async {
          final result =
              await NavigationUtils.pushNamed(context, AppRoutes.createPost);
          // 发帖成功后刷新
          if (result == true && mounted) {
            _myPostsBloc.add(RefreshMyPostsEvent());
          }
        },
        icon: Icons.add,
        tooltip: '发布新帖',
      ),
    );
  }

  Widget _buildContent(BuildContext context, MyPostsState state) {
    final bool isDesktop = DeviceUtils.isDesktop;

    // --- 优先处理加载状态 (仅在首次加载且无数据时显示全屏 Loading) ---
    // Bloc 的 state.isLoading 会控制 RefreshIndicator
    if (state.isLoading && state.posts.isEmpty && state.error == null) {
      print("MyPostsScreen _buildContent: Showing initial loading widget.");
      // 使用 ListView 包裹 LoadingWidget，使其可以在 RefreshIndicator 下工作
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3), // 垂直居中
          LoadingWidget.inline(),
        ],
      );
    }

    // --- 处理未登录状态 ---
    if (state.userId == null && !state.isLoading) {
      print("MyPostsScreen _buildContent: Showing login prompt widget.");
      // 使用 ListView 包裹 LoginPromptWidget
      return ListView(
        children: const [LoginPromptWidget()],
      );
    }
    // --- 处理空状态 (加载完成，无错误，但帖子列表为空) ---
    if (state.posts.isEmpty && !state.isLoading && state.error == null) {
      print("MyPostsScreen _buildContent: Showing empty state widget.");
      // 使用 ListView 包裹 EmptyStateWidget
      return LayoutBuilder(// 使用 LayoutBuilder 确保内容足够高以触发刷新
          builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 即使内容不足也要能滚动
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: EmptyStateWidget(
              message: '你还没有发布过帖子哦',
              iconData: Icons.dynamic_feed_outlined,
              action: FunctionalTextButton(
                onPressed: () async {
                  final result = await NavigationUtils.pushNamed(
                      context, AppRoutes.createPost);
                  if (result == true && mounted) {
                    _myPostsBloc.add(RefreshMyPostsEvent());
                  }
                },
                label: '去发第一篇帖子',
              ),
            ),
          ),
        );
      });
    }

    // --- 显示帖子列表 ---
    print("MyPostsScreen _buildContent: Building PostGridView.");
    // PostGridView 现在是主要内容，应该直接返回，让 RefreshIndicator 包裹它
    return PostGridView(
      // key: ValueKey(state.posts.hashCode), // 可选：如果列表更新有问题，可以加 Key
      posts: state.posts,
      scrollController: _scrollController, // 传递滚动控制器
      // PostGridView 不再需要 isLoading 和 hasMoreData，因为我们没做分页
      isLoading: false, // 始终为 false
      hasMoreData: false, // 始终为 false
      isDesktopLayout: isDesktop,
      // --- 传递实现好的回调函数 ---
      onDeleteAction: _handleDeletePost,
      onEditAction: _handleEditPost,
      onToggleLockAction: _handleToggleLockAction, // <-- 传递新回调
    );
  }
}
