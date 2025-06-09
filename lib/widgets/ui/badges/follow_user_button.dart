// lib/widgets/ui/badges/follow_user_button.dart

/// 该文件定义了 FollowUserButton 组件，一个用于关注/取消关注用户的按钮。
/// FollowUserButton 根据用户的关注状态和登录状态显示不同的按钮样式和功能。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // 导入应用 SnackBar 工具
import 'package:suxingchahui/services/error/api_exception.dart'; // 导入 API 异常
import 'package:suxingchahui/services/error/api_error_definitions.dart'; // 导入 API 错误定义
import 'dart:async'; // 异步操作所需

/// `FollowUserButton` 类：关注/取消关注用户按钮组件。
///
/// 该组件根据用户是否已关注目标用户以及当前用户的登录状态，
/// 显示相应的按钮文本、图标和交互。
class FollowUserButton extends StatefulWidget {
  final UserFollowService followService; // 用户关注服务实例
  final String targetUserId; // 目标用户ID
  final User? currentUser; // 当前登录用户
  final Color? color; // 按钮颜色
  final bool showIcon; // 是否显示图标
  final bool mini; // 是否为迷你模式
  final VoidCallback? onFollowChanged; // 关注状态改变时的回调
  final bool initialIsFollowing; // 初始关注状态

  /// 构造函数。
  ///
  /// [followService]：关注服务。
  /// [targetUserId]：目标用户ID。
  /// [currentUser]：当前用户。
  /// [color]：颜色。
  /// [showIcon]：是否显示图标。
  /// [mini]：是否迷你模式。
  /// [onFollowChanged]：关注状态改变回调。
  /// [initialIsFollowing]：初始关注状态。
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

  /// 创建状态。
  @override
  State<FollowUserButton> createState() => _FollowUserButtonState();
}

/// `_FollowUserButtonState` 类：`FollowUserButton` 的状态管理。
///
/// 管理按钮的关注状态、监听关注状态流和处理关注/取消关注操作。
class _FollowUserButtonState extends State<FollowUserButton> {
  late bool _isFollowing; // 当前关注状态
  StreamSubscription? _followStatusSubscription; // 关注状态流订阅器

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initialIsFollowing; // 初始化关注状态

    _followStatusSubscription =
        widget.followService.followStatusStream.listen((data) {
      // 监听关注状态流
      if (mounted && data.containsKey(widget.targetUserId)) {
        // 组件已挂载且包含目标用户ID
        setState(() {
          _isFollowing = data[widget.targetUserId]!; // 更新关注状态
        });
      }
    });
  }

  @override
  void dispose() {
    _followStatusSubscription?.cancel(); // 取消关注状态流订阅
    super.dispose();
  }

  /// 处理关注/取消关注操作。
  ///
  /// 根据当前关注状态调用关注或取消关注服务，并处理结果。
  Future<void> _handleFollowTap() async {
    if (widget.currentUser == null) {
      // 用户未登录
      if (!mounted) return; // 组件未挂载时返回
      AppSnackBar.showLoginRequiredSnackBar(context); // 提示登录
      return;
    }

    final bool wasFollowing = _isFollowing; // 记录操作前的关注状态

    setState(() {
      _isFollowing = !wasFollowing; // 乐观更新关注状态
    });

    bool apiCallSuccess = false; // API 调用是否成功标记

    try {
      if (!wasFollowing) {
        apiCallSuccess = await widget.followService
            .followUser(widget.targetUserId); // 调用关注服务
      } else {
        apiCallSuccess = await widget.followService
            .unfollowUser(widget.targetUserId); // 调用取消关注服务
      }

      if (!mounted) return; // 组件未挂载时返回

      if (apiCallSuccess) {
        // API 调用成功
        widget.onFollowChanged?.call(); // 调用关注状态改变回调
      } else {
        // API 调用失败
        if (!mounted) return; // 组件未挂载时返回
        setState(() {
          _isFollowing = wasFollowing; // 恢复关注状态
        });
        AppSnackBar.showError(wasFollowing ? '取消关注失败' : '关注失败'); // 显示错误提示
      }
    } on ApiException catch (apiException) {
      // 捕获 API 异常
      if (!mounted) return; // 组件未挂载时返回

      String displayMessage = apiException.effectiveMessage; // 显示消息

      if (apiException.apiErrorCode == BackendApiErrorCodes.followAlready) {
        // 已关注错误
        setState(() {
          _isFollowing = true; // 确保状态为已关注
        });
        AppSnackBar.showInfo(displayMessage); // 显示信息提示
      } else if (apiException.apiErrorCode ==
          BackendApiErrorCodes.unFollowAlready) {
        // 已取消关注错误
        setState(() {
          _isFollowing = false; // 确保状态为未关注
        });
        AppSnackBar.showInfo(displayMessage); // 显示信息提示
      } else {
        setState(() {
          _isFollowing = wasFollowing; // 恢复关注状态
        });
        AppSnackBar.showError(displayMessage); // 显示错误提示
      }
    } catch (e) {
      // 捕获其他异常
      setState(() {
        _isFollowing = wasFollowing; // 恢复关注状态
      });
      AppSnackBar.showError("操作失败,${e.toString()}");
    }
  }

  /// 构建关注按钮。
  ///
  /// 根据是否为迷你模式、是否已关注显示不同的按钮样式。
  @override
  Widget build(BuildContext context) {
    final Color themeColor =
        widget.color ?? Theme.of(context).primaryColor; // 获取主题色

    if (widget.mini) {
      // 迷你模式
      return _buildMiniButton(context, themeColor); // 构建迷你按钮
    } else {
      // 非迷你模式
      return _isFollowing
          ? _buildIsFollowingButton(context, themeColor) // 已关注按钮
          : _buildCanFollowButton(context, themeColor); // 未关注按钮
    }
  }

  /// 构建迷你关注按钮。
  ///
  /// [context]：Build 上下文。
  /// [themeColor]：主题颜色。
  Widget _buildMiniButton(BuildContext context, Color themeColor) {
    return SizedBox(
      height: 30, // 高度
      child: OutlinedButton(
        onPressed: _handleFollowTap, // 点击回调
        style: OutlinedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // 内边距
          side: BorderSide(
              color: _isFollowing ? Colors.grey : themeColor), // 边框颜色
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)), // 形状
        ),
        child: Text(
          _isFollowing ? '已关注' : '关注', // 文本
          style: TextStyle(
              fontSize: 8,
              color: _isFollowing ? Colors.grey : themeColor), // 文本样式
        ),
      ),
    );
  }

  /// 构建已关注按钮。
  ///
  /// [context]：Build 上下文。
  /// [themeColor]：主题颜色。
  Widget _buildIsFollowingButton(BuildContext context, Color themeColor) {
    return OutlinedButton.icon(
      onPressed: _handleFollowTap, // 点击回调
      icon: widget.showIcon // 图标
          ? const Icon(Icons.check, size: 12, color: Colors.grey)
          : const SizedBox.shrink(),
      label: const Text('已关注', style: TextStyle(color: Colors.grey)), // 文本
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.grey), // 边框颜色
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)), // 形状
      ),
    );
  }

  /// 构建可关注按钮。
  ///
  /// [context]：Build 上下文。
  /// [themeColor]：主题颜色。
  Widget _buildCanFollowButton(BuildContext context, Color themeColor) {
    return ElevatedButton.icon(
      onPressed: _handleFollowTap, // 点击回调
      icon: widget.showIcon // 图标
          ? const Icon(Icons.add, size: 12)
          : const SizedBox.shrink(),
      label: const Text('关注'), // 文本
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor, // 背景色
        foregroundColor: Colors.white, // 前景色
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)), // 形状
      ),
    );
  }
}
