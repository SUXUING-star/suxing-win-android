// lib/widgets/components/form/announcementform/field/announcement_image_field.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';

class AnnouncementImageField extends StatelessWidget {
  final dynamic imageSource;
  final ValueChanged<dynamic> onImageSourceChanged;

  const AnnouncementImageField({
    super.key,
    required this.imageSource,
    required this.onImageSourceChanged,
  });

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200, // 限制大小可以在选择时进行，也可在上传时
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      onImageSourceChanged(image); // 回调 XFile
    }
  }

  void _clearImage(BuildContext context) {
    if (imageSource != null) {
      onImageSourceChanged(null); // 回调 null 清除图片源
      AppSnackBar.showSuccess('图片已清除'); // 反馈
    }
  }

  @override
  Widget build(BuildContext context) {
    final double verticalSpacing = DeviceUtils.isDesktop ? 8.0 : 6.0; // 调整间距
    final double fontSize = DeviceUtils.isDesktop ? 16.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '公告图片 (可选)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
        SizedBox(height: verticalSpacing),

        Row(
          // 使用 Expanded 让按钮均分布局更佳
          children: [
            Expanded(
              child: ElevatedButton.icon(
                // onPressed: isLoading ? null : () => _pickImage(context), // 移除 isLoading 判断
                onPressed: () => _pickImage(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('本地图片'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        SizedBox(height: verticalSpacing),

        // 预览区域
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100, // 添加背景色
            ),
            // 调用新的预览方法
            child: _buildImagePreview(context),
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                '添加图片让公告更生动。',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 仅当有图片源时显示删除按钮
            if (imageSource != null)
              TextButton.icon(
                // onPressed: isLoading ? null : () => _confirmDeleteImage(context), // 移除 isLoading 判断
                // 直接调用清除方法，不再需要确认对话框，因为还没上传
                onPressed: () => _clearImage(context),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
                label: const Text('清除图片',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
          ],
        ),
      ],
    );
  }

  // 新的预览方法，处理 XFile 和 String
  Widget _buildImagePreview(BuildContext context) {
    final source = imageSource;

    if (source == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('无图片', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    Widget imageWidget;
    if (source is XFile) {
      // 预览本地文件
      imageWidget = Image.file(
        File(source.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // print("本地图片预览错误: ${source.path}, $error");
          return const Center(
              child:
                  Icon(Icons.broken_image, size: 48, color: Colors.redAccent));
        },
      );
    } else if (source is String && source.isNotEmpty) {
      // 预览网络 URL
      final imageUrl = source;
      final String displayUrl = imageUrl;
      imageWidget = SafeCachedImage(
        memCacheWidth: 140,
        imageUrl: displayUrl,
        fit: BoxFit.cover,
      );
    } else {
      // 无效的源或空字符串
      return const Center(
          child: Icon(Icons.help_outline, size: 48, color: Colors.grey));
    }

    // 添加圆角裁剪
    return ClipRRect(
      borderRadius: BorderRadius.circular(7.0), // 稍微小于容器的圆角
      child: imageWidget,
    );
  }

// _confirmDeleteImage 方法不再需要，因为清除是即时的，没有实际删除服务器文件
}
