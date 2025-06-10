// lib/screens/activity/activity_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/components/screen/activity/activity_detail_content.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 引入 AuthProvider
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/edit_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;
  final UserActivity? activity;
  final AuthProvider authProvider;
  final ActivityService activityService;
  final UserFollowService followService;
  final InputStateService inputStateService;
  final UserInfoProvider infoProvider;

  const ActivityDetailScreen({
    super.key,
    required this.activityId,
    required this.activityService,
    required this.followService,
    required this.authProvider,
    required this.inputStateService,
    required this.infoProvider,
    this.activity,
  });

  @override
  _ActivityDetailScreenState createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late UserActivity _activity;
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

    if (widget.activity != null) {
      _activity = widget.activity!;
      _isLoading = false; // 标记为非加载状态
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeActivity();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 封装初始化逻辑
  void _initializeActivity() {
    if (widget.activity != null) {
      setStateIfMounted(() {
        _activity = widget.activity!;
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
      final activity =
          await widget.activityService.getActivityDetail(widget.activityId);
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

  Future<void> _handleLike() async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    HapticFeedback.lightImpact();
    final bool currentlyLiked = _activity.isLiked;
    final int currentLikesCount = _activity.likesCount;
    setStateIfMounted(() {
      _activity.isLiked = !currentlyLiked;
      _activity.likesCount =
          currentlyLiked ? currentLikesCount - 1 : currentLikesCount + 1;
    });
    try {
      bool success = currentlyLiked
          ? await widget.activityService.unlikeActivity(_activity.id)
          : await widget.activityService.likeActivity(_activity.id);
      if (!success) {
        throw Exception('发生异常报错'); // 抛出异常以便 catch 处理回滚
      }
    } catch (e) {
      setStateIfMounted(() {
        // 回滚 UI
        _activity.isLiked = currentlyLiked;
        _activity.likesCount = currentLikesCount;
      });

      AppSnackBar.showError('操作失败，请稍后重试');
    }
  }

  Future<void> _addComment(String content) async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (content.trim().isEmpty) return;
    try {
      final comment =
          await widget.activityService.commentOnActivity(_activity.id, content);
      if (comment != null) {
        setStateIfMounted(() {
          _activity.comments.insert(0, comment);
          _activity.commentsCount += 1;
          _refreshCounter++; // 强制刷新
        });
        // 滚动逻辑 (可选)
        // if (_scrollController.hasClients) { ... }
      } else {
        throw Exception('Comment creation failed');
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
            final success = await widget.activityService
                .deleteComment(_activity.id, comment);
            if (success && mounted) {
              // --- 从本地列表移除评论并更新计数 ---
              setStateIfMounted(() {
                _activity.comments.removeWhere((c) => c.id == commentId);
                _activity.commentsCount = _activity.comments.length;
                _refreshCounter++; // 强制 UI 刷新
              });
              AppSnackBar.showSuccess('评论已删除');
            } else if (mounted) {
              throw Exception("删除评论失败");
            }
          } catch (e) {
            if (mounted) AppSnackBar.showError('删除失败: ${e.toString()}');
            rethrow;
          }
        });
  }

  void _handleCommentLikeToggled(ActivityComment updatedComment) {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    setStateIfMounted(() {
      // 在 _activity!.comments 中找到对应的评论并替换
      final index =
          _activity.comments.indexWhere((c) => c.id == updatedComment.id);
      if (index != -1) {
        _activity.comments[index] = updatedComment; // 使用更新后的对象替换旧的
        // 不需要强制刷新计数器了，因为 Service 调用 -> 缓存失效 -> 监听器刷新 会处理
        // _refreshCounter++;
      }
    });
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
            final success = await widget.activityService
                .updateActivity(_activity, newText, _activity.metadata);

            if (success) {
              // 更新本地状态
              setStateIfMounted(() {
                final currentActivity = _activity;
                // 创建一个新的 UserActivity 实例，复制旧数据并更新字段

                _activity = UserActivity(
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
                _refreshCounter++; // 强制刷新UI
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
            final success =
                await widget.activityService.deleteActivity(_activity);
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
        child: ActivityDetailContent(
          inputStateService: widget.inputStateService,
          key: ValueKey(_refreshCounter), // 使用 Key 强制刷新
          currentUser: widget.authProvider.currentUser,
          userInfoProvider: widget.infoProvider,
          userFollowService: widget.followService,
          activity: _activity,
          comments: _activity.comments,
          isLoadingComments: _isLoadingComments,
          scrollController: _scrollController,
          onAddComment: _addComment,
          onCommentDeleted: _handleCommentDeleted,
          onCommentLikeToggled: _handleCommentLikeToggled,
          onActivityUpdated: _handleActivityUpdated, // 传递更新回调
          onEditActivity: _handleEditActivity, // 传递编辑回调
          onDeleteActivity: _handleDeleteActivity, // 传递删除回调
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
