// lib/screens/activity/activity_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 引入 Provider
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/widgets/components/screen/activity/activity_detail_content.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 引入 AuthProvider
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/edit_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;
  final UserActivity? activity;

  const ActivityDetailScreen({
    Key? key,
    required this.activityId,
    this.activity,
  }) : super(key: key);

  @override
  _ActivityDetailScreenState createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final UserActivityService _activityService = UserActivityService();
  UserActivity? _activity;
  bool _isLoading = true;
  bool _isLoadingComments = false;
  String _error = '';
  final ScrollController _scrollController = ScrollController();
  // int _currentPage = 1; // 评论分页暂时不用
  // int _totalCommentPages = 1;
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeActivity();
    });
    _scrollController.addListener(_scrollListener);
  }

  // 封装初始化逻辑
  void _initializeActivity() {
    if (widget.activity != null) {
      setStateIfMounted(() {
        _activity = widget.activity;
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

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
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
          await _activityService.getActivityDetail(widget.activityId);
      setStateIfMounted(() {
        _activity = activity;
        _isLoading = false;
        if (activity == null) {
          _error = '未能加载活动详情';
        }
      });
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
    if (_activity == null) return;
    HapticFeedback.lightImpact();
    final bool currentlyLiked = _activity!.isLiked;
    final int currentLikesCount = _activity!.likesCount;
    setStateIfMounted(() {
      _activity!.isLiked = !currentlyLiked;
      _activity!.likesCount =
          currentlyLiked ? currentLikesCount - 1 : currentLikesCount + 1;
    });
    try {
      bool success = currentlyLiked
          ? await _activityService.unlikeActivity(_activity!.id)
          : await _activityService.likeActivity(_activity!.id);
      if (!success) {
        throw Exception('API call failed'); // 抛出异常以便 catch 处理回滚
      }
    } catch (e) {
      setStateIfMounted(() {
        // 回滚 UI
        _activity!.isLiked = currentlyLiked;
        _activity!.likesCount = currentLikesCount;
      });
      if (mounted) {
        AppSnackBar.showError(context, '操作失败，请稍后重试');
      }
    }
  }

  Future<void> _addComment(String content) async {
    if (content.trim().isEmpty || _activity == null) return;
    try {
      final comment =
          await _activityService.commentOnActivity(_activity!.id, content);
      if (comment != null) {
        setStateIfMounted(() {
          _activity!.comments.insert(0, comment);
          _activity!.commentsCount += 1;
          _refreshCounter++; // 强制刷新
        });
        // 滚动逻辑 (可选)
        // if (_scrollController.hasClients) { ... }
      } else {
        throw Exception('Comment creation failed');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context,
            '评论失败: ${e is Exception ? e.toString().replaceFirst("Exception: ", "") : "请稍后重试"}');
      }
    }
  }

  void _shareActivity() {
    if (_activity == null) return;
    final String shareText =
        '来自宿星茶会的动态：${_activity!.content}\n\n来自用户：${_activity!.user?['username'] ?? '未知用户'}';
    Share.share(shareText);
  }

  void _handleCommentDeleted(String commentId) {
    // 这里是父级处理删除逻辑的地方，通常会调用 Service
    print("ActivityDetailScreen: Handling delete request for comment $commentId");
    // --- 这里应该调用 Service 删除，并处理 UI 更新 (移除) ---
    // 这个方法现在由 ActivityCommentItem -> ActivityCommentsSection -> 这里 最终调用
    // 之前在 ActivityFeedScreen 的实现是正确的，应该类似：
    CustomConfirmDialog.show(
        context: context, title: "确认删除", message: "确定删除这条评论吗？",
        confirmButtonText: "删除", confirmButtonColor: Colors.red,
        iconData: Icons.delete_outline, iconColor: Colors.red,
        onConfirm: () async {
          print("Delete comment confirmed for $commentId");
          try {
            final success = await _activityService.deleteComment(_activity!.id, commentId);
            if (success && mounted) {
              // --- 从本地列表移除评论并更新计数 ---
              setStateIfMounted(() {
                _activity!.comments.removeWhere((c) => c.id == commentId);
                _activity!.commentsCount = _activity!.comments.length;
                _refreshCounter++; // 强制 UI 刷新
              });
              AppSnackBar.showSuccess(context, '评论已删除');
            } else if (mounted) {
              throw Exception("删除评论失败");
            }
          } catch (e) { if (mounted) AppSnackBar.showError(context, '删除失败: $e'); rethrow; }
        }
    );
  }

  void _handleCommentLikeToggled(ActivityComment updatedComment) {
    if (_activity == null) return;
    setStateIfMounted(() {
      // 在 _activity!.comments 中找到对应的评论并替换
      final index = _activity!.comments.indexWhere((c) => c.id == updatedComment.id);
      if (index != -1) {
        _activity!.comments[index] = updatedComment; // 使用更新后的对象替换旧的
        // 不需要强制刷新计数器了，因为 Service 调用 -> 缓存失效 -> 监听器刷新 会处理
        // _refreshCounter++;
      }
    });
  }


  // --- 编辑活动处理 ---
  Future<void> _handleEditActivity() async {
    if (_activity == null) return;
    final authProvider =
        context.read<AuthProvider>(); // 使用 context.read 获取 Provider

    // 权限检查：必须是作者本人
    if (!authProvider.isLoggedIn ||
        authProvider.currentUserId != _activity!.userId) {
      if (mounted) {
        AppSnackBar.showError(context, '您没有权限编辑此动态');
      }
      return;
    }

    try {
      // 使用 EditDialog.show
      await EditDialog.show(
        context: context,
        title: '编辑动态',
        initialText: _activity!.content,
        hintText: '输入新的动态内容...',
        maxLines: 5, // 可以调整最大行数
        onSave: (newText) async {
          // onSave 是异步的
          if (newText == _activity!.content) return; // 内容未改变则不提交

          try {
            // 调用服务更新活动
            final success = await _activityService.updateActivity(
                _activity!.id, newText, _activity!.metadata);

            if (success) {
              // 更新本地状态
              setStateIfMounted(() {
                final currentActivity = _activity!;
                // 创建一个新的 UserActivity 实例，复制旧数据并更新字段

                _activity = UserActivity(
                  id: currentActivity.id,
                  userId: currentActivity.userId,
                  type: currentActivity.type,
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
                  user: currentActivity.user, // 复制旧值
                  target: currentActivity.target, // 复制旧值
                  comments: currentActivity.comments, // 复制旧值
                );
                _refreshCounter++; // 强制刷新UI
              });
              if (mounted) {
                AppSnackBar.showSuccess(context, '动态更新成功');
              }
            } else {
              throw Exception('Update failed');
            }
          } catch (e) {
            if (mounted) {
              AppSnackBar.showError(context,
                  '更新失败: ${e is Exception ? e.toString().replaceFirst("Exception: ", "") : "请稍后重试"}');
            }
            // 重新抛出，让 EditDialog 的调用者知道出错了（如果需要）
            rethrow;
          }
        },
      );
    } catch (e) {}
  }

  // --- 删除活动处理 ---
  Future<void> _handleDeleteActivity() async {
    if (_activity == null) return;
    final authProvider = context.read<AuthProvider>();

    // 权限检查：作者本人 或 管理员
    final bool canDelete = authProvider.isLoggedIn &&
        (authProvider.currentUserId == _activity!.userId ||
            authProvider.isAdmin);

    if (!canDelete) {
      if (mounted) {
        AppSnackBar.showError(context, '您没有权限删除此动态');
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
                await _activityService.deleteActivity(_activity!.id);
            if (success) {
              if (mounted) {
                // 删除成功后，关闭当前页面
                Navigator.pop(context);
                AppSnackBar.showSuccess(context, '动态已删除');
              }
            } else {
              throw Exception('Deletion failed');
            }
          } catch (e) {
            if (mounted) {
              AppSnackBar.showError(context,
                  '删除失败: ${e is Exception ? e.toString().replaceFirst("Exception: ", "") : "请稍后重试"}');
            }
            rethrow;
          }
        },
      );
    } catch (e) {
      debugPrint("Error showing or confirming delete dialog: $e");
    }
  }

  // 活动更新后的回调（目前主要由编辑触发）
  void _handleActivityUpdated() {
    setStateIfMounted(() {
      _refreshCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    Widget body;

    if (_isLoading) {
      body = LoadingWidget();
    } else if (_error.isNotEmpty && _activity == null) {
      body = InlineErrorWidget(errorMessage: _error);
    } else if (_activity == null) {
      body = InlineErrorWidget(errorMessage: '无法加载动态内容');
    } else {
      // 传递编辑和删除的回调给 ActivityDetailContent
      body = RefreshIndicator(
        onRefresh: _refreshActivity,
        child: ActivityDetailContent(
          key: ValueKey(_refreshCounter), // 使用 Key 强制刷新
          activity: _activity!,
          comments: _activity!.comments,
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

    return Scaffold(
      appBar: isDesktop
          ? CustomAppBar(
              title: '动态详情',
              actions: _activity == null
                  ? []
                  : [
                      // 确保 _activity 不为空
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: _shareActivity,
                        tooltip: '分享动态',
                      ),
                      IconButton(
                        icon: Icon(_activity!.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border),
                        color: _activity!.isLiked ? Colors.red : null,
                        onPressed: _handleLike,
                        tooltip: _activity!.isLiked ? '取消点赞' : '点赞',
                      ),
                      const SizedBox(width: 16),
                    ],
            )
          : CustomAppBar(
              title: '动态详情',
              actions: _activity == null
                  ? []
                  : [
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: _shareActivity,
                        tooltip: '分享动态',
                      ),
                    ],
            ),
      body: body,
      floatingActionButton: (!isDesktop && _activity != null) // 移动端且活动已加载
          ? GenericFloatingActionButton(
              onPressed: _handleLike,
              backgroundColor: _activity!.isLiked
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white, // 确保图标颜色
              icon: _activity!.isLiked ? Icons.favorite : Icons.favorite_border,
              tooltip: _activity!.isLiked ? '取消点赞' : '点赞',
            )
          : null,
    );
  }
}
