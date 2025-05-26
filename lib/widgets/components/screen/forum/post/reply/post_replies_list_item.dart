// lib/widgets/ui/components/forum/post_replies_list_item.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:suxingchahui/models/post/post_reply.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/post/post_reply_list.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart'; // 加载更多按钮
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/inputs/comment_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/buttons/login_prompt.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'post_reply_item.dart';

class PostRepliesListItem extends StatefulWidget {
  final User? currentUser;
  final AuthProvider authProvider;
  final UserInfoProvider infoProvider;
  final InputStateService inputStateService;
  final UserFollowService followService;
  final PostService postService;
  final String postId;
  final bool isScrollableInternally;

  const PostRepliesListItem({
    super.key,
    required this.currentUser,
    required this.authProvider,
    required this.infoProvider,
    required this.inputStateService,
    required this.followService,
    required this.postService,
    required this.postId,
    this.isScrollableInternally = false,
  });

  @override
  State<PostRepliesListItem> createState() => _PostRepliesListItemState();
}

class _PostRepliesListItemState extends State<PostRepliesListItem> {
  List<PostReply> _currentReplies = [];
  PaginationData? _paginationData;
  bool _isLoadingInitial = true; // 初始加载状态
  bool _isLoadingMore = false; // 加载更多状态
  String? _error; // 错误信息
  int _currentPage = 1;
  final int _replyLimit = PostService.postReplyPageLimit;

  bool _isSubmittingTopLevelReply = false;
  late final String _topLevelReplySlotName;
  ScrollController? _scrollController;
  bool _hasInitializedDependencies = false;

  late String _postId;

  @override
  void initState() {
    super.initState();
    _topLevelReplySlotName = 'post_reply_list_top_reply_${widget.postId}';
    if (widget.isScrollableInternally) {
      _scrollController = ScrollController()..addListener(_onScroll);
    }
    _postId = widget.postId; // 在 initState 中初始化
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
      _loadReplies(page: 1, isRefresh: true);
    }
  }

  @override
  void didUpdateWidget(covariant PostRepliesListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsReload = false;
    if (widget.currentUser != oldWidget.currentUser) {
      // 如果用户变化，可能需要重新加载以反映用户特定的回复状态（如点赞）
      // 但通常回复列表本身不直接依赖 currentUser，除非有特殊逻辑
    }
    if (widget.postId != oldWidget.postId) {
      _postId = widget.postId;
      needsReload = true; // postId 变化，必须重新加载
    }

    if (needsReload) {
      _loadReplies(page: 1, isRefresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController != null &&
        _scrollController!.position.pixels >=
            _scrollController!.position.maxScrollExtent * 0.9 &&
        !_isLoadingMore &&
        (_paginationData?.hasNextPage() ?? false)) {
      _loadMoreReplies();
    }
  }

  Future<void> _loadReplies({required int page, bool isRefresh = false}) async {
    if (page == 1 && !isRefresh) {
      // 初始加载
      if (mounted) setState(() => _isLoadingInitial = true);
    } else if (page > 1) {
      // 加载更多
      if (mounted) setState(() => _isLoadingMore = true);
    }
    if (isRefresh && mounted) {
      // 下拉刷新
      setState(() {
        _isLoadingInitial = true;
        _currentReplies.clear();
        _paginationData = null;
        _currentPage = 1;
        _error = null;
      });
    }

    try {
      final PostReplyList result = await widget.postService.getPostReplies(
          postId: _postId, page: page, limit: _replyLimit);
      if (!mounted) return;

      setState(() {
        if (page == 1) {
          _currentReplies = result.replies;
        } else {
          _currentReplies.addAll(result.replies);
        }
        _paginationData = result.pagination;
        _currentPage = result.pagination.page; // 更新当前页码
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreReplies() async {
    if (_isLoadingMore || !(_paginationData?.hasNextPage() ?? false)) return;
    await _loadReplies(page: _currentPage + 1);
  }

  Future<void> _submitTopLevelReply(
      BuildContext modalContext, String text) async {
    final content = text.trim();
    if (content.isEmpty || _isSubmittingTopLevelReply) return;
    if (widget.currentUser == null) {
      AppSnackBar.showError(modalContext, "请先登录");
      return;
    }

    if (mounted) setState(() => _isSubmittingTopLevelReply = true);

    try {
      await widget.postService.addReply(widget.postId, content, parentId: null);
      if (mounted) {
        widget.inputStateService.clearText(_topLevelReplySlotName);
        AppSnackBar.showSuccess(context, '评论发表成功');
        _loadReplies(page: 1, isRefresh: true); // 提交评论后刷新第一页

        if (modalContext.mounted && Navigator.canPop(modalContext)) {
          Navigator.pop(modalContext);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
            context, '评论发表失败: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) setState(() => _isSubmittingTopLevelReply = false);
    }
  }

  void _showTopLevelReplyModal(BuildContext context) {
    if (widget.currentUser == null) {
      NavigationUtils.showLoginDialog(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            final isSubmitting = _isSubmittingTopLevelReply;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: _buildTopReplyInput(bottomSheetContext, isSubmitting),
            );
          },
        );
      },
    );
  }

  Widget _buildTopReplyInput(
      BuildContext bottomSheetContext, bool isSubmitting) {
    return StreamBuilder<User?>(
        stream: widget.authProvider.currentUserStream,
        initialData: widget.authProvider.currentUser,
        builder: (context, authSnapshot) {
          return CommentInputField(
            currentUser: widget.currentUser,
            inputStateService: widget.inputStateService,
            slotName: _topLevelReplySlotName,
            hintText: '写下你的评论...',
            submitButtonText: '发表评论',
            isSubmitting: isSubmitting,
            maxLines: 4,
            maxLength: 500,
            onCancel: () {
              if (bottomSheetContext.mounted) {
                Navigator.pop(bottomSheetContext);
              }
            },
            onSubmit: (text) async {
              await _submitTopLevelReply(bottomSheetContext, text);
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    Widget contentChild;

    if (_isLoadingInitial && _currentReplies.isEmpty) {
      contentChild = Padding(
        padding: EdgeInsets.symmetric(vertical: 64.0),
        child: LoadingWidget.inline(message: "正在加载评论..."),
      );
    } else if (_error != null && _currentReplies.isEmpty) {
      contentChild = Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
        child: InlineErrorWidget(
          errorMessage: "加载评论列表出错: $_error",
          onRetry: () => _loadReplies(page: 1, isRefresh: true),
        ),
      );
    } else {
      final activeReplies = _currentReplies
          .where((r) => r.status == PostReplyStatus.active)
          .toList();
      final topLevelReplies = activeReplies
          .where((r) => r.parentId == null || r.parentId!.isEmpty)
          .toList();
      // 注意：如果后端API返回时已经是排序好的，这里可以不再次排序
      // 如果需要前端排序（例如按最新或最旧），可以在这里添加
      // topLevelReplies.sort((a, b) => b.createTime.compareTo(a.createTime)); // 示例：按最新排序

      final nestedRepliesMap = groupBy(
        activeReplies
            .where((r) => r.parentId != null && r.parentId!.isNotEmpty),
        (PostReply r) => r.parentId!,
      );

      if (topLevelReplies.isEmpty && !_isLoadingMore) {
        // 也检查是否正在加载更多
        contentChild = const Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0),
          child: EmptyStateWidget(
            message: "还没有人评论，快来抢沙发吧！",
            iconData: Icons.forum_outlined,
            iconSize: 32,
            iconColor: Color(0xFFBDBDBD),
          ),
        );
      } else {
        Widget listView = ListView.builder(
            controller:
                widget.isScrollableInternally ? _scrollController : null,
            shrinkWrap: !widget.isScrollableInternally,
            physics: widget.isScrollableInternally
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: topLevelReplies.length +
                (_isLoadingMore || (_paginationData?.hasNextPage() ?? false)
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              if (index == topLevelReplies.length) {
                if (_isLoadingMore) {
                  return Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LoadingWidget.inline(message: "加载更多..."),
                  );
                } else if (_paginationData?.hasNextPage() ?? false) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: FunctionalTextButton(
                        label: "加载更多评论",
                        onPressed: _loadMoreReplies,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final topReply = topLevelReplies[index];
              final children = nestedRepliesMap[topReply.id] ?? [];
              // 为嵌套回复也进行排序（如果需要）
              // children.sort((a,b) => a.createTime.compareTo(b.createTime)); // 示例：按最旧排序

              return StreamBuilder<User?>(
                stream: widget.authProvider.currentUserStream,
                initialData: widget.authProvider.currentUser,
                builder: (context, authSnapshot) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PostReplyItem(
                          inputStateService: widget.inputStateService,
                          authProvider: widget.authProvider,
                          followService: widget.followService,
                          infoProvider: widget.infoProvider,
                          currentUser: authSnapshot.data,
                          postService: widget.postService,
                          reply: topReply,
                          floor: (_paginationData != null &&
                                  _paginationData!.page == 1)
                              ? (topLevelReplies.length - index) // 只有第一页尝试计算楼层
                              : 0, // 其他页或无分页信息时不计算
                          postId: widget.postId,
                          onActionSuccess: () =>
                              _loadReplies(page: 1, isRefresh: true),
                        ),
                        if (children.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 32.0, top: 8.0, bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children.map((nestedReply) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: PostReplyItem(
                                    inputStateService: widget.inputStateService,
                                    authProvider: widget.authProvider,
                                    currentUser: authSnapshot.data,
                                    postService: widget.postService,
                                    reply: nestedReply,
                                    followService: widget.followService,
                                    infoProvider: widget.infoProvider,
                                    floor: 0,
                                    postId: widget.postId,
                                    onActionSuccess: () =>
                                        _loadReplies(page: 1, isRefresh: true),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        if (index < topLevelReplies.length - 1)
                          const Divider(height: 32, thickness: 0.5, indent: 48),
                      ],
                    ),
                  );
                },
              );
            });

        if (widget.isScrollableInternally) {
          assert(_scrollController != null,
              'ScrollController should be initialized when isScrollableInternally is true');
          contentChild = Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: listView,
          );
        } else {
          contentChild = listView;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:
            widget.isScrollableInternally ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '全部评论',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (widget.currentUser != null)
                  FunctionalButton(
                    label: "发表评论",
                    icon: Icons.add_comment_outlined,
                    onPressed: () => _showTopLevelReplyModal(context),
                  )
                else
                  const LoginPrompt()
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          widget.isScrollableInternally
              ? Expanded(child: contentChild)
              : contentChild,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    _scrollController?.dispose();
    super.dispose();
  }
}
