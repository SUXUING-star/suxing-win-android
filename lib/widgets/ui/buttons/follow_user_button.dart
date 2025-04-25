// lib/widgets/ui/buttons/follow_user_button.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../services/main/user/user_follow_service.dart';
import '../../../providers/auth/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class FollowUserButton extends StatefulWidget {
  final String userId;
  final Color? color;
  final bool showIcon;
  final bool mini;
  final VoidCallback? onFollowChanged;
  // 接收来自父组件的初始关注状态。
  // - 如果是 bool 值，直接使用。
  // - 如果是 null，表示父组件可能正在获取，按钮会等待一小段时间。
  final bool? initialIsFollowing;

  const FollowUserButton({
    super.key,
    required this.userId,
    this.color,
    this.showIcon = true,
    this.mini = false,
    this.onFollowChanged,
    this.initialIsFollowing,
  });

  @override
  _FollowUserButtonState createState() => _FollowUserButtonState();
}

class _FollowUserButtonState extends State<FollowUserButton> {
  final UserFollowService _followService = UserFollowService();
  late bool _isFollowing;
  bool _isLoading = false; // 只在 API 调用期间为 true
  bool _internalStateInitialized = false; // 标记内部状态是否已初始化

  StreamSubscription? _followStatusSubscription; // 保留流监听，用于外部触发刷新
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    // --- 简化初始化 ---
    // 直接使用父组件传递的状态
    _isFollowing =
        widget.initialIsFollowing ?? false; // 如果父组件没传（理论上不该发生），默认 false
    _isLoading = false; // 初始时不加载
    _internalStateInitialized = true; // 标记内部状态已根据父组件初始化
    print(
        'FollowUserButton (${widget.userId}): initState - Initial state from parent: $_isFollowing');

    // --- 仍然监听全局流，但触发时不自己调用API，而是通知父组件刷新（如果需要） ---
    // 或者更简单：依赖父组件的 AuthProvider 刷新机制
    _followStatusSubscription =
        _followService.followStatusStream.listen((changedUserId) {
      if (changedUserId == widget.userId && _mounted) {
        // 当接收到流事件时，可以认为状态可能已过期，但这里我们信任父组件的刷新
        // 可以选择性地强制父组件刷新，但 AuthProvider.refreshUserState 应该已经处理了
        print(
            'FollowUserButton (${widget.userId}): Received stream update. Relying on parent refresh.');
        // 如果需要强制刷新，可以调用 widget.onFollowChanged?.call() 并让父组件处理
      }
    });
  }

  @override
  void didUpdateWidget(FollowUserButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // --- 当父组件传递的状态更新时，同步内部状态 ---
    // 只有当父组件传递的状态确实变化了，才更新
    if (widget.initialIsFollowing != null &&
        widget.initialIsFollowing != _isFollowing) {
      print(
          'FollowUserButton (${widget.userId}): didUpdateWidget - State updated from parent: ${widget.initialIsFollowing}');
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
  }

  @override
  void dispose() {
    _mounted = false;
    _followStatusSubscription?.cancel();
    super.dispose();
  }

  // --- _checkFollowStatus 方法可以删除了 ---
  // Future<void> _checkFollowStatus(...) async { ... } // 删除这个方法

  /// 处理关注/取消关注按钮的点击事件 (基本不变，但调用 authProvider.refreshUserState)
  Future<void> _handleFollowTap() async {
    if (!_mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      AppSnackBar.showInfo(context, '请先登录');
      return;
    }
    if (_isLoading) return; // 防止重复点击

    // **乐观更新 UI**
    // 暂存旧状态，用于失败时回滚
    final bool oldState = _isFollowing;
    setState(() {
      _isFollowing = !_isFollowing; // 先改状态
      _isLoading = true; // 显示加载
    });

    bool success = false;
    try {
      if (!oldState) {
        // 如果之前是 false (未关注)，现在是 true (已关注)
        success = await _followService.followUser(widget.userId);
      } else {
        // 如果之前是 true (已关注)，现在是 false (未关注)
        success = await _followService.unfollowUser(widget.userId);
      }

      if (!_mounted) return;

      if (success) {
        setState(() {
          _isLoading = false; // API 成功，结束加载
        });
        // **通知 AuthProvider 刷新当前用户状态**
        authProvider.refreshUserState();
        widget.onFollowChanged?.call(); // 调用回调
      } else {
        // API 失败，回滚状态
        setState(() {
          _isFollowing = oldState; // 恢复旧状态
          _isLoading = false;
        });
        AppSnackBar.showError(context, oldState ? '取消关注失败' : '关注失败');
      }
    } catch (e) {
      if (_mounted) {
        // 异常，回滚状态
        setState(() {
          _isFollowing = oldState; // 恢复旧状态
          _isLoading = false;
        });
        AppSnackBar.showError(context, '操作失败: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- UI 构建逻辑基本不变，依赖 _isFollowing 和 _isLoading ---
    final themeColor = widget.color ?? Theme.of(context).primaryColor;

    if (widget.mini) {
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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _isFollowing ? Colors.grey : themeColor),
                  ),
                )
              : Text(
                  _isFollowing ? '已关注' : '关注',
                  style: TextStyle(
                      fontSize: 12,
                      color: _isFollowing ? Colors.grey : themeColor),
                ),
        ),
      );
    }

    // 标准样式
    if (_isFollowing) {
      return OutlinedButton.icon(
        onPressed: _handleFollowTap,
        icon: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)))
            : widget.showIcon
                ? Icon(Icons.check, size: 16, color: Colors.grey)
                : SizedBox.shrink(),
        label: Text('已关注', style: TextStyle(color: Colors.grey)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: _handleFollowTap,
        icon: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : widget.showIcon
                ? Icon(Icons.add, size: 16)
                : SizedBox.shrink(),
        label: Text('关注'),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }
  }
}
