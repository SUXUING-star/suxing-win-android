// lib/widgets/components/screen/activity/card/activity_card.dart

/// 该文件定义了 ActivityCard 组件，用于显示用户动态信息。
/// ActivityCard 封装了动态的头部、内容、目标、互动按钮和评论区。
library;

import 'dart:async'; // 导入异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/models/activity/user_activity.dart'; // 用户动态模型
import 'package:suxingchahui/models/user/user.dart'; // 用户模型
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 输入状态 Provider
import 'package:suxingchahui/providers/user/user_info_provider.dart'; // 用户信息 Provider
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_header.dart'; // 动态头部组件
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_target.dart'; // 动态目标组件
import 'package:suxingchahui/widgets/components/screen/activity/button/activity_action_buttons.dart'; // 动态操作按钮组件
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_item.dart'; // 动态评论项组件
import 'package:suxingchahui/widgets/components/screen/activity/comment/activity_comment_input.dart'; // 动态评论输入框组件
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_target_navigation.dart'; // 动态目标导航组件
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart'; // 应用 Snackbar
import 'package:flutter/services.dart'; // 导入 HapticFeedback
import 'dart:math' as math; // 导入数学函数

/// `ActivityCard` 类：显示用户动态的卡片组件。
///
/// 该组件展示一条用户动态的完整信息，包括发布者、内容、相关目标、互动操作和评论区。
class ActivityCard extends StatefulWidget {
  final UserActivity activity; // 要显示的动态数据
  final UserInfoProvider infoProvider; // 用户信息 Provider
  final UserFollowService followService; // 用户关注服务
  final InputStateService inputStateService; // 输入状态服务
  final User? currentUser; // 当前登录用户
  final bool isAlternate; // 是否使用交替布局样式
  final Function(UserActivity activity)? onUpdated; // 动态更新后的回调
  final bool isInDetailView; // 是否在详情视图中
  final Function(UserActivity)? onActivityTap; // 动态点击回调
  final bool hasOwnBackground; // 是否拥有自己的背景样式

  final VoidCallback? onEdit; // 编辑动态回调
  final VoidCallback? onDelete; // 删除动态回调
  final Future<bool> Function()? onLike; // 点赞动态回调
  final Future<bool> Function()? onUnlike; // 取消点赞动态回调
  final FutureOr<ActivityComment?> Function(String activityId, String content)?
      onAddComment; // 添加评论回调
  final FutureOr<void> Function(String activityId, ActivityComment comment)?
      onDeleteComment; // 删除评论回调
  final Future<bool> Function(String activityId, String commentId)?
      onLikeComment; // 评论点赞回调
  final Future<bool> Function(String activityId, String commentId)?
      onUnlikeComment; // 评论取消点赞回调

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [activity]：要显示的动态数据。
  /// [inputStateService]：输入状态服务。
  /// [currentUser]：当前登录用户。
  /// [followService]：用户关注服务。
  /// [infoProvider]：用户信息 Provider。
  /// [isAlternate]：是否使用交替布局样式。
  /// [onUpdated]：动态更新后的回调。
  /// [isInDetailView]：是否在详情视图中。
  /// [onActivityTap]：动态点击回调。
  /// [hasOwnBackground]：是否拥有自己的背景样式。
  /// [onEdit]：编辑动态回调。
  /// [onDelete]：删除动态回调。
  /// [onLike]：点赞动态回调。
  /// [onUnlike]：取消点赞动态回调。
  /// [onAddComment]：添加评论回调。
  /// [onDeleteComment]：删除评论回调。
  /// [onLikeComment]：评论点赞回调。
  /// [onUnlikeComment]：评论取消点赞回调。
  const ActivityCard({
    super.key,
    required this.activity,
    required this.inputStateService,
    required this.currentUser,
    required this.followService,
    required this.infoProvider,
    this.isAlternate = false,
    this.onUpdated,
    this.isInDetailView = false,
    this.onActivityTap,
    this.hasOwnBackground = true,
    this.onEdit,
    this.onDelete,
    this.onLike,
    this.onUnlike,
    this.onAddComment,
    this.onDeleteComment,
    this.onLikeComment,
    this.onUnlikeComment,
  });

  @override
  _ActivityCardState createState() => _ActivityCardState();
}

/// `_ActivityCardState` 类：`ActivityCard` 的状态管理。
class _ActivityCardState extends State<ActivityCard> {
  late UserActivity _activity; // 动态数据副本
  bool _isAlternate = false; // 是否使用交替布局样式副本
  bool _showComments = false; // 是否显示评论区
  late double _cardHeight; // 卡片高度
  late double _cardWidth; // 卡片宽度
  final TextEditingController _commentController =
      TextEditingController(); // 评论输入框控制器
  bool _isSubmittingComment = false; // 评论是否正在提交

  /// 初始化状态。
  ///
  /// 初始化动态数据、布局样式和卡片属性。
  @override
  void initState() {
    super.initState();
    _activity = widget.activity; // 初始化动态数据
    _isAlternate = widget.isAlternate; // 初始化布局样式
    _initializeCardProperties(); // 初始化卡片属性
  }

  /// 当 Widget 的配置发生变化时调用。
  ///
  /// 更新动态数据和布局样式。
  @override
  void didUpdateWidget(ActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAlternate != oldWidget.isAlternate) {
      setState(() => _isAlternate = widget.isAlternate); // 更新布局样式
    }
    if (widget.activity.id != oldWidget.activity.id ||
        widget.activity.updateTime != oldWidget.activity.updateTime ||
        widget.activity.commentsCount != oldWidget.activity.commentsCount ||
        widget.activity.likesCount != oldWidget.activity.likesCount ||
        widget.activity.isLiked != oldWidget.activity.isLiked) {
      setState(() => _activity = widget.activity); // 更新动态数据
    }
  }

  /// 销毁状态。
  ///
  /// 销毁评论输入框控制器。
  @override
  void dispose() {
    _commentController.dispose(); // 销毁评论输入框控制器
    super.dispose(); // 调用父类销毁方法
  }

  /// 初始化卡片的尺寸属性。
  ///
  /// 根据动态内容长度和是否在详情视图中计算卡片高度和宽度。
  void _initializeCardProperties() {
    final random = math.Random(widget.activity.id.hashCode); // 基于动态 ID 的随机数生成器
    final bool hasContent = _activity.content.isNotEmpty; // 判断动态是否有内容
    double minHeight = 1.0, maxHeight = 1.5; // 最小和最大高度因子
    if (hasContent) {
      minHeight = 1.0;
      maxHeight = 1.8;
    } else if (hasContent) {
      // 这个 else if (hasContent) 是重复的，功能上不会有问题但代码风格上不合理
      minHeight = 0.9;
      maxHeight = 1.5;
    } else {
      minHeight = 1.0;
      maxHeight = 1.4;
    }
    double contentLengthFactor = hasContent
        ? math.min(_activity.content.length / 200, 0.3)
        : 0; // 内容长度对高度的影响因子
    _cardHeight = minHeight +
        random.nextDouble() * (maxHeight - minHeight) +
        contentLengthFactor; // 计算卡片高度
    double widthBase = 0.75, widthVariation = 0.2; // 宽度基数和变化范围
    double contentWidthFactor = hasContent
        ? math.min(_activity.content.length / 300, 0.15)
        : 0; // 内容长度对宽度的影响因子
    _cardWidth = widthBase +
        random.nextDouble() * widthVariation +
        contentWidthFactor; // 计算卡片宽度
    if (widget.isInDetailView) _cardWidth = 0.95; // 详情视图中固定卡片宽度
  }

  /// 处理点赞/取消点赞操作。
  ///
  /// 触发触觉反馈，更新本地点赞状态和计数，并调用父级回调。
  Future<void> _handleLike() async {
    if (widget.onLike == null && widget.onUnlike == null) return; // 回调不存在时直接返回
    HapticFeedback.lightImpact(); // 轻微触觉反馈

    bool? success;
    if (_activity.isLiked) {
      success = await widget.onUnlike?.call(); // 取消点赞时调用取消点赞回调
    } else {
      success = await widget.onLike?.call(); // 点赞时调用点赞回调
    }
    if (success != null && success) {
      setState(() {
        //
      });
    } else {
      setState(() {
        //
      });
    }
  }

  /// 处理评论区显示/隐藏操作。
  ///
  /// 触发触觉反馈，切换评论区显示状态。
  void _handleComment() {
    HapticFeedback.mediumImpact(); // 中等触觉反馈
    setState(() => _showComments = !_showComments); // 切换评论区显示状态
  }

  /// 添加评论。
  ///
  /// [content]：评论内容。
  /// 检查评论内容是否为空或正在提交，调用父级回调，并更新评论计数和显示状态。
  Future<void> _addComment(String content) async {
    if (content.isEmpty || _isSubmittingComment) return; // 内容为空或正在提交时直接返回
    if (widget.onAddComment == null) {
      // 添加评论回调不存在时
      AppSnackBar.showError("操作失败"); // 显示错误提示
      return;
    }

    HapticFeedback.lightImpact(); // 轻微触觉反馈
    setState(() => _isSubmittingComment = true); // 设置为正在提交状态

    final newComment =
        await widget.onAddComment!(_activity.id, content); // 调用父级添加评论回调
    if (newComment != null && mounted) {
      // 评论成功且 Widget 已挂载
      setState(() {
        _showComments = true; // 展开评论区
      });
    } else {
      setState(() => _isSubmittingComment = false); // 设置为正在提交状态
    }
  }

  /// 处理动态卡片点击操作。
  ///
  /// 触发触觉反馈，并调用父级回调。
  void _handleActivityTap() {
    if (widget.isInDetailView || widget.onActivityTap == null) {
      return; // 在详情视图中或点击回调不存在时直接返回
    }
    HapticFeedback.selectionClick(); // 选择触觉反馈
    widget.onActivityTap!(widget.activity); // 调用动态点击回调
  }

  /// 构建 Widget。
  ///
  /// 根据布局样式、内容和评论区显示状态渲染卡片内容。
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 获取屏幕宽度
    final calculatedWidth = screenWidth * _cardWidth; // 计算卡片宽度

    // --- 内容 Widget ---
    Widget contentWidget = Column(
      crossAxisAlignment: _isAlternate
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start, // 根据布局样式设置交叉轴对齐
      children: [
        ActivityHeader(
          userId: _activity.userId,
          infoProvider: widget.infoProvider,
          followService: widget.followService,
          currentUser: widget.currentUser,
          createTime: _activity.createTime,
          updateTime: _activity.updateTime,
          isEdited: _activity.isEdited,
          activityType: _activity.type,
          isAlternate: _isAlternate,
          cardHeight: _cardHeight,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        ),
        SizedBox(height: 12 * _cardHeight), // 间距
        if (_activity.content.isNotEmpty) // 动态内容不为空时显示
          Container(
            width: double.infinity,
            alignment: _isAlternate
                ? Alignment.centerRight
                : Alignment.centerLeft, // 根据布局样式设置对齐
            child: Text(_activity.content, // 动态内容文本
                style: TextStyle(
                    fontSize: 14 * math.sqrt(_cardHeight * 0.7)), // 文本样式
                textAlign:
                    _isAlternate ? TextAlign.right : TextAlign.left), // 文本对齐
          ),
        ...[
          SizedBox(height: 12 * _cardHeight), // 间距
          ActivityTarget(
              currentUser: widget.currentUser,
              infoProvider: widget.infoProvider,
              followService: widget.followService,
              activity: _activity,
              isAlternate: _isAlternate,
              cardHeight: _cardHeight),
        ],
        ActivityTargetNavigation(
            activity: _activity, isAlternate: _isAlternate), // 动态目标导航
        SizedBox(height: 16 * _cardHeight), // 间距
        ActivityActionButtons(
          isLiked: _activity.isLiked,
          likesCount: _activity.likesCount,
          commentsCount: _activity.commentsCount,
          isAlternate: _isAlternate,
          cardHeight: _cardHeight,
          onLike: _handleLike, // 点赞回调
          onComment: _handleComment, // 评论回调
        ),
        if (_showComments || _activity.comments.isNotEmpty) ...[
          // 显示评论区
          const Divider(
              height: 24, indent: 16, endIndent: 16, thickness: 0.5), // 分割线
          _buildComments(), // 构建评论区内容
        ]
      ],
    );

    // --- 卡片包装 ---
    if (!widget.hasOwnBackground) {
      // 没有自己的背景时，通常在详情页使用
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0), // 垂直内边距
        child: contentWidget, // 直接返回内容 Widget
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // 动画时长
      margin: const EdgeInsets.symmetric(vertical: 8), // 垂直外边距
      alignment: _isAlternate
          ? Alignment.centerRight
          : Alignment.centerLeft, // 根据布局样式设置对齐
      padding: EdgeInsets.symmetric(
          horizontal: 16, vertical: 4 * _cardHeight), // 内边距
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // 鼠标悬停时显示点击光标
        child: GestureDetector(
          onTap: _handleActivityTap, // 点击回调
          child: Container(
            width: calculatedWidth, // 卡片宽度
            constraints: BoxConstraints(
                maxWidth: screenWidth * 0.95,
                minWidth: screenWidth * 0.6), // 宽度约束
            child: Card(
              elevation: 1, // 阴影
              margin: EdgeInsets.zero, // 无外边距
              shape: RoundedRectangleBorder(
                  // 圆角边框
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(_isAlternate ? 20 : 4),
                      topRight: Radius.circular(_isAlternate ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20))),
              child: Container(
                padding: EdgeInsets.all(16 * math.sqrt(_cardHeight)), // 内边距
                decoration: BoxDecoration(
                    // 装饰
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_isAlternate ? 20 : 4),
                        topRight: Radius.circular(_isAlternate ? 4 : 20),
                        bottomLeft: const Radius.circular(20),
                        bottomRight: const Radius.circular(20)),
                    color: Colors.white), // 背景颜色
                child: contentWidget, // 内容 Widget
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建评论区内容。
  ///
  /// 包含评论列表、查看更多按钮和评论输入框。
  Widget _buildComments() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0), // 顶部内边距
      child: Column(
        crossAxisAlignment: _isAlternate
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start, // 根据布局样式设置交叉轴对齐
        children: [
          // --- 显示评论列表 ---
          if (_activity.comments.isNotEmpty) // 评论列表不为空时显示
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(), // 禁用滚动
              shrinkWrap: true, // 最小化列表尺寸
              itemCount:
                  _activity.comments.length > 3 && !_showComments // 控制显示评论数量
                      ? 3
                      : _activity.comments.length,
              itemBuilder: (context, index) {
                final comment = _activity.comments[index]; // 获取评论数据
                return ActivityCommentItem(
                  key: ValueKey(comment.id), // Key
                  comment: comment, // 评论数据
                  userFollowService: widget.followService, // 用户关注服务
                  userInfoProvider: widget.infoProvider, // 用户信息 Provider
                  currentUser: widget.currentUser, // 当前用户
                  activityId: _activity.id, // 动态 ID
                  isAlternate: _isAlternate, // 布局样式
                  onLike: widget.onLikeComment != null // 评论点赞回调
                      ? () {
                          return widget.onLikeComment!(
                              _activity.id, comment.id);
                        }
                      : null,
                  onUnlike: widget.onUnlikeComment != null // 评论取消点赞回调
                      ? () => widget.onUnlikeComment!(_activity.id, comment.id)
                      : null,
                  onCommentDeleted: widget.onDeleteComment != null // 评论删除回调
                      ? () => widget.onDeleteComment!(_activity.id, comment)
                      : null,
                );
              },
            ),

          // --- 查看更多按钮 ---
          if (_activity.comments.length > 3 &&
              !_showComments) // 评论数量超过 3 且未展开时显示
            Padding(
              padding: const EdgeInsets.only(top: 8.0), // 顶部内边距
              child: TextButton(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, // 无内边距
                    minimumSize: Size(50, 30), // 最小尺寸
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap), // 触摸目标尺寸
                onPressed: () =>
                    setState(() => _showComments = true), // 点击时展开评论区
                child: Text('查看全部 ${_activity.commentsCount} 条评论...', // 文本
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).primaryColor)), // 文本样式
              ),
            ),

          // --- 评论输入框 ---
          if (_showComments) // 评论区展开时显示评论输入框
            Padding(
              padding: const EdgeInsets.only(top: 12.0), // 顶部内边距
              child: ActivityCommentInput(
                inputStateService: widget.inputStateService, // 输入状态服务
                currentUser: widget.currentUser, // 当前用户
                onSubmit: _addComment, // 提交评论回调
                isSubmitting: _isSubmittingComment, // 是否正在提交
                isAlternate: _isAlternate, // 布局样式
              ),
            ),

          // --- 如果没有评论但展开了评论区 ---
          if (_activity.comments.isEmpty && _showComments) // 没有评论且评论区展开时显示提示
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0), // 垂直内边距
              child: Text('暂无评论，快来抢沙发吧~', // 提示文本
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600)), // 文本样式
            ),
        ],
      ),
    );
  }
}
