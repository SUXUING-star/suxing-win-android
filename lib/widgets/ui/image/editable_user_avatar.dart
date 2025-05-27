// lib/widgets/ui/image/editable_user_avatar.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'custom_crop_dialog.dart';

class EditableUserAvatar extends StatelessWidget {
  final User user;
  final double radius;
  final RateLimitedFileUpload fileUpload;
  final Function(bool isLoading) onUploadStateChanged;
  final Function(String? avatarUrl) onUploadSuccess; // 这个回调应该只关心最终的URL
  final double iconSizeRatio;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color placeholderColor;
  final IconData placeholderIcon;

  const EditableUserAvatar({
    super.key,
    required this.user,
    required this.radius,
    required this.fileUpload,
    required this.onUploadStateChanged,
    required this.onUploadSuccess,
    this.iconSizeRatio = 0.3,
    this.iconColor = Colors.white,
    this.iconBackgroundColor = Colors.blue,
    this.placeholderColor = Colors.grey,
    this.placeholderIcon = Icons.person_outline,
  });

  Future<void> _handleAvatarUpdate(BuildContext context) async {
    // 1. 显示裁剪对话框，现在返回 CropResult?
    final CropResult? cropResult = await CustomCropDialog.show(context);

    // 用户取消或裁剪失败
    if (cropResult == null || cropResult.bytes.isEmpty) {
      // 不需要设置 onUploadStateChanged(true) 因为没有东西要上传
      return;
    }

    // 确保 context 仍然有效
    if (!context.mounted) return;

    onUploadStateChanged(true); // 准备开始上传，设置加载状态

    File? tempFileToDelete; // 用于在 finally 中删除创建的临时文件

    try {
      final Uint8List croppedBytes = cropResult.bytes;
      final String outputExtension =
          cropResult.outputExtension; // 例如 ".jpg" 或 ".png"

      final tempDir = await getTemporaryDirectory();
      // 根据 outputExtension 生成正确的文件名
      final tempFileName =
          'cropped_avatar_${DateTime.now().millisecondsSinceEpoch}$outputExtension';
      final tempFile = File('${tempDir.path}/$tempFileName');
      tempFileToDelete = tempFile; // 记录以便删除

      await tempFile.writeAsBytes(croppedBytes);

      // 调用上传服务
      // RateLimitedFileUpload.uploadAvatar 现在接收 File 对象
      final avatarUrl = await fileUpload.uploadAvatar(tempFile); // 传整个File对象

      if (context.mounted) {
        AppSnackBar.showSuccess(context, '头像更新成功');
      }
      onUploadSuccess(avatarUrl); // 通知父组件成功，父组件负责刷新
    } catch (e) {
      if (context.mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('头像上传速率超限')) {
          AppSnackBar.showWarning(context, '头像上传过于频繁，请稍后再试。');
        } else {
          AppSnackBar.showError(context, '上传头像失败: ${e.toString()}');
        }
      }
    } finally {
      if (context.mounted) {
        onUploadStateChanged(false); // 结束上传，重置加载状态
      }
      // 清理临时文件
      if (tempFileToDelete != null) {
        try {
          if (await tempFileToDelete.exists()) {
            await tempFileToDelete.delete();
          }
        } catch (_) {
          // Log deletion error if necessary
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = radius * iconSizeRatio;
    final bool hasValidAvatar =
        user.avatar != null && user.avatar!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => _handleAvatarUpdate(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: placeholderColor.withSafeOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withSafeOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: hasValidAvatar
                  ? SafeCachedImage(
                      key: ValueKey(user.avatar!),
                      imageUrl: user.avatar!,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        placeholderIcon,
                        size: radius,
                        color: placeholderColor,
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(radius * 0.1),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                Icons.camera_alt,
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
