// lib/widgets/components/button/follow_user_button.dart
import 'package:flutter/material.dart';
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

  const FollowUserButton({
    Key? key,
    required this.userId,
    this.color,
    this.showIcon = true,
    this.mini = false,
    this.onFollowChanged,
  }) : super(key: key);

  @override
  _FollowUserButtonState createState() => _FollowUserButtonState();
}

class _FollowUserButtonState extends State<FollowUserButton> {
  final UserFollowService _followService = UserFollowService();
  bool _isFollowing = false;
  bool _isLoading = false;

  // 跟踪上次状态检查时间 - 减少频繁API调用
  DateTime? _lastStatusCheckTime;
  static const Duration _minStatusCheckInterval = Duration(minutes: 10);

  StreamSubscription? _followStatusSubscription;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();

    // 延迟检查关注状态，避免在初始化时过多请求
    Future.delayed(Duration(milliseconds: 100), () {
      if (_mounted) {
        _checkFollowStatus(initialCheck: true);
      }
    });

    // 监听关注状态变化
    _followStatusSubscription = _followService.followStatusStream.listen((changedUserId) {
      if (changedUserId == widget.userId && _mounted) {
        _checkFollowStatus(forceCheck: true);
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _followStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkFollowStatus({bool forceCheck = false, bool initialCheck = false}) async {
    // 状态检查节流控制
    final now = DateTime.now();
    if (!forceCheck && _lastStatusCheckTime != null) {
      final timeSinceLastCheck = now.difference(_lastStatusCheckTime!);
      if (timeSinceLastCheck < _minStatusCheckInterval) {
        print('关注状态检查被节流: ${widget.userId}');
        return;
      }
    }

    if (!_mounted) return;

    try {
      if (initialCheck || _isLoading) {
        // 第一次检查或正在加载时，直接设置加载状态
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }
      }

      // 使用缓存优化的 isFollowing 方法
      final isFollowing = await _followService.isFollowing(widget.userId);
      _lastStatusCheckTime = now;

      if (_mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('检查关注状态失败: $e');
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFollowTap() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 检查用户是否已登录
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先登录'),
          action: SnackBarAction(
            label: '去登录',
            onPressed: () {
              Navigator.pushNamed(context, 'login');
            },
          ),
        ),
      );
      return;
    }

    // 防止重复点击
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      bool success;
      if (_isFollowing) {
        // 取消关注
        success = await _followService.unfollowUser(widget.userId);
      } else {
        // 关注
        success = await _followService.followUser(widget.userId);
      }

      if (success && _mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });

        // 调用回调
        if (widget.onFollowChanged != null) {
          widget.onFollowChanged!();
        }
      } else if (_mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isFollowing ? '取消关注失败' : '关注失败'))
        );
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;

    if (widget.mini) {
      return SizedBox(
        height: 30,
        child: OutlinedButton(
          onPressed: _handleFollowTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            side: BorderSide(
              color: _isFollowing ? Colors.grey : color,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isLoading
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_isFollowing ? Colors.grey : color),
            ),
          )
              : Text(
            _isFollowing ? '已关注' : '关注',
            style: TextStyle(
              fontSize: 12,
              color: _isFollowing ? Colors.grey : color,
            ),
          ),
        ),
      );
    }

    return _isFollowing
        ? OutlinedButton.icon(
      onPressed: _handleFollowTap,
      icon: _isLoading
          ? SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      )
          : widget.showIcon ? Icon(Icons.check, size: 16, color: Colors.grey) : SizedBox(),
      label: Text('已关注', style: TextStyle(color: Colors.grey)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    )
        : ElevatedButton.icon(
      onPressed: _handleFollowTap,
      icon: _isLoading
          ? SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : widget.showIcon ? Icon(Icons.add, size: 16) : SizedBox(),
      label: Text('关注'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}