// lib/screens/profile/myposts/my_posts_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/post_grid_view.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';

class MyPostsScreen extends StatefulWidget {
  final UserFollowService followService;
  final PostService postService;
  final UserInfoProvider infoProvider;
  final AuthProvider authProvider;
  const MyPostsScreen({
    super.key,
    required this.authProvider,
    required this.postService,
    required this.followService,
    required this.infoProvider,
  });

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  List<Post> _posts = [];
  PaginationData? _paginationData;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String? _userId;
  bool _isMounted = false;

  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _userId = widget.authProvider.currentUserId;

    _scrollController.addListener(() {
      if (_isMounted &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoadingMore &&
          (_paginationData?.hasNextPage() ?? false)) {
        _loadMorePosts();
      }
    });

    if (_userId != null) {
      _fetchPosts(isRefresh: true);
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts({bool isRefresh = false}) async {
    if (!_isMounted || (_isLoading && !isRefresh)) return;

    if (isRefresh) {
      _currentPage = 1;
    }
    if (!_isMounted) return;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _error = null;
      if (isRefresh) {
        _posts = [];
        _paginationData = null;
      }
    });

    final currentUserId = widget.authProvider.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
          _posts = [];
          _paginationData = null;
        });
      }
      return;
    }

    try {
      final postListResult = await widget.postService
          .getUserPosts(currentUserId, page: _currentPage);

      if (_isMounted) {
        setState(() {
          _posts = postListResult.posts;
          _paginationData = postListResult.pagination;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
          _error = '加载我的帖子失败';
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_isMounted ||
        _isLoadingMore ||
        !(_paginationData?.hasNextPage() ?? false)) {
      return;
    }
    if (!_isMounted) return;
    setState(() {
      _isLoadingMore = true;
      _error = null;
    });

    _currentPage++;
    final currentUserId = widget.authProvider.currentUserId;
    if (currentUserId == null) {
      if (_isMounted) setState(() => _isLoadingMore = false);
      return;
    }

    try {
      final postListResult = await widget.postService
          .getUserPosts(currentUserId, page: _currentPage);

      if (_isMounted) {
        setState(() {
          _posts.addAll(postListResult.posts);
          _paginationData = postListResult.pagination;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (_isMounted) {
        _currentPage--;
        setState(() {
          _isLoadingMore = false;
          _error = '加载更多失败';
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _fetchPosts(isRefresh: true);
  }

  bool _checkCanEditOrDeletePost(Post post) {
    return widget.authProvider.isAdmin ||
        widget.authProvider.currentUserId == post.authorId;
  }

  Future<void> _handleDeletePost(Post post) async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeletePost(post)) {
      AppSnackBar.showPermissionDenySnackBar(context);
      return;
    }

    final postId = post.id;
    final int originalIndex = _posts.indexWhere((p) => p.id == postId);
    Post? originalPostData;
    if (originalIndex != -1) {
      originalPostData = _posts[originalIndex];
    }

    await CustomConfirmDialog.show(
        context: context,
        title: '确认删除',
        message: '确定要删除这篇帖子吗？此操作无法撤销。',
        confirmButtonText: '删除',
        confirmButtonColor: Colors.red,
        onConfirm: () async {
          if (!_isMounted) return;

          if (originalIndex != -1) {
            if (!_isMounted) return;
            setState(() {
              _posts.removeAt(originalIndex);
              if (_paginationData != null) {
                _paginationData = _paginationData!.copyWith(
                  total: _paginationData!.total - 1,
                );
              }
            });
          }

          try {
            await widget.postService.deletePost(post);
            if (!_isMounted) return;
            if (mounted) {
              AppSnackBar.showPostDeleteSuccessfullySnackBar(context);
            }

            if (_posts.isEmpty && _currentPage > 1) {
              _currentPage--;
              _fetchPosts(isRefresh: true);
            } else if (_posts.isEmpty && _paginationData?.total == 0) {
              if (_isMounted) setState(() {});
            }
          } catch (e) {
            if (_isMounted && originalPostData != null && originalIndex != -1) {
              setState(() {
                _posts.insert(originalIndex, originalPostData!);
                if (_paginationData != null) {
                  _paginationData = _paginationData!.copyWith(
                    total: _paginationData!.total + 1,
                  );
                }
                _error = '删除帖子失败';
              });
              if (!mounted) return;
              AppSnackBar.showError(context, '删除帖子失败');
            }
          }
        },
        onCancel: () {
          // 用户取消，不需要额外操作，因为乐观更新在 onConfirm 内部
        });
  }

  void _handleEditPost(Post post) async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeletePost(post)) {
      AppSnackBar.showPermissionDenySnackBar(context);
      return;
    }
    final result = await NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost,
      arguments: post.id,
    );
    if (result == true && _isMounted) {
      _fetchPosts(isRefresh: true);
    }
  }

  void _handleAddPost() async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    final result =
        await NavigationUtils.pushNamed(context, AppRoutes.createPost);
    if (result == true && _isMounted) {
      _fetchPosts(isRefresh: true);
    }
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButtonGroup(children: [
      GenericFloatingActionButton(
        icon: Icons.refresh,
        onPressed: _isLoading || _isLoadingMore ? null : _refreshPosts,
        tooltip: '刷新',
        heroTag: "刷新我的帖子",
      ),
      GenericFloatingActionButton(
        onPressed: _handleAddPost,
        icon: Icons.add,
        tooltip: '发布新帖',
        heroTag: "发布新帖我的帖子",
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _posts.isEmpty && _error == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: '我的帖子'),
        body: LoadingWidget.fullScreen(message: "拼命加载中"),
      );
    }

    return StreamBuilder<User?>(
        stream: widget.authProvider.currentUserStream,
        initialData: widget.authProvider.currentUser,
        builder: (context, authSnapshot) {
          final authUser = authSnapshot.data;
          if (authUser == null && !_isLoading) {
            return const Scaffold(
                appBar: CustomAppBar(title: '我的帖子'), body: LoginPromptWidget());
          }
          return Scaffold(
              appBar: const CustomAppBar(
                title: '我的帖子',
              ),
              body: RefreshIndicator(
                onRefresh:
                    _isLoading || _isLoadingMore ? () async {} : _refreshPosts,
                child: _buildContent(context, authUser),
              ),
              floatingActionButton:
                  (authUser != null) ? _buildFab(context) : null);
        });
  }

  Widget _buildContent(BuildContext context, User? authUser) {
    final bool isDesktop = DeviceUtils.isDesktop;

    if (_error != null && _posts.isEmpty && !_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
              height: MediaQuery.of(context).size.height -
                  (Scaffold.of(context).appBarMaxHeight ?? kToolbarHeight) -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
              alignment: Alignment.center,
              child: FunctionalTextButton(
                label: '加载失败: $_error. 点我重试',
                onPressed: () => _fetchPosts(isRefresh: true),
              ))
        ],
      );
    }

    if (_posts.isEmpty && !_isLoading && _error == null) {
      return LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: EmptyStateWidget(
              message: '你还没有发布过帖子哦',
              iconData: Icons.dynamic_feed_outlined,
              action: FunctionalTextButton(
                onPressed: _handleAddPost,
                label: '去发第一篇帖子',
              ),
            ),
          ),
        );
      });
    }

    return PostGridView(
      posts: _posts,
      currentUser: authUser,
      infoProvider: widget.infoProvider,
      followService: widget.followService,
      scrollController: _scrollController,
      isLoading: _isLoadingMore, // PostGridView 的 isLoading 应该对应加载更多的状态
      hasMoreData: _paginationData?.hasNextPage() ?? false,
      isDesktopLayout: isDesktop,
      onDeleteAction: _handleDeletePost,
      onEditAction: _handleEditPost,
    );
  }
}
