// lib/widgets/ui/badges/follow_user_button.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/services/error/api_exception.dart';
import 'package:suxingchahui/services/error/api_error_definitions.dart';
import 'dart:async';

class FollowUserButton extends StatefulWidget {
  final UserFollowService followService;
  final String targetUserId;
  final User? currentUser;
  final Color? color;
  final bool showIcon;
  final bool mini;
  final VoidCallback? onFollowChanged;
  final bool initialIsFollowing;

  const FollowUserButton({
    super.key,
    required this.followService,
    required this.targetUserId,
    required this.currentUser,
    this.color,
    this.showIcon = true,
    this.mini = false,
    this.onFollowChanged,
    required this.initialIsFollowing,
  });

  @override
  State<FollowUserButton> createState() => _FollowUserButtonState();
}

class _FollowUserButtonState extends State<FollowUserButton> {
  late bool _isFollowing;
  StreamSubscription? _followStatusSubscription;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initialIsFollowing;

    _followStatusSubscription =
        widget.followService.followStatusStream.listen((data) {
      if (mounted && data.containsKey(widget.targetUserId)) {
        setState(() {
          _isFollowing = data[widget.targetUserId]!;
        });
      }
    });
  }

  @override
  void dispose() {
    _followStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleFollowTap() async {
    if (widget.currentUser == null) {
      if (!mounted) return; // 使用 !mounted
      AppSnackBar.showInfo(context, '请先登录');
      return;
    }

    final bool wasFollowing = _isFollowing;

    setState(() {
      _isFollowing = !wasFollowing;
    });

    bool apiCallSuccess = false;

    try {
      if (!wasFollowing) {
        apiCallSuccess =
            await widget.followService.followUser(widget.targetUserId);
      } else {
        apiCallSuccess =
            await widget.followService.unfollowUser(widget.targetUserId);
      }

      if (!mounted) return; // 使用 !mounted

      if (apiCallSuccess) {
        widget.onFollowChanged?.call();
      } else {
        if (!mounted) return; // 使用 !mounted
        setState(() {
          _isFollowing = wasFollowing;
        });
        AppSnackBar.showError(context, wasFollowing ? '取消关注失败' : '关注失败');
      }
    } on ApiException catch (apiException) {
      if (!mounted) return; // 使用 !mounted

      String displayMessage = apiException.effectiveMessage;

      if (apiException.apiErrorCode == BackendApiErrorCodes.followAlready) {
        setState(() {
          _isFollowing = true;
        });
        AppSnackBar.showInfo(context, displayMessage);
      } else if (apiException.apiErrorCode ==
          BackendApiErrorCodes.unFollowAlready) {
        setState(() {
          _isFollowing = false;
        });
        AppSnackBar.showInfo(context, displayMessage);
      } else {
        setState(() {
          _isFollowing = wasFollowing;
        });
        AppSnackBar.showError(context, displayMessage);
      }
    } catch (e) {
      if (!mounted) return; // 使用 !mounted
      setState(() {
        _isFollowing = wasFollowing;
      });
      AppSnackBar.showError(context, '操作失败: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = widget.color ?? Theme.of(context).primaryColor;

    if (widget.mini) {
      return _buildMiniButton(context, themeColor);
    } else {
      return _isFollowing
          ? _buildIsFollowingButton(context, themeColor)
          : _buildCanFollowButton(context, themeColor);
    }
  }

  Widget _buildMiniButton(BuildContext context, Color themeColor) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: _handleFollowTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          side: BorderSide(color: _isFollowing ? Colors.grey : themeColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          _isFollowing ? '已关注' : '关注',
          style: TextStyle(
              fontSize: 8, color: _isFollowing ? Colors.grey : themeColor),
        ),
      ),
    );
  }

  Widget _buildIsFollowingButton(BuildContext context, Color themeColor) {
    return OutlinedButton.icon(
      onPressed: _handleFollowTap,
      icon: widget.showIcon
          ? const Icon(Icons.check, size: 12, color: Colors.grey)
          : const SizedBox.shrink(),
      label: const Text('已关注', style: TextStyle(color: Colors.grey)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildCanFollowButton(BuildContext context, Color themeColor) {
    return ElevatedButton.icon(
      onPressed: _handleFollowTap,
      icon: widget.showIcon
          ? const Icon(Icons.add, size: 12)
          : const SizedBox.shrink(),
      label: const Text('关注'),
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
