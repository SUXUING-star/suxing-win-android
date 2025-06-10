// lib/widgets/ui/image/editable_user_avatar.dart

/// 该文件定义了 EditableUserAvatar 组件，一个可编辑用户头像的 StatelessWidget。
/// 该组件支持显示用户头像、触发头像编辑流程和处理图片上传。
library;

import 'dart:io'; // 导入 File 类
import 'dart:typed_data'; // 导入 Uint8List
import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:path_provider/path_provider.dart'; // 导入路径提供程序库
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart'; // 导入限速文件上传服务
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart'; // 导入安全缓存图片组件
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart'; // 导入应用 SnackBar 工具
import 'custom_crop_dialog.dart'; // 导入自定义裁剪对话框

/// `EditableUserAvatar` 类：一个可编辑的用户头像组件。
///
/// 该组件显示用户头像，并提供点击以触发图片选择、裁剪和上传功能。
class EditableUserAvatar extends StatelessWidget {
  final User user; // 当前用户模型
  final double radius; // 头像半径
  final RateLimitedFileUpload fileUpload; // 文件上传服务实例
  final Function(bool isLoading) onUploadStateChanged; // 上传状态变化回调
  final Function(String avatarUrl) onUploadSuccess; // 上传成功回调，返回新头像 URL
  final double iconSizeRatio; // 编辑图标大小与头像半径的比例
  final Color iconColor; // 编辑图标颜色
  final Color iconBackgroundColor; // 编辑图标背景色
  final Color placeholderColor; // 占位符颜色
  final IconData placeholderIcon; // 占位符图标

  /// 构造函数。
  ///
  /// [user]：用户。
  /// [radius]：半径。
  /// [fileUpload]：文件上传服务。
  /// [onUploadStateChanged]：上传状态变化回调。
  /// [onUploadSuccess]：上传成功回调。
  /// [iconSizeRatio]：图标大小比例。
  /// [iconColor]：图标颜色。
  /// [iconBackgroundColor]：图标背景色。
  /// [placeholderColor]：占位符颜色。
  /// [placeholderIcon]：占位符图标。
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

  /// 处理头像更新流程。
  ///
  /// [context]：Build 上下文。
  /// 启动裁剪对话框，上传裁剪后的图片，并处理上传结果。
  Future<void> _handleAvatarUpdate(BuildContext context) async {
    final CropResult? cropResult =
        await CustomCropDialog.show(context); // 显示裁剪对话框

    if (cropResult == null || cropResult.bytes.isEmpty) {
      // 用户取消或裁剪结果为空
      return;
    }

    if (!context.mounted) return; // 上下文未挂载时返回

    onUploadStateChanged(true); // 通知上传开始

    File? tempFileToDelete; // 临时文件对象，用于清理

    try {
      final Uint8List croppedBytes = cropResult.bytes; // 获取裁剪后的图片字节数据
      final String outputExtension = cropResult.outputExtension; // 获取输出文件扩展名

      final tempDir = await getTemporaryDirectory(); // 获取临时目录
      final tempFileName =
          'cropped_avatar_${DateTime.now().millisecondsSinceEpoch}$outputExtension'; // 生成临时文件名
      final tempFile = File('${tempDir.path}/$tempFileName'); // 创建临时文件
      tempFileToDelete = tempFile; // 记录临时文件以便清理

      await tempFile.writeAsBytes(croppedBytes); // 将字节数据写入临时文件

      final avatarUrl = await fileUpload.uploadAvatar(tempFile); // 上传临时文件

      // 检查上下文挂载状态
      AppSnackBar.showSuccess('头像更新成功'); // 显示成功提示

      onUploadSuccess(avatarUrl); // 通知父组件上传成功
    } catch (e) {
      // 捕获上传过程中的异常
      if (context.mounted) {
        // 检查上下文挂载状态
        final errorMsg = e.toString(); // 获取错误消息字符串
        if (errorMsg.contains('头像上传速率超限')) {
          // 判断是否为速率超限错误
          AppSnackBar.showWarning('头像上传过于频繁，请稍后再试。'); // 显示速率超限警告
        } else {
          AppSnackBar.showError("操作失败,${e.toString()}");
        }
      }
      if (context.mounted) {
        // 检查上下文挂载状态
        onUploadStateChanged(false); // 通知上传结束（失败）
      }
    } finally {
      // 确保执行清理操作
      if (tempFileToDelete != null) {
        // 存在临时文件时
        try {
          if (await tempFileToDelete.exists()) {
            // 检查文件是否存在
            await tempFileToDelete.delete(); // 删除临时文件
          }
        } catch (e) {
          // 删除临时文件发生异常时无操作
        }
      }
    }
  }

  /// 构建可编辑的用户头像组件。
  @override
  Widget build(BuildContext context) {
    final iconSize = radius * iconSizeRatio; // 计算编辑图标大小
    final bool hasValidAvatar =
        user.avatar != null && user.avatar!.trim().isNotEmpty; // 判断是否存在有效头像 URL

    return GestureDetector(
      onTap: () => _handleAvatarUpdate(context), // 点击时触发头像更新流程
      child: Stack(
        alignment: Alignment.center, // 堆栈内容居中对齐
        children: [
          Container(
            width: radius * 2, // 容器宽度
            height: radius * 2, // 容器高度
            decoration: BoxDecoration(
              shape: BoxShape.circle, // 形状为圆形
              color: placeholderColor.withSafeOpacity(0.2), // 背景色
              boxShadow: [
                // 阴影
                BoxShadow(
                  color: Colors.black.withSafeOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              // 裁剪为圆形
              child: hasValidAvatar // 根据是否存在有效头像显示不同内容
                  ? SafeCachedImage(
                      key: ValueKey(user.avatar!), // 图片键
                      imageUrl: user.avatar!, // 图片 URL
                      width: radius * 2, // 图片宽度
                      height: radius * 2, // 图片高度
                      fit: BoxFit.cover, // 图片填充模式
                    )
                  : Center(
                      // 占位符
                      child: Icon(
                        placeholderIcon, // 占位符图标
                        size: radius, // 占位符图标大小
                        color: placeholderColor, // 占位符图标颜色
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 0, // 底部对齐
            right: 0, // 右侧对齐
            child: Container(
              padding: EdgeInsets.all(radius * 0.1), // 内边距
              decoration: BoxDecoration(
                color: iconBackgroundColor, // 背景色
                shape: BoxShape.circle, // 形状为圆形
                border: Border.all(color: Colors.white, width: 1.5), // 边框
              ),
              child: Icon(
                Icons.camera_alt, // 相机图标
                color: iconColor, // 图标颜色
                size: iconSize, // 图标大小
              ),
            ),
          ),
        ],
      ),
    );
  }
}
