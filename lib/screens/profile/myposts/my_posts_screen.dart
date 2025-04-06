// lib/screens/profile/my_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../utils/device/device_utils.dart';
import 'blocs/my_posts_bloc.dart';
import 'blocs/my_posts_event.dart';
import 'blocs/my_posts_state.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../services/main/user/user_service.dart';
import '../../../widgets/components/screen/forum/card/post_grid_view.dart';
import '../../../widgets/components/screen/my_posts/post_actions_bottom_sheet.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/components/loading/loading_route_observer.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';

class MyPostsScreen extends StatefulWidget {
  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  late MyPostsBloc _myPostsBloc;
  bool _isInitialized = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 直接初始化 bloc
    _myPostsBloc = MyPostsBloc(
      Provider.of<ForumService>(context, listen: false),
      Provider.of<UserService>(context, listen: false),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 确保只执行一次加载
    if (!_isInitialized) {
      _isInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final loadingObserver = NavigationUtils.of(context)
            .widget
            .observers
            .whereType<LoadingRouteObserver>()
            .first;

        loadingObserver.showLoading();

        // 加载数据
        _myPostsBloc.add(LoadMyPostsEvent());

        // 延迟隐藏加载动画
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            loadingObserver.hideLoading();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _myPostsBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshPosts() async {
    final loadingObserver = NavigationUtils.of(context)
        .widget
        .observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      _myPostsBloc.add(LoadMyPostsEvent());
    } finally {
      // 延迟隐藏加载动画
      Future.delayed(Duration(seconds: 1), () {
        loadingObserver.hideLoading();
      });
    }
  }
  // --- 新增：处理 PostCard 的删除请求 ---
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

  // --- 新增：处理 PostCard 的编辑请求 ---
  void _handleEditPost(Post post) async {
    print("MyPostsScreen: Handling edit request for ${post.id}");
    // 导航到编辑页面
    final result = await NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost,
      arguments: post, // 传递 Post 对象
    );

    // 如果编辑成功返回，触发 Bloc 刷新事件
    if (result == true && mounted) {
      print("MyPostsScreen: Edit successful for ${post.id}. Dispatching refresh event.");
      _myPostsBloc.add(RefreshMyPostsEvent()); // 触发刷新
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _myPostsBloc,
      child: Scaffold(
        appBar: CustomAppBar(
          title: '我的帖子',
        ),
        body: BlocConsumer<MyPostsBloc, MyPostsState>(
          listener: (context, state) {
            if (state.error != null) {
              AppSnackBar.showError(context, state.error!);

            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: _refreshPosts,
              child: _buildContent(context, state),
            );
          },
        ),
        floatingActionButton: GenericFloatingActionButton(
          onPressed: () =>
              NavigationUtils.pushNamed(context, AppRoutes.createPost),
          icon:Icons.add,
          tooltip: '发布新帖',
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MyPostsState state) {
    final bool isDesktop = DeviceUtils.isDesktop;

    if (state.isLoading) {
      return LoadingWidget.inline();
    }

    if (state.userId == null) {
      return LoginPromptWidget();
    }

    if (state.posts.isEmpty) {
      return EmptyStateWidget(message: '暂无发帖', iconData: Icons.mail_outline);
    }

    return PostGridView(
      posts: state.posts,
      scrollController: _scrollController, // 传递滚动控制器
      // PostGridView 内部的加载指示器由 isLoading 和 hasMoreData 控制
      isLoading: state.isLoading && state.hasMoreData, // 只有在加载更多时才传递 true
      hasMoreData: state.hasMoreData, // 传递是否有更多数据
      isDesktopLayout: isDesktop, // 控制 PostCard 布局
      // --- 传递实现好的回调函数 ---
      onDeleteAction: _handleDeletePost,
      onEditAction: _handleEditPost,
    );
  }
}
