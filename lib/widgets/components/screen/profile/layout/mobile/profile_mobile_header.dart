// lib/widgets/components/screen/profile/layout/mobile/profile_mobile_header.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/daily_progress.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart';
import 'package:suxingchahui/widgets/components/screen/profile/experience/exp_progress_badge.dart'; // 确认路径
import 'package:suxingchahui/widgets/components/screen/profile/level/level_progress_bar.dart'; // 确认路径
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/warning_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/image/editable_user_avatar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class ProfileMobileHeader extends StatelessWidget {
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

  const ProfileMobileHeader({
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
    final double avatarRadius = 50.0; // 移动端头像半径固定为 50
    final double badgeSize = 28.0; // 移动端徽章大小固定为 28

    final double buttonIconSize = 18;
    final double buttonFontSize = 14;
    final EdgeInsets buttonPadding =
        EdgeInsets.symmetric(horizontal: 20, vertical: 10); // 按钮内边距

    // 获取签名并检查是否为空
    final String signature = user.signature?.trim() ?? '';
    final bool hasSignature = signature.isNotEmpty;

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
                fileUpload: fileUpload,
                iconBackgroundColor: Colors.white,
                iconColor: Colors.black54,
              ),

              // 经验进度徽章 (位置可能需要微调)
              Positioned(
                top: 0, // 示例位置，可能需要你根据实际效果调整
                right: 0, // 示例位置，可能需要你根据实际效果调整
                child: ExpProgressBadge(
                  currentUser: user,
                  size: badgeSize,
                  backgroundColor: Theme.of(context).primaryColor,
                  dailyProgressData: dailyProgressData,
                  isLoadingExpData: isLoadingExpData,
                  expDataError: expDataError,
                  onRefreshExpData: onRefreshExpData,
                  // isDesktop: false, // 移动端不需要 isDesktop 标志（除非 Badge 有差异化逻辑）
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // 头像下方间距

          // --- 用户信息区域 ---
          AppText(
            user.username,
            style: TextStyle(
              fontSize: 24, // 移动端用户名稍大
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4), // 名字和邮箱间距缩小
          AppText(
            user.email, // 再次提醒，邮箱隐私
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14, // 移动端邮箱字体稍小
            ),
            textAlign: TextAlign.center,
          ),

          if (hasSignature) ...[
            const SizedBox(height: 12),
            Padding(
              // 使用 Padding 控制左右边距，确保居中时不会太靠边
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // <-- 让 Row 内容水平居中
                crossAxisAlignment:
                    CrossAxisAlignment.center, // <-- 交叉轴也居中，让图标和文本垂直对齐
                children: [
                  Icon(
                    Icons.format_quote_rounded, // 保留引号图标
                    size: 18, // 图标大小
                    color: Colors.grey.shade500, // 图标颜色
                  ),
                  const SizedBox(width: 6), // 图标和文本之间的间距
                  Flexible(
                    // 使用 Flexible 而不是 Expanded，当内容不足时不会撑满
                    child: AppText(
                      signature,
                      textAlign: TextAlign.center, // <-- 文本本身也居中对齐
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withSafeOpacity(0.75),
                        height: 1.35,
                      ),
                      maxLines: 3, // 移动端行数
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 如果需要对称的右引号，可以在这里再加一个 Icon，但通常单引号效果也不错
                ],
              ),
            ),
          ],
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
