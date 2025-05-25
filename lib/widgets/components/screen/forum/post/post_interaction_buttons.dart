// === 文件: lib/widgets/components/screen/forum/post/post_interaction_buttons.dart ===
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/post/user_post_actions.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

class PostInteractionButtons extends StatefulWidget {
  final Post post;
  final PostService forumService;
  final User? currentUser;
  final UserPostActions userActions;
  final Function(Post, UserPostActions) onPostUpdated;

  const PostInteractionButtons({
    super.key,
    required this.post,
    required this.currentUser,
    required this.forumService,
    required this.userActions,
    required this.onPostUpdated,
  });

  @override
  _PostInteractionButtonsState createState() => _PostInteractionButtonsState();
}

class _PostInteractionButtonsState extends State<PostInteractionButtons> {
  // *** 只维护按钮的加载状态 ***
  bool _isLiking = false;
  bool _isAgreeing = false;
  bool _isFavoriting = false;

  late int _likeCount;
  late int _agreeCount;
  late int _favoriteCount;

  bool _hasInitializedDependencies = false;
  late final PostService _forumService;
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    // 初始化计数从传入的 post 获取
    _likeCount = widget.post.likeCount;
    _agreeCount = widget.post.agreeCount;
    _favoriteCount = widget.post.favoriteCount;
    _currentUser = widget.currentUser;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _forumService = widget.forumService;
      _hasInitializedDependencies = true;
    }
  }

  @override
  void didUpdateWidget(PostInteractionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果外部传入的 post 计数变化了，同步本地的乐观计数
    // 交互状态直接使用新的 widget.userActions
    bool countsChanged = oldWidget.post.likeCount != widget.post.likeCount ||
        oldWidget.post.agreeCount != widget.post.agreeCount ||
        oldWidget.post.favoriteCount != widget.post.favoriteCount;
    if (countsChanged) {
      if (mounted) {
        // 确保组件挂载
        setState(() {
          _likeCount = widget.post.likeCount;
          _agreeCount = widget.post.agreeCount;
          _favoriteCount = widget.post.favoriteCount;
        });
      }
    }
    if (widget.currentUser != oldWidget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  // --- 通用的交互处理函数 ---
  Future<void> _handleInteraction({
    required Future<bool> Function() apiCall,
    required bool Function() getLoadingState,
    required Function(bool isLoading) setLoadingState,
    required String actionName, // 'like', 'agree', 'favorite'
  }) async {
    final currentUserId = widget.currentUser?.id;
    if (currentUserId == null) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    if (getLoadingState()) return;

    // --- 获取当前状态（从 widget.userActions）和计数（从本地状态）用于计算 ---
    final String postId = widget.post.id;
    final bool currentLiked = widget.userActions.liked;
    final bool currentAgreed = widget.userActions.agreed;
    final bool currentFavorited = widget.userActions.favorited;
    // 原始计数用于回滚和计算新 Post
    final int originalLikeCount = widget.post.likeCount;
    final int originalAgreeCount = widget.post.agreeCount;
    final int originalFavoriteCount = widget.post.favoriteCount;

    // --- 计算乐观更新的计数变化 ---
    bool optimisticNewStatus;
    int optimisticCountChange;
    switch (actionName) {
      case 'like':
        optimisticNewStatus = !currentLiked;
        optimisticCountChange = optimisticNewStatus ? 1 : -1;
        break;
      case 'agree':
        optimisticNewStatus = !currentAgreed;
        optimisticCountChange = optimisticNewStatus ? 1 : -1;
        break;
      case 'favorite':
        optimisticNewStatus = !currentFavorited;
        optimisticCountChange = optimisticNewStatus ? 1 : -1;
        break;
      default:
        return;
    }

    // --- 乐观更新 UI 计数并显示加载 ---
    setState(() {
      setLoadingState(true);
      // *** 只更新本地的计数用于即时显示 ***
      switch (actionName) {
        case 'like':
          _likeCount += optimisticCountChange;
          break;
        case 'agree':
          _agreeCount += optimisticCountChange;
          break;
        case 'favorite':
          _favoriteCount += optimisticCountChange;
          break;
      }
    });

    try {
      // --- 调用 API 获取确认的状态 ---
      final bool actualNewStatus = await apiCall();

      if (mounted) {
        // --- 计算最终正确的计数 ---
        int finalCountChange = actualNewStatus ? 1 : -1;
        int finalLikeCount =
            originalLikeCount + (actionName == 'like' ? finalCountChange : 0);
        int finalAgreeCount =
            originalAgreeCount + (actionName == 'agree' ? finalCountChange : 0);
        int finalFavoriteCount = originalFavoriteCount +
            (actionName == 'favorite' ? finalCountChange : 0);

        // --- 构建新的 Post (只更新计数) ---
        final newPost = widget.post.copyWith(
          likeCount: finalLikeCount,
          agreeCount: finalAgreeCount,
          favoriteCount: finalFavoriteCount,
        );

        // --- 构建新的 UserPostActions (包含确认的状态) ---
        final newActions = UserPostActions(
          postId: postId, userId: currentUserId,
          // 使用 API 返回的状态更新对应项，其他项保持 widget 传入的值
          liked: (actionName == 'like')
              ? actualNewStatus
              : widget.userActions.liked,
          agreed: (actionName == 'agree')
              ? actualNewStatus
              : widget.userActions.agreed,
          favorited: (actionName == 'favorite')
              ? actualNewStatus
              : widget.userActions.favorited,
        );

        // --- 调用 Service 写入缓存 ---
        await widget.forumService.cacheNewPostData(newPost, newActions);

        // --- 更新本地 UI 计数为最终确认的值 ---
        // （如果 API 返回的状态与乐观更新不符，这里会修正计数的显示）
        setState(() {
          _likeCount = newPost.likeCount;
          _agreeCount = newPost.agreeCount;
          _favoriteCount = newPost.favoriteCount;
        });

        // --- 通知父组件 Post 数据已更新 ---
        widget.onPostUpdated(newPost, newActions);
      }
    } catch (e) {
      // --- API 失败，回滚 UI 计数 ---
      if (mounted) {
        AppSnackBar.showError(
            context, '操作失败: ${e.toString().replaceFirst("Exception: ", "")}');
        // *** 只回滚本地计数 ***
        setState(() {
          _likeCount = originalLikeCount;
          _agreeCount = originalAgreeCount;
          _favoriteCount = originalFavoriteCount;
        });
        // *** 不需要回滚 _isLiked 等，因为它们由 widget.userActions 控制 ***
      }
    } finally {
      // --- 结束加载状态 ---
      if (mounted) {
        setState(() {
          setLoadingState(false);
        });
      }
    }
  }

  // 各个按钮的 onTap 调用 _handleInteraction 的方式不变
  Future<void> _toggleLike() async {
    await _handleInteraction(
      apiCall: () => _forumService.togglePostLike(widget.post.id),
      getLoadingState: () => _isLiking,
      setLoadingState: (isLoading) => _isLiking = isLoading,
      actionName: 'like',
    );
  }

  Future<void> _toggleAgree() async {
    await _handleInteraction(
      apiCall: () => _forumService.togglePostAgree(widget.post.id),
      getLoadingState: () => _isAgreeing,
      setLoadingState: (isLoading) => _isAgreeing = isLoading,
      actionName: 'agree',
    );
  }

  Future<void> _toggleFavorite() async {
    await _handleInteraction(
      apiCall: () => _forumService.togglePostFavorite(widget.post.id),
      getLoadingState: () => _isFavoriting,
      setLoadingState: (isLoading) => _isFavoriting = isLoading,
      actionName: 'favorite',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;
    final double iconSize = isDesktop ? 20.0 : 18.0;
    final double fontSize = isDesktop ? 14.0 : 12.0;
    final EdgeInsets padding = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    // *** 使用 widget.userActions 来决定按钮的图标和颜色 ***
    final bool liked = widget.userActions.liked;
    final bool agreed = widget.userActions.agreed;
    final bool favorited = widget.userActions.favorited;

    // *** 使用本地状态 _likeCount 等来显示计数值 ***
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInteractionButton(
          // *** 根据 widget.userActions.liked 显示图标和颜色 ***
          icon: liked ? Icons.thumb_up : Icons.thumb_up_outlined,
          label: '$_likeCount', // 显示本地乐观计数
          color: liked ? Theme.of(context).primaryColor : Colors.grey,
          onTap: () => _toggleLike(),
          iconSize: iconSize, fontSize: fontSize, padding: padding,
          isLoading: _isLiking, // 使用加载状态
        ),
        _buildInteractionButton(
          // *** 根据 widget.userActions.agreed 显示图标和颜色 ***
          icon: liked ? Icons.check_circle : Icons.check_circle_outline,
          label: '$_agreeCount', // 显示本地乐观计数
          color: agreed ? Colors.green : Colors.grey,
          onTap: () => _toggleAgree(),
          iconSize: iconSize, fontSize: fontSize, padding: padding,
          isLoading: _isAgreeing, // 使用加载状态
        ),
        _buildInteractionButton(
          // *** 根据 widget.userActions.favorited 显示图标和颜色 ***
          icon: favorited ? Icons.star : Icons.star_border,
          label: '$_favoriteCount', // 显示本地乐观计数
          color: favorited ? Colors.amber : Colors.grey,
          onTap: () => _toggleFavorite(),
          iconSize: iconSize, fontSize: fontSize, padding: padding,
          isLoading: _isFavoriting, // 使用加载状态
        ),
      ],
    );
  }

  // 构建单个交互按钮的 Widget (完整, 无变化)
  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
    required EdgeInsets padding,
    required bool isLoading,
  }) {
    return IgnorePointer(
      ignoring: isLoading,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, size: iconSize, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: isLoading ? Colors.grey : color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} // End of _PostInteractionButtonsState
