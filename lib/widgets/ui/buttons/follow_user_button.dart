// lib/widgets/ui/buttons/follow_user_button.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'dart:async';

class FollowUserButton extends StatelessWidget {
  final UserFollowService followService;
  final String targetUserId;
  final User? currentUser;
  final Color? color;
  final bool showIcon;
  final bool mini;
  final VoidCallback? onFollowChanged;
  final bool? initialIsFollowing;

  const FollowUserButton({
    super.key,
    required this.followService,
    required this.targetUserId,
    required this.currentUser,
    this.color,
    this.showIcon = true,
    this.mini = false,
    this.onFollowChanged,
    this.initialIsFollowing,
  });

  Future<void> _handleFollowTap(
      BuildContext context, bool currentIsFollowingState) async {
    if (currentUser == null) {
      if (!context.mounted) {
        AppSnackBar.showInfo(context, '请先登录');
      }
      return;
    }

    bool success = false;
    String? apiErrorMessage;

    try {
      if (!currentIsFollowingState) {
        success = await followService.followUser(targetUserId);
      } else {
        success = await followService.unfollowUser(targetUserId);
      }

      if (!context.mounted) return;

      if (success) {
        onFollowChanged?.call();
      } else {
        AppSnackBar.showError(
            context, currentIsFollowingState ? '取消关注失败' : '关注失败');
      }
    } catch (e) {
      apiErrorMessage = e.toString();
      if (!context.mounted) return;
      AppSnackBar.showError(context, '操作失败: $apiErrorMessage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = color ?? Theme.of(context).primaryColor;

    return FutureBuilder<bool>(
      future: followService.isFollowing(targetUserId),
      initialData: initialIsFollowing,
      builder: (context, initialSnapshot) {
        bool isFollowingState =
            initialSnapshot.data ?? initialIsFollowing ?? false;

        if (initialSnapshot.connectionState == ConnectionState.waiting &&
            initialSnapshot.data == null) {
          // 如果 Future 正在加载且没有 initialData，可以显示一个加载指示器或使用默认值
          // 这里简单地使用 initialIsFollowing (如果提供) 或 false
          isFollowingState = initialIsFollowing ?? false;
        } else if (initialSnapshot.hasError) {
          isFollowingState = initialIsFollowing ?? false;
        } else if (initialSnapshot.hasData) {
          isFollowingState = initialSnapshot.data!;
        }

        return StreamBuilder<Map<String, bool>>(
          stream: followService.followStatusStream,
          builder: (context, streamSnapshot) {
            if (streamSnapshot.hasData &&
                streamSnapshot.data!.containsKey(targetUserId)) {
              isFollowingState = streamSnapshot.data![targetUserId]!;
            }

            if (mini) {
              return _buildMiniButton(context, themeColor, isFollowingState);
            } else {
              return isFollowingState
                  ? _buildIsFollowingButton(
                      context, themeColor, isFollowingState)
                  : _buildCanFollowButton(
                      context, themeColor, isFollowingState);
            }
          },
        );
      },
    );
  }

  Widget _buildMiniButton(
      BuildContext context, Color themeColor, bool isFollowing) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: () => _handleFollowTap(context, isFollowing),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          side: BorderSide(color: isFollowing ? Colors.grey : themeColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          isFollowing ? '已关注' : '关注',
          style: TextStyle(
              fontSize: 8, color: isFollowing ? Colors.grey : themeColor),
        ),
      ),
    );
  }

  Widget _buildIsFollowingButton(
      BuildContext context, Color themeColor, bool currentIsFollowing) {
    return OutlinedButton.icon(
      onPressed: () => _handleFollowTap(context, currentIsFollowing),
      icon: showIcon
          ? const Icon(Icons.check, size: 12, color: Colors.grey)
          : const SizedBox.shrink(),
      label: const Text('已关注', style: TextStyle(color: Colors.grey)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildCanFollowButton(
      BuildContext context, Color themeColor, bool currentIsFollowing) {
    return ElevatedButton.icon(
      onPressed: () => _handleFollowTap(context, currentIsFollowing),
      icon:
          showIcon ? const Icon(Icons.add, size: 12) : const SizedBox.shrink(),
      label: const Text('关注'),
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
