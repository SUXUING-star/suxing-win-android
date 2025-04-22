import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/utils/font/font_config.dart';
import 'package:suxingchahui/widgets/components/screen/profile/experience/exp_progress_badge.dart'; // 确认路径
import 'package:suxingchahui/widgets/components/screen/profile/level/level_progress_bar.dart';    // 确认路径
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 确认路径
import 'package:suxingchahui/widgets/ui/buttons/warning_button.dart';
import 'package:suxingchahui/widgets/ui/image/editable_user_avatar.dart';    // 确认路径


class MobileProfileHeader extends StatelessWidget {
  final User user;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  // 这两个回调由 EditableUserAvatar 内部处理后触发，父级 (ProfileScreen) 监听
  final Function(bool) onUploadStateChanged;
  final Function() onUploadSuccess;

  const MobileProfileHeader({
    super.key,
    required this.user,
    required this.onEditProfile,
    required this.onLogout,
    required this.onUploadStateChanged, // 父级需要知道上传状态以显示 Loading
    required this.onUploadSuccess,      // 父级需要知道上传成功以刷新用户数据
  });

  @override
  Widget build(BuildContext context) {
    // --- 移动端固定样式变量 ---
    final double avatarRadius = 50.0; // 移动端头像半径固定为 50
    final double badgeSize = 28.0;    // 移动端徽章大小固定为 28

    final double buttonIconSize = 18;
    final double buttonFontSize = 14;
    final EdgeInsets buttonPadding =
    EdgeInsets.symmetric(horizontal: 20, vertical: 10); // 按钮内边距
    // --- 结束 移动端固定样式变量 ---

    return Container(
      padding: const EdgeInsets.all(16), // 整个 Header 的内边距
      child: Column(
        children: [
          // --- 头像和经验徽章区域 ---
          Stack(
            alignment: Alignment.center, // 确保徽章相对于头像定位
            // 注意：移动端的 Stack 可能不需要 clipBehavior: Clip.none
            children: [
              // 使用新封装的可编辑头像组件
              EditableUserAvatar(
                user: user,
                radius: avatarRadius,
                onUploadStateChanged: onUploadStateChanged,
                onUploadSuccess: onUploadSuccess,
                // 移动端使用不同的编辑图标样式
                iconBackgroundColor: Colors.white,
                iconColor: Colors.black54,
              ),

              // 经验进度徽章 (位置可能需要微调)
              Positioned(
                top: 0, // 示例位置，可能需要你根据实际效果调整
                right: 0, // 示例位置，可能需要你根据实际效果调整
                child: ExpProgressBadge(
                  size: badgeSize,
                  backgroundColor: Theme.of(context).primaryColor,
                  // isDesktop: false, // 移动端不需要 isDesktop 标志（除非 Badge 有差异化逻辑）
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // 头像下方间距

          // --- 用户信息区域 ---
          Text(
            user.username,
            style: TextStyle(
              fontSize: 24, // 移动端用户名稍大
              fontWeight: FontWeight.bold,
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4), // 名字和邮箱间距缩小
          Text(
            user.email, // 再次提醒，邮箱隐私
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14, // 移动端邮箱字体稍小
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16), // 用户信息和按钮间距

          // --- 功能按钮区域 ---
          FunctionalButton(
            onPressed: onEditProfile,
            icon: Icons.edit,
            label: '编辑资料',
            iconSize: buttonIconSize,
            fontSize: buttonFontSize,
            padding: buttonPadding,
          ),
          const SizedBox(height: 12), // 按钮间距

          WarningButton(
            onPressed: onLogout,
            icon: Icons.exit_to_app,
            label: '退出登录',
            iconSize: buttonIconSize,
            fontSize: buttonFontSize,
            padding: buttonPadding,
          ),
          const SizedBox(height: 16), // 按钮和进度条间距

          // --- 等级进度条 ---
          LevelProgressBar(
            user: user,
            // 移动端宽度可以根据屏幕宽度动态计算
            width: MediaQuery.of(context).size.width * 0.6, // 例如屏幕宽度的 60%
          ),
        ],
      ),
    );
  }
}