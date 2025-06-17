// lib/screens/activity/activity_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/activity_detail_param.dart';
import 'package:suxingchahui/models/activity/activity_navigation_info.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/activity/activity_detail_content.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 引入 AuthProvider
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/dialogs/edit_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snackBar.dart';

class ActivityDetailScreen extends StatefulWidget {
  final ActivityDetailParam? activityDetailParam;
  final AuthProvider authProvider;
  final ActivityService activityService;
  final UserFollowService followService;
  final InputStateService inputStateService;
  final UserInfoService infoService;
  final WindowStateProvider windowStateProvider;

  const ActivityDetailScreen({
    super.key,
    this.activityDetailParam,
    required this.activityService,
    required this.followService,
    required this.authProvider,
    required this.inputStateService,
    required this.infoService,
    required this.windowStateProvider,
  });

  @override
  _ActivityDetailScreenState createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late UserActivity _activity;
  late String _activityId;
  late ActivityNavigationInfo? _navigationInfo;
  late String _feedType;
  late int _listPageNum;
  bool _isLoading = true;
  final bool _isLoadingComments = false;
  String _error = '';
  final ScrollController _scrollController = ScrollController();
  int _refreshCounter = 0;
  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    final activityDetailParam = widget.activityDetailParam;
    if (activityDetailParam != null) {
      _activity = activityDetailParam.activity;
      _listPageNum = activityDetailParam.listPageNum;
      _feedType = activityDetailParam.feedType;
      _activityId = activityDetailParam.activityId;
      _initNavigationInfo();
    }

    if (activityDetailParam == null) {
      _error = '无法找到该活动记录';
      _navigationInfo = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies && _error == '') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeActivity();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ActivityDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activityDetailParam?.activityId !=
        oldWidget.activityDetailParam?.activityId) {
      final activityDetailParam = widget.activityDetailParam;
      if (activityDetailParam != null) {
        _activity = activityDetailParam.activity;
        _listPageNum = activityDetailParam.listPageNum;
        _feedType = activityDetailParam.feedType;
        _activityId = activityDetailParam.activityId;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initNavigationInfo() async {
    _navigationInfo = await widget.activityService.getActivityNavInfoFromCache(
      currentActivityId: _activityId,
      feedType: _feedType,
      currentPageNum: _listPageNum,
    );
  }

  // 封装初始化逻辑
  void _initializeActivity() {
    final activityDetailParam = widget.activityDetailParam;
    if (activityDetailParam != null) {
      setStateIfMounted(() {
        _activity = activityDetailParam.activity;
        _listPageNum = activityDetailParam.listPageNum;
        _feedType = activityDetailParam.feedType;
        _isLoading = false;
      });
    } else {
      _loadActivity();
    }
  }

  // 安全地设置状态，防止在 dispose 后调用 setState
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _scrollListener() {
    // 评论分页暂时不用
    // if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
    //   _loadMoreComments();
    // }
  }

  Future<void> _loadActivity() async {
    setStateIfMounted(() {
      _isLoading = true;
      _error = '';
    });
    try {
      // 这行根本就不会进行的
      final activity = await widget.activityService.getActivityDetail(
        _activityId,
      );
      if (activity == null) {
        _error = '未能加载活动详情';
      } else {
        setStateIfMounted(() {
          _activity = activity;
          _isLoading = false;
        });
      }
    } catch (e) {
      setStateIfMounted(() {
        _error = '加载活动详情失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshActivity() async {
    await _loadActivity();
  }

  Future<bool> _handleLike() async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return false;
    }
    HapticFeedback.lightImpact();
    final bool currentlyLiked = _activity.isLiked;
    final int currentLikesCount = _activity.likesCount;

    try {
      bool success = currentlyLiked
          ? await widget.activityService.unlikeActivity(
              _activity.id,
              feedType: _feedType,
            )
          : await widget.activityService.likeActivity(
              _activity.id,
              feedType: _feedType,
            );
      if (!success) {
        AppSnackBar.showError('操作失败'); // 抛出异常以便 catch 处理回滚
      } else {
        setStateIfMounted(() {
          _activity.isLiked = !currentlyLiked;
          _activity.likesCount =
              currentlyLiked ? currentLikesCount - 1 : currentLikesCount + 1;
        });
      }
      await widget.activityService
          .tryCacheActivitiesAfterUpdateActivityNotChangePagination(
        _activity,
        feedType: _feedType,
        pageNum: _listPageNum,
      );
      return success;
    } catch (e) {
      AppSnackBar.showError('操作失败，请稍后重试');
      return false;
    }
  }

  Future<void> _addComment(String content) async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (content.trim().isEmpty) return;
    try {
      final comment = await widget.activityService.commentOnActivity(
        _activity.id,
        content,
        feedType: _feedType,
      );
      if (comment != null) {
        setStateIfMounted(() {
          _activity.comments.insert(0, comment);
          _activity.commentsCount += 1;
          _refreshCounter++; // 强制刷新
        });
        await widget.activityService
            .tryCacheActivitiesAfterUpdateActivityNotChangePagination(
          _activity,
          feedType: _feedType,
          pageNum: _listPageNum,
        );
      } else {
        AppSnackBar.showError("操作失败");
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError('评论失败: ${e.toString()}');
      }
    }
  }

  bool _checkCanDeleteComment(ActivityComment comment) {
    final bool isAuthor = comment.userId == widget.authProvider.currentUserId;
    final bool isAdmin = widget.authProvider.isAdmin;
    return isAdmin ? true : isAuthor;
  }

  void _handleCommentDeleted(ActivityComment comment) {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_checkCanDeleteComment(comment)) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    final commentId = comment.id;
    CustomConfirmDialog.show(
        context: context,
        title: "确认删除",
        message: "确定删除这条评论吗？",
        confirmButtonText: "删除",
        confirmButtonColor: Colors.red,
        iconData: Icons.delete_outline,
        iconColor: Colors.red,
        onConfirm: () async {
          try {
            final success = await widget.activityService.deleteComment(
              _activity.id,
              comment,
              feedType: _feedType,
            );
            if (success && mounted) {
              // --- 从本地列表移除评论并更新计数 ---
              setStateIfMounted(() {
                _activity.comments.removeWhere((c) => c.id == commentId);
                _activity.commentsCount = _activity.comments.length;
                _refreshCounter++; // 强制 UI 刷新
              });
              await widget.activityService
                  .tryCacheActivitiesAfterUpdateActivityNotChangePagination(
                _activity,
                feedType: _feedType,
                pageNum: _listPageNum,
              );
              AppSnackBar.showSuccess('评论已删除');
            } else if (mounted) {
              throw Exception("删除评论失败");
            } else if (!success) {
              throw Exception("删除评论失败");
            }
          } catch (e) {
            if (mounted) AppSnackBar.showError('删除失败: ${e.toString()}');
            rethrow;
          }
        });
  }

  Future<bool> _handleCommentLikeToggled(
    ActivityComment updatedComment,
    bool action,
  ) async {
    try {
      if (!widget.authProvider.isLoggedIn) {
        AppSnackBar.showLoginRequiredSnackBar(context);
        return false;
      }
      bool success;
      if (action) {
        success = await widget.activityService.likeComment(
          _activity.id,
          updatedComment.id,
          feedType: _feedType,
        );
      } else {
        success = await widget.activityService.unlikeComment(
          _activity.id,
          updatedComment.id,
          feedType: _feedType,
        );
      }

      if (success) {
        AppSnackBar.showSuccess("操作成功");
      } else {
        AppSnackBar.showError("操作失败");
      }

      setStateIfMounted(() {
        // 在 _activity!.comments 中找到对应的评论并替换
        final index =
            _activity.comments.indexWhere((c) => c.id == updatedComment.id);
        if (index != -1) {
          _activity.comments[index] = updatedComment; // 使用更新后的对象替换旧的
        }
      });
      await widget.activityService
          .tryCacheActivitiesAfterUpdateActivityNotChangePagination(
        _activity,
        feedType: _feedType,
        pageNum: _listPageNum,
      );
      return success;
    } catch (e) {
      AppSnackBar.showError("操作失败,${e.toString()}");
      return false;
    }
  }

  // --- 编辑活动处理 ---
  Future<void> _handleEditActivity() async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }

    if (!_checkCanEditOrCanDelete(_activity)) {
      if (mounted) {
        AppSnackBar.showPermissionDenySnackBar();
      }
      return;
    }

    try {
      // 使用 EditDialog.show
      await EditDialog.show(
        context: context,
        inputStateService: widget.inputStateService,
        title: '编辑动态',
        initialText: _activity.content,
        hintText: '输入新的动态内容...',
        maxLines: 5, // 可以调整最大行数
        onSave: (newText) async {
          // onSave 是异步的
          if (newText == _activity.content) return; // 内容未改变则不提交

          try {
            // 调用服务更新活动
            final (success, updatedActivity) =
                await widget.activityService.updateActivity(
              _activity,
              newText,
              _activity.metadata,
              feedType: _feedType,
            );

            if (success) {
              UserActivity updatedActivityForCache;
              // 更新本地状态
              // 创建一个新的 UserActivity 实例，复制旧数据并更新字段
              if (updatedActivity != null) {
                updatedActivityForCache = updatedActivity;
              } else {
                final currentActivity = _activity;
                updatedActivityForCache = UserActivity(
                  id: currentActivity.id,
                  userId: currentActivity.userId,
                  type: currentActivity.type,
                  sourceId: currentActivity.sourceId,
                  targetId: currentActivity.targetId,
                  targetType: currentActivity.targetType,
                  content: newText, // <--- 更新内容
                  createTime: currentActivity.createTime,
                  updateTime: DateTime.now(), // <--- 更新时间
                  isEdited: true, // <--- 更新编辑状态
                  likesCount: currentActivity.likesCount, // 复制旧值
                  commentsCount: currentActivity.commentsCount, // 复制旧值
                  isPublic: currentActivity.isPublic, // 复制旧值
                  isLiked: currentActivity.isLiked, // 复制旧值
                  metadata: currentActivity.metadata, // 复制旧值
                  comments: currentActivity.comments, // 复制旧值
                );
              }
              await widget.activityService
                  .tryCacheActivitiesAfterUpdateActivityNotChangePagination(
                updatedActivityForCache,
                feedType: _feedType,
                pageNum: _listPageNum,
              );
              setStateIfMounted(() {
                _refreshCounter++;
                _activity = updatedActivityForCache;
                // 强制刷新UI
              });
              if (mounted) {
                AppSnackBar.showSuccess('动态更新成功');
              }
            } else {
              throw Exception('Update failed');
            }
          } catch (e) {
            if (mounted) {
              AppSnackBar.showError('更新失败: ${e.toString()}');
            }
            // 重新抛出，让 EditDialog 的调用者知道出错了（如果需要）
            rethrow;
          }
        },
      );
    } catch (e) {
      //
    }
  }

  bool _checkCanEditOrCanDelete(UserActivity activity) {
    final bool isAuthor = activity.userId == widget.authProvider.currentUserId;
    final bool isAdmin = widget.authProvider.isAdmin;
    final canEditOrDelete = isAdmin ? true : isAuthor;
    return canEditOrDelete;
  }

  // --- 删除活动处理 ---
  Future<void> _handleDeleteActivity() async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }

    if (!_checkCanEditOrCanDelete(_activity)) {
      if (mounted) {
        AppSnackBar.showPermissionDenySnackBar();
      }
      return;
    }

    try {
      // 使用 CustomConfirmDialog.show
      await CustomConfirmDialog.show(
        context: context,
        title: '确认删除',
        message: '确定要删除这条动态吗？此操作不可撤销。',
        confirmButtonText: '删除',
        confirmButtonColor: Colors.red,
        iconData: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        onConfirm: () async {
          // onConfirm 是异步的
          try {
            final success = await widget.activityService.deleteActivity(
              _activity,
              feedType: _feedType,
            );
            if (success) {
              if (mounted) {
                // 删除成功后，关闭当前页面
                Navigator.pop(context);
                AppSnackBar.showSuccess('动态已删除');
              }
            } else {
              throw Exception('删除失败');
            }
          } catch (e) {
            if (mounted) {
              AppSnackBar.showError('删除失败: ${e.toString()}');
            }
            rethrow;
          }
        },
      );
    } catch (e) {
      // debugPrint("Error showing or confirming delete dialog: $e");
    }
  }

  // 活动更新后的回调（目前主要由编辑触发）
  void _handleActivityUpdated() {
    setStateIfMounted(() {
      _refreshCounter++;
    });
  }

  Widget _buildLikeFab() {
    return GenericFloatingActionButton(
      onPressed: _handleLike,
      backgroundColor: _activity.isLiked
          ? Colors.red
          : Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white, // 确保图标颜色
      icon: _activity.isLiked ? Icons.favorite : Icons.favorite_border,
      tooltip: _activity.isLiked ? '取消点赞' : '点赞',
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingWidget();
    } else if (_error.isNotEmpty) {
      return CustomErrorWidget(errorMessage: _error);
    } else {
      // 传递编辑和删除的回调给 ActivityDetailContent
      return RefreshIndicator(
        onRefresh: _refreshActivity,
        child: LazyLayoutBuilder(
          windowStateProvider: widget.windowStateProvider,
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isDesktopLayout =
                DeviceUtils.isDesktopInThisWidth(screenWidth);
            return ActivityDetailContent(
              navigationInfo: _navigationInfo,
              inputStateService: widget.inputStateService,
              key: ValueKey(_refreshCounter), // 使用 Key 强制刷新
              currentUser: widget.authProvider.currentUser,
              userInfoService: widget.infoService,
              userFollowService: widget.followService,
              activity: _activity,
              isDesktopLayout: isDesktopLayout,
              comments: _activity.comments,
              isLoadingComments: _isLoadingComments,
              scrollController: _scrollController,
              onAddComment: _addComment,
              onCommentDeleted: _handleCommentDeleted,
              onCommentLike: (comment) =>
                  _handleCommentLikeToggled(comment, true),
              onCommentUnLike: (comment) =>
                  _handleCommentLikeToggled(comment, false),
              onActivityUpdated: _handleActivityUpdated, // 传递更新回调
              onEditActivity: _handleEditActivity, // 传递编辑回调
              onDeleteActivity: _handleDeleteActivity, // 传递删除回调
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '动态详情',
      ),
      body: _buildBody(),
      floatingActionButton: _buildLikeFab(),
    );
  }
}
