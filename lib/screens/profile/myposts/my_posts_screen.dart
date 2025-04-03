// lib/screens/profile/my_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
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
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error!)));
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
      scrollController: _scrollController,
      isDesktopLayout: false, // 保持原有的列表样式
    );
  }
}
