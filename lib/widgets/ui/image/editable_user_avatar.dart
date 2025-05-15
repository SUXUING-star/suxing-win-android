import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/user/user.dart'; // 引入 User 模型
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart'; // 引入上传服务
import 'package:suxingchahui/services/main/user/user_service.dart'; // 引入用户服务
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart'; // 引入安全图片加载
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'custom_crop_dialog.dart';

class EditableUserAvatar extends StatelessWidget {
  final User user;
  final double radius; // 控制头像大小
  final Function(bool isLoading) onUploadStateChanged; // 通知父组件上传状态
  final Function() onUploadSuccess; // 通知父组件上传成功（用于刷新）
  final double iconSizeRatio; // 编辑图标相对于半径的比例
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color placeholderColor;
  final IconData placeholderIcon;

  const EditableUserAvatar({
    super.key,
    required this.user,
    required this.radius,
    required this.onUploadStateChanged,
    required this.onUploadSuccess,
    this.iconSizeRatio = 0.3, // 图标默认占半径的 30%
    this.iconColor = Colors.white,
    this.iconBackgroundColor = Colors.blue, // 默认用蓝色
    this.placeholderColor = Colors.grey,
    this.placeholderIcon = Icons.person_outline,
  });

  // --- 核心逻辑：处理头像点击、裁剪和上传 ---
  Future<void> _handleAvatarUpdate(BuildContext context,
      UserService userService, RateLimitedFileUpload fileUploadService) async {
    // 1. 显示裁剪对话框
    final Uint8List? croppedBytes = await CustomCropDialog.show(context);

    // 2. 处理裁剪结果
    if (croppedBytes != null && context.mounted) {
      // 检查 context 是否有效
      onUploadStateChanged(true); // 通知开始上传
      try {
        // 保存到临时文件
        final tempDir = await getTemporaryDirectory();
        final tempFileName =
            'cropped_avatar_${DateTime.now().millisecondsSinceEpoch}.png';
        final tempFile = File('${tempDir.path}/$tempFileName');
        await tempFile.writeAsBytes(croppedBytes);

        // 调用上传服务

        final avatarUrl = await fileUploadService.uploadAvatar(
          tempFile,
          maxWidth: 200,
          maxHeight: 200,
          quality: 90,
          oldAvatarUrl: user.avatar,
        );

        // 更新用户资料

        await userService.updateUserProfile(avatar: avatarUrl);

        // 上传和更新成功
        if (context.mounted) {
          AppSnackBar.showSuccess(context, '头像更新成功');
        }
        onUploadSuccess(); // 通知父组件成功，父组件负责刷新
      } catch (e) {
        print("EditableUserAvatar: Error uploading avatar: $e");
        if (context.mounted) {
          // 简化错误处理：显示通用消息或速率限制消息
          final errorMsg = e.toString();
          if (errorMsg.contains('头像上传速率超限')) {
            AppSnackBar.showWarning(context, '头像上传过于频繁，请稍后再试。');
            // 如果需要显示之前的 RateLimitDialog，需要确保能访问到它
            // final remainingSeconds = parseRemainingSecondsFromError(errorMsg);
            // showAvatarRateLimitDialog(context, remainingSeconds);
          } else {
            AppSnackBar.showError(context, '上传头像失败: ${e.toString()}');
          }
        }
      } finally {
        // 确保在任何情况下都通知加载结束
        if (context.mounted) {
          // 再次检查 context
          onUploadStateChanged(false); // 通知结束上传
        }
      }
    } else {
      print("EditableUserAvatar: Cropping cancelled or failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = radius * iconSizeRatio;
    final bool hasValidAvatar =
        user.avatar != null && user.avatar!.trim().isNotEmpty;
    final userService = context.read<UserService>();
    final fileUploadService = context.read<RateLimitedFileUpload>();

    return GestureDetector(
      onTap: () => _handleAvatarUpdate(context, userService, fileUploadService),
      child: Stack(
        alignment: Alignment.center, // 确保内容居中
        children: [
          // 头像主体 (圆形)
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: placeholderColor.withOpacity(0.2), // 占位背景色
              boxShadow: [
                // 可选：加点阴影提升质感
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: hasValidAvatar
                  ? SafeCachedImage(
                      key: ValueKey(user.avatar!), // URL 变化时强制刷新
                      imageUrl: user.avatar!,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      // SafeCachedImage 自带占位和错误处理
                    )
                  : Center(
                      // 无有效头像时的占位图标
                      child: Icon(
                        placeholderIcon,
                        size: radius, // 图标大小约为半径
                        color: placeholderColor,
                      ),
                    ),
            ),
          ),

          // 编辑图标覆盖层
          Positioned(
            bottom: 0, // 调整位置，使其稍微偏右下
            right: 0,
            child: Container(
              padding: EdgeInsets.all(radius * 0.1), // 内边距也相对化
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5), // 白色描边
              ),
              child: Icon(
                Icons.camera_alt, // 或者 Icons.edit
                color: iconColor,
                size: iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
