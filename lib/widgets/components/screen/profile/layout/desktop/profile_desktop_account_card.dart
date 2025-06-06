// lib/widgets/components/screen/profile/layout/desktop/profile_desktop_account_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/daily_progress.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart';
import 'package:suxingchahui/widgets/components/screen/profile/experience/exp_progress_badge.dart';
import 'package:suxingchahui/widgets/components/screen/profile/level/level_progress_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/warning_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/image/editable_user_avatar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class ProfileDesktopAccountCard extends StatelessWidget {
  final User user;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  final RateLimitedFileUpload fileUpload;
  final Function(bool) onUploadStateChanged;
  final Function(String avatarUrl) onUploadSuccess;
  final DailyProgressData? dailyProgressData;
  final bool isLoadingExpData;
  final String? expDataError;
  final VoidCallback onRefreshExpData;

  const ProfileDesktopAccountCard({
    super.key,
    required this.user,
    required this.onEditProfile,
    required this.onLogout,
    required this.fileUpload,
    required this.onUploadStateChanged, // 父级需要知道上传状态以显示 Loading
    required this.onUploadSuccess, // 父级需要知道上传成功以刷新用户数据
    required this.dailyProgressData,
    required this.isLoadingExpData,
    this.expDataError,
    required this.onRefreshExpData,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 1000; // 调整阈值以适应你的设计

    final double avatarRadius = isSmallScreen ? 50.0 : 60.0; // 头像半径
    final double badgeSize = isSmallScreen ? 32.0 : 38.0; // 经验徽章大小

    final double buttonIconSize = isSmallScreen ? 18 : 20;
    final double buttonFontSize = isSmallScreen ? 14 : 16;
    final EdgeInsets buttonPadding = EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24, vertical: isSmallScreen ? 8 : 12);
    final String signature = user.signature?.trim() ?? '';
    final bool hasSignature = signature.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        // 允许内容在极端情况下滚动
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
                    fileUpload: fileUpload,
                    onUploadStateChanged: onUploadStateChanged, // 将回调传递下去
                    onUploadSuccess: onUploadSuccess, // 将回调传递下去
                    iconBackgroundColor:
                        Theme.of(context).primaryColor, // 编辑图标背景色
                    // 可以根据需要定制其他颜色或图标
                  ),

                  // 经验进度徽章 (位置可能需要根据头像大小微调)
                  Positioned(
                    // 使用相对头像半径的位置，更灵活
                    top: -avatarRadius * 0.2, // 稍微向上偏移
                    right: -avatarRadius * 0.2, // 稍微向右偏移
                    child: ExpProgressBadge(
                      currentUser: user,
                      size: badgeSize,
                      backgroundColor: Theme.of(context).primaryColor,
                      isDesktop: true, // 传递桌面端标识（如果需要特殊逻辑）
                      dailyProgressData: dailyProgressData,
                      isLoadingExpData: isLoadingExpData,
                      expDataError: expDataError,
                      onRefreshExpData: onRefreshExpData,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 16 : 24), // 头像下方间距

              // --- 用户信息区域 ---
              AppText(
                user.username,
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // 超长时显示省略号
              ),
              SizedBox(height: 8),
              AppText(
                user.email,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),

              if (hasSignature) ...[
                const SizedBox(height: 14),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20.0), // 控制左右边距
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // <-- 水平居中
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // <-- 垂直居中对齐图标和文本
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: isSmallScreen ? 18 : 20,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withSafeOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        // 文本内容不足时，Flexible 不会强制撑开 Row
                        child: AppText(
                          signature,
                          textAlign: TextAlign.center, // <-- 文本居中
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withSafeOpacity(0.9),
                            height: 1.4,
                          ),
                          maxLines: 4, // 桌面端可以多显示一行
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
