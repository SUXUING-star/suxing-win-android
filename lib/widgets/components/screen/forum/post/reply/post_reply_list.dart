import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // 用于 groupBy
import 'package:provider/provider.dart'; // 获取 AuthProvider 和 InputStateService
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_data_status.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 发评论按钮
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart'; // 空状态
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误状态
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载状态
import 'package:suxingchahui/widgets/ui/inputs/comment_input_field.dart'; // 评论输入框
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // Snackbar 提示
import 'package:suxingchahui/widgets/ui/buttons/login_prompt.dart'; // 登录提示
import 'package:suxingchahui/models/post/post.dart'; // Reply, ReplyStatus 模型
import 'package:suxingchahui/services/main/forum/forum_service.dart'; // 核心服务
import 'post_reply_item.dart'; // 评论项组件

/// PostReplyList - 显示帖子评论列表，并管理自身的加载、刷新和顶层评论提交。
class PostReplyList extends StatefulWidget {
  final User? currentUser;

  /// 帖子 ID
  final String postId;

  /// 标记列表是否需要自己处理滚动（通常桌面端为 true，移动端嵌套在可滚动视图中为 false）
  final bool isScrollableInternally;

  const PostReplyList({
    super.key,
    required this.currentUser,
    required this.postId,
    this.isScrollableInternally = false, // 默认为 false，依赖外部滚动
  });

  @override
  State<PostReplyList> createState() => _PostReplyListState();
}

class _PostReplyListState extends State<PostReplyList> {
  // 内部状态
  late Future<List<Reply>> _repliesFuture; // 用于 FutureBuilder 的数据源
  bool _isSubmittingTopLevelReply = false; // 标记顶层评论是否正在提交
  late final String _topLevelReplySlotName; // 顶层评论输入框的唯一标识符
  ScrollController? _scrollController; // 滚动控制器（仅在需要内部滚动时创建）
  bool _hasInitializedDependencies = false;
  late final ForumService _forumService;
  User? _currentUser;
  late String _postId;

  @override
  void initState() {
    super.initState();
    // 初始化顶层评论输入框的 SlotName
    _topLevelReplySlotName = 'post_reply_list_top_reply_${widget.postId}';
    // 如果需要内部滚动，则创建 ScrollController
    if (widget.isScrollableInternally) {
      _scrollController = ScrollController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _forumService = context.read<ForumService>();
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _currentUser = widget.currentUser;
      _postId = widget.postId;
      _loadReplies();
    }
  }

  @override
  void didUpdateWidget(covariant PostReplyList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
    if (widget.postId != oldWidget.postId || _postId != widget.postId) {
      setState(() {
        _postId = widget.postId;
      });
    }
  }

  @override
  void dispose() {
    // 释放滚动控制器 (如果创建了)
    _scrollController?.dispose();
    super.dispose();
  }

  /// 核心加载/刷新逻辑
  void _loadReplies() {
    setState(() {
      _repliesFuture = _forumService.fetchReplies(widget.postId);
    });
  }

  /// 处理顶层评论提交的完整逻辑
  Future<void> _submitTopLevelReply(
      BuildContext modalContext, String text) async {
    final content = text.trim();
    if (content.isEmpty || _isSubmittingTopLevelReply) return;
    if (widget.currentUser == null) {
      AppSnackBar.showError(modalContext, "请先登录");
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmittingTopLevelReply = true;
      });
    }

    try {
      await _forumService.addReply(widget.postId, content, parentId: null);
      if (mounted) {
        // 保持用途明确
        InputStateService? inputStateService =
            Provider.of<InputStateService>(context, listen: false);
        inputStateService.clearText(_topLevelReplySlotName);
        inputStateService = null;
        //

        AppSnackBar.showSuccess(context, '评论发表成功');
        _loadReplies(); // 重新加载列表

        // 尝试安全地关闭模态框
        if (modalContext.mounted && Navigator.canPop(modalContext)) {
          Navigator.pop(modalContext);
        }
      }
    } catch (e) {
      if (mounted) {
        // 同样，使用 PostReplyList 的 context 显示错误
        AppSnackBar.showError(
            context, '评论发表失败: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingTopLevelReply = false;
        });
      }
    }
  }

  /// 显示用于发表顶层评论的模态底部输入框
  void _showTopLevelReplyModal(BuildContext context) {
    if (widget.currentUser == null) {
      NavigationUtils.showLoginDialog(context);
      return; // 或者显示登录提示
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        // 使用 StatefulBuilder 确保模态框内的提交状态能独立更新按钮 UI
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            // 直接从 _PostReplyListState 读取提交状态
            final isSubmitting = _isSubmittingTopLevelReply;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: CommentInputField(
                slotName: _topLevelReplySlotName,
                hintText: '写下你的评论...',
                submitButtonText: '发表评论',
                isSubmitting: isSubmitting, // 使用状态控制按钮加载
                maxLines: 4,
                maxLength: 500,
                onCancel: () {
                  if (bottomSheetContext.mounted) {
                    Navigator.pop(bottomSheetContext);
                  }
                },
                onSubmit: (text) async {
                  // 调用外部状态的提交方法，并传入模态框 context
                  await _submitTopLevelReply(bottomSheetContext, text);
                  // 注意：关闭模态框的逻辑现在在 _submitTopLevelReply 成功时处理
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = context.watch<UserInfoProvider>();

    return FutureBuilder<List<Reply>>(
      future: _repliesFuture,
      builder: (context, snapshot) {
        Widget buildLayout(Widget contentChild) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: widget.isScrollableInternally
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                // --- 标题和发表评论按钮区域 ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '全部评论',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (widget.currentUser != null)
                        FunctionalButton(
                          label: "发表评论",
                          icon: Icons.add_comment_outlined,
                          onPressed: () => _showTopLevelReplyModal(context),
                        )
                      else
                        const LoginPrompt() // 使用 const 优化
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.5), // 分隔线

                // --- 列表内容区域 ---
                // 根据是否需要内部滚动决定如何放置 contentChild
                widget.isScrollableInternally
                    ? Expanded(child: contentChild) // 桌面: Expanded 填充
                    : contentChild, // 移动: 直接放置，依赖外部滚动
              ],
            ),
          );
        }

        // --- 处理 FutureBuilder 的各种状态 ---

        // 1. 错误状态
        if (snapshot.hasError) {
          return buildLayout(Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
            child: InlineErrorWidget(
              errorMessage: "加载评论列表出错: ${snapshot.error}",
              onRetry: _loadReplies,
            ),
          ));
        }

        // 2. 加载状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildLayout(Padding(
            // 使用 const 优化
            padding: EdgeInsets.symmetric(vertical: 64.0),
            child: LoadingWidget.inline(message: "正在加载评论..."),
          ));
        }

        // 3. 成功获取数据
        final allReplies = snapshot.data ?? [];
        final activeReplies =
            allReplies.where((r) => r.status == ReplyStatus.active).toList();

        final topLevelReplies = activeReplies
            .where((r) => r.parentId == null || r.parentId!.isEmpty)
            .toList();
        final nestedRepliesMap = groupBy(
          activeReplies
              .where((r) => r.parentId != null && r.parentId!.isNotEmpty),
          (Reply r) => r.parentId!,
        );

        topLevelReplies.sort((a, b) => b.createTime.compareTo(a.createTime));

        // --- 构建列表内容 Widget (核心改动在这里) ---
        Widget listContent; // 先声明一个 Widget 变量

        if (topLevelReplies.isEmpty) {
          // 情况 A: 没有评论
          listContent = const Padding(
            // 使用 const 优化
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: EmptyStateWidget(
              message: "还没有人评论，快来抢沙发吧！",
              iconData: Icons.forum_outlined,
              iconSize: 32,
              iconColor: Color(0xFFBDBDBD), // Colors.grey[400]
            ),
          );
        } else {
          // 情况 B: 有评论，构建 ListView
          Widget listView = ListView.builder(
            // 仅在需要内部滚动时关联控制器
            controller:
                widget.isScrollableInternally ? _scrollController : null,
            // 根据是否需要内部滚动设置 shrinkWrap 和 physics
            shrinkWrap: !widget.isScrollableInternally, // 移动端 true, 桌面端 false
            physics: widget.isScrollableInternally
                ? const AlwaysScrollableScrollPhysics() // 桌面端允许滚动
                : const NeverScrollableScrollPhysics(), // 移动端禁止滚动
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: topLevelReplies.length,
            itemBuilder: (context, index) {
              final topReply = topLevelReplies[index];
              final children = nestedRepliesMap[topReply.id] ?? [];
              final userId = topReply.authorId;
              userInfoProvider.ensureUserInfoLoaded(userId);

              final UserDataStatus userDataStatus =
                  userInfoProvider.getUserStatus(userId);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 渲染顶层回复项
                    PostReplyItem(
                      currentUser: widget.currentUser,
                      userDataStatus: userDataStatus,
                      forumService: _forumService,
                      reply: topReply,
                      floor: topLevelReplies.length - index,
                      postId: widget.postId,
                      onActionSuccess: _loadReplies, // 回调刷新
                    ),
                    // 渲染嵌套回复
                    if (children.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 32.0, top: 8.0, bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children.map((nestedReply) {
                            final userId = nestedReply.authorId;
                            userInfoProvider.ensureUserInfoLoaded(userId);

                            final UserDataStatus userDataStatus =
                                userInfoProvider.getUserStatus(userId);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: PostReplyItem(
                                currentUser: widget.currentUser,
                                forumService: _forumService,
                                reply: nestedReply,
                                userDataStatus: userDataStatus,
                                floor: 0, // 嵌套不显示楼层
                                postId: widget.postId,
                                onActionSuccess: _loadReplies, // 回调刷新
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    // 分隔线
                    if (index < topLevelReplies.length - 1)
                      const Divider(height: 32, thickness: 0.5, indent: 48),
                  ],
                ),
              );
            },
          );

          // **核心改动：根据 isScrollableInternally 决定是否包裹 Scrollbar**
          if (widget.isScrollableInternally) {
            // 需要内部滚动：包裹 Scrollbar，并使用 _scrollController
            // 断言确保 controller 不是 null (理论上 initState 保证了)
            assert(_scrollController != null,
                'ScrollController should be initialized when isScrollableInternally is true');
            listContent = Scrollbar(
              controller: _scrollController,
              thumbVisibility: true, // 内部滚动时显示滚动条
              child: listView,
            );
          } else {
            // 不需要内部滚动：直接使用 ListView
            listContent = listView;
          }
        }

        // --- 返回最终构建的包含列表内容的布局 ---
        return buildLayout(listContent);
      },
    );
  }
}
