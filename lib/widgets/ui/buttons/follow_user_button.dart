// lib/widgets/ui/buttons/follow_user_button.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class FollowUserButton extends StatefulWidget {
  final String targetUserId;
  final User? currentUser;
  final Color? color;
  final bool showIcon;
  final bool mini;
  final VoidCallback? onFollowChanged;
  final bool? initialIsFollowing;

  const FollowUserButton({
    super.key,
    required this.targetUserId,
    required this.currentUser,
    this.color,
    this.showIcon = true,
    this.mini = false,
    this.onFollowChanged,
    this.initialIsFollowing,
  });

  @override
  _FollowUserButtonState createState() => _FollowUserButtonState();
}

class _FollowUserButtonState extends State<FollowUserButton>
    with SnackBarNotifierMixin {
  late bool _isFollowing;
  late bool _isLoading; // 只在 API 调用期间为 true
  bool _internalStateInitialized = false; // 标记内部状态是否已初始化

  StreamSubscription? _followStatusSubscription; // 保留流监听，用于外部触发刷新
  bool _mounted = true;

  User? _currentUser;
  String? _targatUserId;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _isFollowing =
        widget.initialIsFollowing ?? false; // 如果父组件没传（理论上不该发生），默认 false
    _isLoading = false; // 初始时不加载
    _internalStateInitialized = true; // 标记内部状态已根据父组件初始化
    _currentUser = widget.currentUser;
    _targatUserId = widget.targetUserId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// ** 作用域开始 **
    UserFollowService? followService = context.read<UserFollowService>();
    _followStatusSubscription =
        followService.followStatusStream.listen((changedUserId) {});
    followService = null;

    /// 使用完立即消除引用
    /// 保持语义清晰
    /// ** 作用域结束 **
  }

  @override
  void didUpdateWidget(FollowUserButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // --- 当父组件传递的状态更新时，同步内部状态 ---
    // 只有当父组件传递的状态确实变化了，才更新
    if (widget.initialIsFollowing != null &&
        widget.initialIsFollowing != _isFollowing) {
      // 只有在内部状态已经初始化后，才接受来自父组件的更新
      // 避免覆盖用户刚刚点击操作后的乐观 UI 状态
      // （或者，如果需要严格同步父状态，可以去掉 _internalStateInitialized 判断）
      if (_internalStateInitialized && _mounted) {
        setState(() {
          _isFollowing = widget.initialIsFollowing!;
          // 如果此时正在加载（不太可能，但作为保险），取消加载
          if (_isLoading) _isLoading = false;
        });
      }
    }
    if (widget.currentUser != oldWidget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
    if (widget.targetUserId != oldWidget.targetUserId ||
        _targatUserId != widget.targetUserId) {
      setState(() {
        _targatUserId = widget.targetUserId;
      });
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _followStatusSubscription?.cancel();
    super.dispose();
  }

  /// 处理关注/取消关注按钮的点击事件
  Future<void> _handleFollowTap() async {
    if (!_mounted) return;

    if (widget.currentUser == null) {
      showSnackbar(message: '请先登录', type: SnackbarType.info);
      return;
    }
    if (_isLoading) return; // 防止重复点击

    // 暂存旧状态，用于失败时回滚
    final bool oldState = _isFollowing;
    setState(() {
      _isFollowing = !_isFollowing; // 先改状态
      _isLoading = true; // 显示加载
    });

    bool success = false;

    try {
      /// ** 作用域开始 **
      UserFollowService? followService = context.read<UserFollowService>();
      if (!oldState) {
        // 如果之前是 false (未关注)，现在是 true (已关注)
        success = await followService.followUser(widget.targetUserId);
      } else {
        // 如果之前是 true (已关注)，现在是 false (未关注)
        success = await followService.unfollowUser(widget.targetUserId);
      }
      followService = null;

      /// 使用完立即消除引用
      /// 保持语义清晰
      /// ** 作用域结束 **

      if (!_mounted) return;

      if (success) {
        setState(() {
          _isLoading = false; // API 成功，结束加载
        });
        widget.onFollowChanged?.call(); // 调用回调
      } else {
        // API 失败，回滚状态
        setState(() {
          _isFollowing = oldState; // 恢复旧状态
          _isLoading = false;
        });
        showSnackbar(
            message: oldState ? '取消关注失败' : '关注失败', type: SnackbarType.error);
      }
    } catch (e) {
      if (_mounted) {
        // 异常，回滚状态
        setState(() {
          _isFollowing = oldState; // 恢复旧状态
          _isLoading = false;
        });
        showSnackbar(
            message: '操作失败: ${e.toString()}', type: SnackbarType.error);
      }
    }
  }

  Widget _buildMini(Color themeColor) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: _handleFollowTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          side: BorderSide(color: _isFollowing ? Colors.grey : themeColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isLoading
            ? SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _isFollowing ? Colors.grey : themeColor),
                ),
              )
            : Text(
                _isFollowing ? '已关注' : '关注',
                style: TextStyle(
                    fontSize: 8,
                    color: _isFollowing ? Colors.grey : themeColor),
              ),
      ),
    );
  }

  Widget _buildIsFollowing(Color themeColor) {
    return OutlinedButton.icon(
      onPressed: _handleFollowTap,
      icon: _isLoading
          ? SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)))
          : widget.showIcon
              ? Icon(Icons.check, size: 12, color: Colors.grey)
              : SizedBox.shrink(),
      label: Text('已关注', style: TextStyle(color: Colors.grey)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildCanFollow(Color themeColor) {
    return ElevatedButton.icon(
      onPressed: _handleFollowTap,
      icon: _isLoading
          ? SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
          : widget.showIcon
              ? Icon(Icons.add, size: 12)
              : SizedBox.shrink(),
      label: Text('关注'),
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);
    final Color themeColor = widget.color ?? Theme.of(context).primaryColor;

    if (widget.mini) return _buildMini(themeColor);

    return _isFollowing
        ? _buildIsFollowing(themeColor)
        : _buildCanFollow(themeColor);
  }
}
