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
    Key? key,
    required this.userId,
    this.color,
    this.showIcon = true,
    this.mini = false,
    this.onFollowChanged,
    this.initialIsFollowing,
  }) : super(key: key);

  @override
  _FollowUserButtonState createState() => _FollowUserButtonState();
}

class _FollowUserButtonState extends State<FollowUserButton> {
  final UserFollowService _followService = UserFollowService();
  late bool _isFollowing;
  bool _isLoading = false; // 是否正在进行网络请求或等待初始状态

  // --- 新增：用于等待父组件状态更新的后备 Timer ---
  Timer? _fallbackTimer;
  static const Duration _fallbackDelay = Duration(seconds: 1, milliseconds: 500); // 等待父组件状态的最大时间 (例如 1.5 秒)
  // ---------------------------------------------

  // 跟踪上次状态检查时间 - 减少频繁API调用 (这个仍然有用，用于非初始检查)
  DateTime? _lastStatusCheckTime;
  static const Duration _minStatusCheckInterval = Duration(minutes: 10);

  StreamSubscription? _followStatusSubscription;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _mounted = true;

    // --- 初始化状态逻辑修改 ---
    if (widget.initialIsFollowing != null) {
      // 1. 父组件提供了明确的初始状态 (true 或 false)
      _isFollowing = widget.initialIsFollowing!;
      _isLoading = false; // 状态已知，不加载
      print('FollowUserButton (${widget.userId}): 使用父组件提供的初始状态: $_isFollowing');
    } else {
      // 2. 父组件未提供初始状态 (传入的是 null)
      //    这通常意味着父组件正在异步获取数据 (比如通过 batch-info)
      _isFollowing = false; // 默认未关注
      _isLoading = true; // 进入加载/等待状态
      print('FollowUserButton (${widget.userId}): 未收到初始状态，进入等待模式...');

      // --- 启动后备 Timer ---
      // 如果在 _fallbackDelay 时间内，父组件没有通过 didUpdateWidget 提供状态，
      // 那么这个 Timer 会触发 _checkFollowStatus 进行自主检查。
      _fallbackTimer = Timer(_fallbackDelay, () {
        // Timer 触发时，再次检查 _mounted 状态
        if (_mounted && _isLoading) { // 只有在仍在加载/等待状态时才执行
          print('FollowUserButton (${widget.userId}): 等待超时，启动后备 API 检查...');
          _checkFollowStatus(initialCheck: true); // 标记为初始(后备)检查
        }
      });
      // -----------------------
    }
    // --------------------------

    // 监听全局关注状态流 (保持不变)
    _followStatusSubscription = _followService.followStatusStream.listen((changedUserId) {
      if (changedUserId == widget.userId && _mounted) {
        print('FollowUserButton (${widget.userId}): 收到状态流更新，强制检查状态');
        _checkFollowStatus(forceCheck: true); // 强制检查最新状态
      }
    });
  }

  @override
  void didUpdateWidget(FollowUserButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // --- 监听父组件传递的 initialIsFollowing 是否从 null 变为 非null ---
    // 这表示父组件的异步请求完成了，并把包含关注状态的数据传递过来了
    if (oldWidget.initialIsFollowing == null && widget.initialIsFollowing != null) {
      // 只有在当前仍然处于加载/等待状态时才处理 (避免覆盖用户操作后的状态)
      if (_isLoading && _mounted) {
        print('FollowUserButton (${widget.userId}): 父组件更新了状态: ${widget.initialIsFollowing}');

        // --- 取消后备 Timer ---
        // 因为父组件已经成功提供了状态，不再需要后备检查
        _fallbackTimer?.cancel();
        _fallbackTimer = null;
        // -------------------

        // 更新按钮状态，并结束加载
        setState(() {
          _isFollowing = widget.initialIsFollowing!;
          _isLoading = false;
        });
      }
    }
    // ---------------------------------------------------------------
  }


  @override
  void dispose() {
    _mounted = false;
    _followStatusSubscription?.cancel();
    _fallbackTimer?.cancel(); // 确保 Timer 被取消
    _fallbackTimer = null;
    super.dispose();
  }

  /// 检查当前用户是否关注了目标用户 [widget.userId]
  /// 这个方法现在主要由后备 Timer、状态流更新或用户强制刷新触发
  Future<void> _checkFollowStatus({
    bool forceCheck = false,
    bool initialCheck = false, // 标记是否由 initState/fallbackTimer 触发
  }) async {
    if (!_mounted) return;

    // 节流控制 (对于非强制检查)
    final now = DateTime.now();
    if (!forceCheck && _lastStatusCheckTime != null) {
      final timeSinceLastCheck = now.difference(_lastStatusCheckTime!);
      if (timeSinceLastCheck < _minStatusCheckInterval) {
        print('FollowUserButton (${widget.userId}): 关注状态检查被节流');
        // 如果是初始检查被节流，且仍在加载，需要取消加载状态
        if (initialCheck && _isLoading && mounted) {
          setState(() { _isLoading = false; });
        }
        return;
      }
    }

    // 如果不是初始检查（即由流更新或刷新触发），且当前不在加载状态，
    // 可以考虑短暂显示加载指示器，提升用户体验
    // if (!initialCheck && !_isLoading && mounted) {
    //   setState(() { _isLoading = true; });
    // }

    try {
      print('FollowUserButton (${widget.userId}): 正在调用 API 检查关注状态 (可能为后备检查)...');
      final isFollowingResult = await _followService.isFollowing(widget.userId);
      _lastStatusCheckTime = now;

      if (!_mounted) return;

      print('FollowUserButton (${widget.userId}): API 检查结果: $isFollowingResult');
      // 只有当状态变化 或 之前在加载状态时 才更新UI
      if (_isFollowing != isFollowingResult || _isLoading) {
        setState(() {
          _isFollowing = isFollowingResult;
          _isLoading = false; // 检查完成，结束加载
        });
      }
    } catch (e) {
      print('FollowUserButton (${widget.userId}): 检查关注状态失败: $e');
      if (_mounted && _isLoading) { // 如果检查失败时仍在加载状态
        setState(() {
          _isLoading = false; // 结束加载
        });
      }
    }
  }

  /// 处理关注/取消关注按钮的点击事件 (基本不变)
  Future<void> _handleFollowTap() async {
    if (!_mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      AppSnackBar.showInfo(context, '请先登录');
      return;
    }
    if (_isLoading) return; // 防止重复点击

    // --- 点击时，取消可能存在的后备 Timer ---
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    // ------------------------------------

    setState(() { _isLoading = true; }); // 进入加载状态

    bool success = false;
    try {
      if (_isFollowing) {
        success = await _followService.unfollowUser(widget.userId);
      } else {
        success = await _followService.followUser(widget.userId);
      }

      if (!_mounted) return;

      if (success) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });
        widget.onFollowChanged?.call();
      } else {
        setState(() { _isLoading = false; });
        AppSnackBar.showError(context, _isFollowing ? '取消关注失败' : '关注失败');
      }
    } catch (e) {
      if (_mounted) {
        setState(() { _isLoading = false; });
        AppSnackBar.showError(context,'操作失败: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- UI 构建逻辑保持不变 ---
    final themeColor = widget.color ?? Theme.of(context).primaryColor;

    // Mini 样式
    if (widget.mini) {
      return SizedBox(
        height: 30,
        child: OutlinedButton(
          onPressed: _handleFollowTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            side: BorderSide(color: _isFollowing ? Colors.grey : themeColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: _isLoading
              ? SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_isFollowing ? Colors.grey : themeColor),
            ),
          )
              : Text(
            _isFollowing ? '已关注' : '关注',
            style: TextStyle(fontSize: 12, color: _isFollowing ? Colors.grey : themeColor),
          ),
        ),
      );
    }

    // 标准样式
    if (_isFollowing) {
      return OutlinedButton.icon(
        onPressed: _handleFollowTap,
        icon: _isLoading
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)))
            : widget.showIcon ? Icon(Icons.check, size: 16, color: Colors.grey) : SizedBox.shrink(),
        label: Text('已关注', style: TextStyle(color: Colors.grey)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: _handleFollowTap,
        icon: _isLoading
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : widget.showIcon ? Icon(Icons.add, size: 16) : SizedBox.shrink(),
        label: Text('关注'),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }
  }
}