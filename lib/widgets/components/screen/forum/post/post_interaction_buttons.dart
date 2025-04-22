import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../../models/post/post.dart';
import '../../../../../services/main/forum/forum_service.dart';
import '../../../../../providers/auth/auth_provider.dart';
import 'package:provider/provider.dart';

class PostInteractionButtons extends StatefulWidget {
  final Post post;
  final Function(Post) onPostUpdated;
  // 添加一个回调函数，用于通知父组件交互成功，需要刷新
  final VoidCallback? onInteractionSuccess;

  const PostInteractionButtons({
    super.key,
    required this.post,
    required this.onPostUpdated,
    this.onInteractionSuccess,
  });

  @override
  _PostInteractionButtonsState createState() => _PostInteractionButtonsState();
}

class _PostInteractionButtonsState extends State<PostInteractionButtons> {
  final ForumService _forumService = ForumService();
  bool _isLoading = false;

  // 本地状态，用于即时更新UI
  late bool _isLiked;
  late bool _isAgreed;
  late bool _isFavorited;
  late int _likeCount;
  late int _agreeCount;
  late int _favoriteCount;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void didUpdateWidget(PostInteractionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.isAgreed != widget.post.isAgreed ||
        oldWidget.post.isFavorited != widget.post.isFavorited) {
      _initializeState();
    }
  }

  void _initializeState() {
    _isLiked = widget.post.isLiked;
    _isAgreed = widget.post.isAgreed;
    _isFavorited = widget.post.isFavorited;
    _likeCount = widget.post.likeCount;
    _agreeCount = widget.post.agreeCount;
    _favoriteCount = widget.post.favoriteCount;
  }

  Future<void> _toggleLike() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginDialog();
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newStatus = await _forumService.togglePostLike(widget.post.id);

      setState(() {
        // 更新本地状态
        _isLiked = newStatus;
        _likeCount += newStatus ? 1 : -1;

        // 更新父组件的Post对象
        final updatedPost = widget.post.copyWith(
          isLiked: _isLiked,
          likeCount: _likeCount,
        );

        widget.onPostUpdated(updatedPost);
      });

      // 调用交互成功回调
      if (widget.onInteractionSuccess != null) {
        widget.onInteractionSuccess!();
      }
    } catch (e) {
      AppSnackBar.showError(context, '操作失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAgree() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginDialog();
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newStatus = await _forumService.togglePostAgree(widget.post.id);

      setState(() {
        // 更新本地状态
        _isAgreed = newStatus;
        _agreeCount += newStatus ? 1 : -1;

        // 更新父组件的Post对象
        final updatedPost = widget.post.copyWith(
          isAgreed: _isAgreed,
          agreeCount: _agreeCount,
        );

        widget.onPostUpdated(updatedPost);
      });

      // 调用交互成功回调
      if (widget.onInteractionSuccess != null) {
        widget.onInteractionSuccess!();
      }
    } catch (e) {
      AppSnackBar.showError(context, '操作失败: $e');

    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _showLoginDialog();
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newStatus = await _forumService.togglePostFavorite(widget.post.id);

      setState(() {
        // 更新本地状态
        _isFavorited = newStatus;
        _favoriteCount += newStatus ? 1 : -1;

        // 更新父组件的Post对象
        final updatedPost = widget.post.copyWith(
          isFavorited: _isFavorited,
          favoriteCount: _favoriteCount,
        );

        widget.onPostUpdated(updatedPost);
      });

      // 调用交互成功回调
      if (widget.onInteractionSuccess != null) {
        widget.onInteractionSuccess!();
      }
    } catch (e) {
      AppSnackBar.showError(context,'操作失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLoginDialog() {
    NavigationUtils.showLoginDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    // 根据屏幕大小调整UI样式
    final double iconSize = isDesktop ? 20.0 : 18.0;
    final double fontSize = isDesktop ? 14.0 : 12.0;
    final EdgeInsets padding = isDesktop
        ? EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 点赞按钮
        _buildInteractionButton(
          icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
          label: '$_likeCount',
          color: _isLiked ? Theme.of(context).primaryColor : Colors.grey,
          onTap: _toggleLike,
          iconSize: iconSize,
          fontSize: fontSize,
          padding: padding,
        ),

        // 赞成按钮
        _buildInteractionButton(
          icon: _isAgreed ? Icons.check_circle : Icons.check_circle_outline,
          label: '$_agreeCount',
          color: _isAgreed ? Colors.green : Colors.grey,
          onTap: _toggleAgree,
          iconSize: iconSize,
          fontSize: fontSize,
          padding: padding,
        ),

        // 收藏按钮
        _buildInteractionButton(
          icon: _isFavorited ? Icons.star : Icons.star_border,
          label: '$_favoriteCount',
          color: _isFavorited ? Colors.amber : Colors.grey,
          onTap: _toggleFavorite,
          iconSize: iconSize,
          fontSize: fontSize,
          padding: padding,
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
    required EdgeInsets padding,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Icon(icon, size: iconSize, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
