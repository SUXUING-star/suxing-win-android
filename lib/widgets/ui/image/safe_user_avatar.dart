// lib/widgets/ui/image/safe_user_avatar.dart
import 'package:flutter/material.dart';
import '../../../services/main/user/user_service.dart';
import 'safe_cached_image.dart';
import '../../../screens/profile/open_profile_screen.dart';

/// 安全的用户头像组件
///
/// 统一处理用户头像的显示、缓存、错误状态及点击事件
class SafeUserAvatar extends StatefulWidget {
  /// 用户ID - 如果提供，将尝试通过ID获取用户信息
  final String? userId;

  /// 直接提供的头像URL - 如果提供，优先使用此URL而不请求服务器
  final String? avatarUrl;

  /// 用户名 - 用于生成头像占位图和fallback显示
  final String? username;

  /// 头像大小 - 控制显示的半径大小
  final double radius;

  /// 是否启用导航到用户资料页
  final bool enableNavigation;

  /// 点击头像的自定义回调
  final VoidCallback? onTap;

  /// 额外的占位符小部件
  final Widget? placeholder;

  /// 边框颜色
  final Color? borderColor;

  /// 边框宽度
  final double? borderWidth;

  /// 背景颜色
  final Color? backgroundColor;

  const SafeUserAvatar({
    Key? key,
    this.userId,
    this.avatarUrl,
    this.username,
    this.radius = 20,
    this.enableNavigation = true,
    this.onTap,
    this.placeholder,
    this.borderColor,
    this.borderWidth,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<SafeUserAvatar> createState() => _SafeUserAvatarState();
}

class _SafeUserAvatarState extends State<SafeUserAvatar> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  String? _avatarUrl;
  String? _username;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.avatarUrl;
    _username = widget.username;

    // 如果没有直接提供avatarUrl但提供了userId，则尝试加载用户信息
    if (_avatarUrl == null && widget.userId != null) {
      _loadUserInfo();
    }
  }

  @override
  void didUpdateWidget(SafeUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 检查关键属性是否变化，如变化则更新
    if (widget.userId != oldWidget.userId ||
        widget.avatarUrl != oldWidget.avatarUrl ||
        widget.username != oldWidget.username) {
      _avatarUrl = widget.avatarUrl;
      _username = widget.username;

      if (_avatarUrl == null && widget.userId != null) {
        _loadUserInfo();
      }
    }
  }

  /// 加载用户信息
  Future<void> _loadUserInfo() async {
    if (widget.userId == null || _isLoading) return;

    // Set loading state
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userInfo = await _userService.getUserInfoById(widget.userId!);

      // Check mounted again before setState
      if (mounted) {
        setState(() {
          _avatarUrl = userInfo['avatar'];
          // Always use the username from userInfo if available
          _username = userInfo['username'] ?? _username ?? '未知用户';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Avatar loading error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 导航到用户个人资料页
  void _navigateToProfile(BuildContext context) {
    if (widget.userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OpenProfileScreen(userId: widget.userId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.radius * 2;

    // 构建头像内容
    Widget avatarContent;

    if (_isLoading) {
      // 加载状态
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.backgroundColor ?? Colors.grey.shade200,
        ),
        child: Center(
          child: SizedBox(
            width: widget.radius,
            height: widget.radius,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor.withOpacity(0.5),
              ),
            ),
          ),
        ),
      );
    } else if (_avatarUrl != null) {
      // 有头像URL的情况
      avatarContent = SafeCachedImage(
        imageUrl: _avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(size),
        backgroundColor: widget.backgroundColor ?? Colors.grey.shade200,
        onError: (url, error) {
          // 头像加载失败，降级显示首字母头像
          // 由于setState可能导致build循环，这里不设置state
          // 而是依赖SafeCachedImage的错误处理显示
          print('头像加载失败: $url, 错误: $error');
        },
      );
    } else {
      // 无头像的情况，显示首字母或占位图标
      final String displayChar = (_username?.isNotEmpty == true)
          ? _username![0].toUpperCase()
          : '?';

      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.backgroundColor ?? Colors.grey.shade200,
        ),
        child: Center(
          child: widget.placeholder ?? Text(
            displayChar,
            style: TextStyle(
              fontSize: widget.radius * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    // 添加边框（如果需要）
    if (widget.borderColor != null && widget.borderWidth != null) {
      avatarContent = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.borderColor!,
            width: widget.borderWidth!,
          ),
        ),
        child: ClipOval(child: avatarContent),
      );
    }

    // 添加点击事件
    if (widget.onTap != null || (widget.enableNavigation && widget.userId != null)) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap ??
              (widget.enableNavigation ? () => _navigateToProfile(context) : null),
          child: avatarContent,
        ),
      );
    }

    return avatarContent;
  }
}