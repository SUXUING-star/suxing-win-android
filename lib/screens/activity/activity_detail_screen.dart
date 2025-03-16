// lib/screens/activity/activity_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/widgets/components/screen/activity/activity_detail_content.dart';
import 'package:suxingchahui/widgets/common/appbar/custom_app_bar.dart';
import 'package:suxingchahui/screens/profile/open_profile_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;
  final UserActivity? activity; // 可选的活动数据，如果已经有数据可以传入

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
  List<ActivityComment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingComments = false;
  String _error = '';
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMoreComments = false;
  int _currentPage = 1;
  int _totalCommentPages = 1;
  int _refreshCounter = 0; // 添加刷新计数器以强制重建界面

  @override
  void initState() {
    super.initState();

    if (widget.activity != null) {
      setState(() {
        _activity = widget.activity;
        _isLoading = false;
      });
      _loadComments();
    } else {
      _loadActivity();
    }

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 滚动监听器，用于触发加载更多评论
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreComments();
    }
  }

  // 加载活动详情
  Future<void> _loadActivity() async {
    if (_isLoading && _activity == null) {
      try {
        final activity = await _activityService.getActivityDetail(widget.activityId);

        if (mounted) {
          setState(() {
            _activity = activity;
            _isLoading = false;
          });

          // 活动加载成功后加载评论
          _loadComments();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = '加载活动详情失败: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  // 刷新活动详情和评论
  Future<void> _refreshActivity() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      await _loadActivity();
      await _loadComments();
    } finally {
      setState(() {
        _isLoading = false;
        // 增加刷新计数器以强制重建界面
        _refreshCounter++;
      });
    }
  }

  // 加载评论
  Future<void> _loadComments() async {
    if (_isLoadingComments || _activity == null) return;

    setState(() {
      _isLoadingComments = true;
      _currentPage = 1;
    });

    try {
      final comments = await _activityService.getActivityComments(_activity!.id);

      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
          _totalCommentPages = 1; // 由于API没有分页信息，我们默认只有一页
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载评论失败: $e';
          _isLoadingComments = false;
        });
      }
    }
  }

  // 加载更多评论 - 由于API当前不支持分页，这个方法暂时不执行任何操作
  Future<void> _loadMoreComments() async {
    // 现有API不支持评论分页，此处为未来扩展预留
    return;
  }

  // 处理点赞
  Future<void> _handleLike() async {
    if (_activity == null) return;

    HapticFeedback.lightImpact();

    bool success;

    if (_activity!.isLiked) {
      success = await _activityService.unlikeActivity(_activity!.id);
      if (success && mounted) {
        setState(() {
          _activity!.isLiked = false;
          _activity!.likesCount -= 1;
        });
      }
    } else {
      success = await _activityService.likeActivity(_activity!.id);
      if (success && mounted) {
        setState(() {
          _activity!.isLiked = true;
          _activity!.likesCount += 1;
        });
      }
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败，请稍后重试')),
      );
    }
  }

  // 添加评论
  Future<void> _addComment(String content) async {
    if (content.trim().isEmpty || _activity == null) return;

    final comment = await _activityService.commentOnActivity(_activity!.id, content);
    if (comment != null && mounted) {
      setState(() {
        _comments.insert(0, comment);
        if (_activity != null) {
          _activity!.commentsCount += 1;
        }
      });

      // 滚动到评论顶部
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('评论失败，请稍后重试')),
      );
    }
  }

  // 分享活动
  void _shareActivity() {
    if (_activity == null) return;

    final String shareText = '来自速星茶会的动态：${_activity!.content}\n\n来自用户：${_activity!.user?['username'] ?? '未知用户'}';

    Share.share(shareText);
  }

  // 处理评论删除
  void _handleCommentDeleted(String commentId) {
    setState(() {
      _comments.removeWhere((comment) => comment.id == commentId);
      if (_activity != null) {
        _activity!.commentsCount = _activity!.commentsCount > 0 ? _activity!.commentsCount - 1 : 0;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('评论已删除')),
    );
  }

  // 评论点赞切换回调
  void _handleCommentLikeToggled(ActivityComment comment) {
    setState(() {
      // 评论状态已在ActivityCommentItem中更新
    });
  }

  // 处理活动更新
  void _handleActivityUpdated() {
    setState(() {
      // 强制重建界面
      _refreshCounter++;
    });
  }

  // 导航到用户个人资料页
  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 判断是否为桌面端布局
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (_isLoading) {
      return Scaffold(
        appBar: isDesktop
            ? CustomAppBar(title: '动态详情')
            : AppBar(title: const Text('动态详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty && _activity == null) {
      return Scaffold(
        appBar: isDesktop
            ? CustomAppBar(title: '错误')
            : AppBar(title: const Text('错误')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_error),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadActivity,
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    // 确保_activity不为空
    if (_activity == null) {
      return Scaffold(
        appBar: isDesktop
            ? CustomAppBar(title: '动态详情')
            : AppBar(title: const Text('动态详情')),
        body: const Center(child: Text('无法加载动态内容')),
      );
    }

    // 使用ActivityDetailContent组件渲染内容
    return Scaffold(
      appBar: isDesktop
          ? CustomAppBar(
        title: '动态详情',
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareActivity,
            tooltip: '分享动态',
          ),
          IconButton(
            icon: Icon(_activity!.isLiked ? Icons.favorite : Icons.favorite_border),
            color: _activity!.isLiked ? Colors.red : null,
            onPressed: _handleLike,
            tooltip: _activity!.isLiked ? '取消点赞' : '点赞',
          ),
          const SizedBox(width: 16),
        ],
      )
          : AppBar(
        title: const Text('动态详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareActivity,
            tooltip: '分享动态',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshActivity,
        child: ActivityDetailContent(
          activity: _activity!,
          comments: _comments,
          isLoadingComments: _isLoadingComments,
          scrollController: _scrollController,
          onAddComment: _addComment,
          onCommentDeleted: _handleCommentDeleted,
          onCommentLikeToggled: _handleCommentLikeToggled,
          onActivityUpdated: _handleActivityUpdated,
        ),
      ),
      // 只在移动端显示悬浮点赞按钮
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
        onPressed: _handleLike,
        backgroundColor: _activity!.isLiked ? Colors.red : Theme.of(context).primaryColor,
        child: Icon(
          _activity!.isLiked ? Icons.favorite : Icons.favorite_border,
          color: Colors.white,
        ),
      )
          : null,
    );
  }
}