// lib/screens/profile/myposts/my_posts_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/myposts/my_posts_layout.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';

class MyPostsScreen extends StatefulWidget {
  final UserFollowService followService;
  final PostService postService;
  final UserInfoService infoService;
  final AuthProvider authProvider;
  final WindowStateProvider windowStateProvider;
  const MyPostsScreen({
    super.key,
    required this.authProvider,
    required this.postService,
    required this.followService,
    required this.infoService,
    required this.windowStateProvider,
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
  bool _isMounted = false;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  static const Duration _minRefreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_isMounted &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoadingMore &&
          (_paginationData?.hasNextPage() ?? false)) {
        _loadMorePosts();
      }
    });

    if (widget.authProvider.currentUserId != null) {
      _loadPosts();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({
    int pageToFetch = 1,
    bool forceRefresh = false,
  }) async {
    if (!_isMounted || (_isLoading && _posts.isEmpty)) return;

    if (!_isMounted) return;
    setState(() {
      _posts = [];
      _paginationData = null;
      _error = null;
      _isLoading = true;

      _isLoadingMore = false;
    });

    final currentUserId = widget.authProvider.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
          _posts = [];
          _paginationData = null;
          _error = null;
        });
      }
      return;
    }

    try {
      final postList = await widget.postService
          .getUserPosts(currentUserId, page: _currentPage);

      if (_isMounted) {
        setState(() {
          _posts = postList.posts;
          _paginationData = postList.pagination;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
          _error = '加载我的帖子失败: ${e.toString().split(':').last.trim()}';
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
          _error = '加载更多失败: ${e.toString().split(':').last.trim()}';
          AppSnackBar.showError('加载更多帖子失败');
        });
      }
    }
  }

  Future<void> _refreshPosts({
    bool needCheck = true,
  }) async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }

    if (!mounted || _isRefreshing) return;

    final now = DateTime.now();

    if (needCheck) {
      // 需要进行时间间隔检查时
      if (_lastRefreshTime != null &&
          now.difference(_lastRefreshTime!) < _minRefreshInterval) {
        // 时间间隔不足时
        if (mounted) {
          AppSnackBar.showWarning(
              '刷新太频繁啦，请 ${(_minRefreshInterval.inSeconds - now.difference(_lastRefreshTime!).inSeconds)} 秒后再试'); // 提示刷新频繁
        }
        return; // 返回
      }
    }

    setState(() {
      _isRefreshing = true;
      _lastRefreshTime = now;
    });
    try {
      await _loadPosts(
        forceRefresh: true,
        pageToFetch: _currentPage,
      );
      setState(() {
        _isRefreshing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
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
      AppSnackBar.showPermissionDenySnackBar();
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

            AppSnackBar.showPostDeleteSuccessfullySnackBar();

            if (_posts.isEmpty && (_paginationData?.total ?? 0) > 0) {
              _loadPosts(pageToFetch: _currentPage, forceRefresh: true);
            } else if (_posts.isEmpty && (_paginationData?.total ?? 0) == 0) {
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
              AppSnackBar.showError('删除帖子失败');
            }
          }
        });
  }

  void _handleEditPost(Post post) async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanEditOrDeletePost(post)) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    final result = await NavigationUtils.pushNamed(
      context,
      AppRoutes.editPost,
      arguments: post.id,
    );
    if (result == true && _isMounted) {
      _loadPosts(
        pageToFetch: _currentPage,
        forceRefresh: false,
      );
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
      _loadPosts(forceRefresh: true);
    }
  }

  String _makeHeroTag(
      {required bool isDesktopLayout, required String mainCtx}) {
    final ctxDevice = isDesktopLayout ? 'desktop' : 'mobile';
    const ctxScreen = 'my_posts';
    return '${ctxScreen}_${ctxDevice}_${mainCtx}_${widget.authProvider.currentUserId}';
  }

  Widget _buildFab(bool isDesktopLayout) {
    if (!widget.authProvider.isLoggedIn) {
      return const SizedBox.shrink();
    }
    return FloatingActionButtonGroup(
      toggleButtonHeroTag: "my_posts_heroTags",
      children: [
        GenericFloatingActionButton(
          icon: Icons.refresh,
          onPressed: _isLoading || _isLoadingMore
              ? null
              : () => _refreshPosts(needCheck: true),
          tooltip: '刷新',
          heroTag: _makeHeroTag(
              isDesktopLayout: isDesktopLayout, mainCtx: 'refresh'),
        ),
        GenericFloatingActionButton(
          onPressed: _handleAddPost,
          icon: Icons.add,
          tooltip: '发布新帖',
          heroTag:
              _makeHeroTag(isDesktopLayout: isDesktopLayout, mainCtx: 'add'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktopLayout = DeviceUtils.isDesktopInThisWidth(screenWidth);
        return Scaffold(
          appBar: const CustomAppBar(title: '我的帖子'),
          body: StreamBuilder<User?>(
            stream: widget.authProvider.currentUserStream,
            initialData: widget.authProvider.currentUser,
            builder: (context, authSnapshot) {
              final currentUser = authSnapshot.data;
              final bool isLoggedIn = currentUser != null;

              if (!isLoggedIn) {
                return const LoginPromptWidget();
              }

              if (_isLoading && _posts.isEmpty && _error == null) {
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

              if (_error != null && _posts.isEmpty) {
                return CustomErrorWidget(
                  onRetry: () => _loadPosts(forceRefresh: true),
                  errorMessage: _error,
                );
              }

              return RefreshIndicator(
                  onRefresh: _isLoading || _isLoadingMore
                      ? () async {}
                      : _refreshPosts,
                  child: MyPostsLayout(
                    posts: _posts,
                    isLoadingMore: _isLoadingMore,
                    hasMore: _paginationData?.hasNextPage() ?? false,
                    scrollController: _scrollController,
                    onAddPost: _handleAddPost,
                    onDeletePost: _handleDeletePost,
                    onEditPost: _handleEditPost,
                    errorMessage: _error,
                    isDesktopLayout: isDesktopLayout,
                    screenWidth: screenWidth,
                    onRetry: () => _refreshPosts(needCheck: true),
                    currentUser: currentUser,
                    infoService: widget.infoService,
                    followService: widget.followService,
                    totalPostCount: _paginationData?.total ?? _posts.length,
                  ));
            },
          ),
          floatingActionButton: _buildFab(isDesktopLayout),
        );
      },
    );
  }
}
