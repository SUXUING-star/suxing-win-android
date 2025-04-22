import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/utils/font/font_config.dart';
import 'package:suxingchahui/widgets/components/screen/profile/experience/exp_progress_badge.dart'; // 确认路径正确
import 'package:suxingchahui/widgets/components/screen/profile/level/level_progress_bar.dart'; // 确认路径正确
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 确认路径正确
import 'package:suxingchahui/widgets/ui/buttons/warning_button.dart';
import 'package:suxingchahui/widgets/ui/image/editable_user_avatar.dart'; // 确认路径正确


class DesktopProfileCard extends StatelessWidget {
  final User user;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  // 这两个回调由 EditableUserAvatar 内部处理后触发，父级 (ProfileScreen) 监听
  final Function(bool) onUploadStateChanged;
  final Function() onUploadSuccess;

  const DesktopProfileCard({
    super.key,
    required this.user,
    required this.onEditProfile,
    required this.onLogout,
    required this.onUploadStateChanged, // 父级需要知道上传状态以显示 Loading
    required this.onUploadSuccess,      // 父级需要知道上传成功以刷新用户数据
  });

  @override
  Widget build(BuildContext context) {
    // --- 响应式布局变量 ---
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 1000; // 调整阈值以适应你的设计

    final double avatarRadius = isSmallScreen ? 50.0 : 60.0; // 头像半径
    final double badgeSize = isSmallScreen ? 32.0 : 38.0;    // 经验徽章大小

    final double buttonIconSize = isSmallScreen ? 18 : 20;
    final double buttonFontSize = isSmallScreen ? 14 : 16;
    final EdgeInsets buttonPadding = EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 8 : 12);
    // --- 结束 响应式布局变量 ---

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView( // 允许内容在极端情况下滚动
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // 内容居中对齐
            mainAxisSize: MainAxisSize.min, // Column 高度自适应内容
            children: [
              // --- 头像和经验徽章区域 ---
              Stack(
                clipBehavior: Clip.none, // 允许徽章溢出到 Card 外部一点
                alignment: Alignment.center,
                children: [
                  // 使用新封装的可编辑头像组件
                  EditableUserAvatar(
                    user: user,
                    radius: avatarRadius, // 控制头像大小
                    onUploadStateChanged: onUploadStateChanged, // 将回调传递下去
                    onUploadSuccess: onUploadSuccess,         // 将回调传递下去
                    iconBackgroundColor: Theme.of(context).primaryColor, // 编辑图标背景色
                    // 可以根据需要定制其他颜色或图标
                  ),

                  // 经验进度徽章 (位置可能需要根据头像大小微调)
                  Positioned(
                    // 使用相对头像半径的位置，更灵活
                    top: -avatarRadius * 0.2, // 稍微向上偏移
                    right: -avatarRadius * 0.2, // 稍微向右偏移
                    child: ExpProgressBadge(
                      size: badgeSize,
                      backgroundColor: Theme.of(context).primaryColor,
                      isDesktop: true, // 传递桌面端标识（如果需要特殊逻辑）
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 16 : 24), // 头像下方间距

              // --- 用户信息区域 ---
              Text(
                user.username,
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // 超长时显示省略号
              ),
              SizedBox(height: 8),
              Text(
                user.email, // 注意：邮箱可能涉及隐私，考虑是否显示或部分显示
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16),

              // --- 等级进度条 ---
              LevelProgressBar(
                user: user,
                // 可以根据 isSmallScreen 调整宽度
                width: isSmallScreen ? 240 : 280,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // --- 功能按钮区域 ---
              // 编辑资料按钮
              FunctionalButton(
                onPressed: onEditProfile, // 使用传入的回调
                icon: Icons.edit,
                label: '编辑资料',
                iconSize: buttonIconSize,
                fontSize: buttonFontSize,
                padding: buttonPadding,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20), // 按钮间距

              // 退出登录按钮
              WarningButton(
                onPressed: onLogout, // 使用传入的回调
                icon: Icons.exit_to_app,
                label: '退出登录',
                iconSize: buttonIconSize,
                fontSize: buttonFontSize,
                padding: buttonPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}