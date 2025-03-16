// lib/widgets/components/form/announcementform/field/image_field.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../services/common/file_upload_service.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../common/image/safe_cached_image.dart';
import '../../gameform/field/image_url_dialog.dart';

class AnnouncementImageField extends StatelessWidget {
  final String? imageUrl;
  final ValueChanged<String> onImageUrlChanged;
  final bool isLoading;
  final ValueChanged<bool> onLoadingChanged;

  const AnnouncementImageField({
    Key? key,
    this.imageUrl,
    required this.onImageUrlChanged,
    required this.isLoading,
    required this.onLoadingChanged,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      try {
        onLoadingChanged(true);

        // 上传新图片时传递旧图片URL，以便后端删除旧图片
        final uploadedUrl = await FileUpload.uploadImage(
          File(image.path),
          folder: 'announcements/images',
          maxWidth: 1200,
          maxHeight: 800,
          quality: 85,
          oldImageUrl: imageUrl, // 传递旧图片URL
        );
        onImageUrlChanged(uploadedUrl);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上传图片失败：$e')),
          );
        }
      } finally {
        onLoadingChanged(false);
      }
    }
  }

  Future<void> _showUrlDialog(BuildContext context) async {
    // 不传递initialUrl，这样就不会显示原来的路径
    final result = await showDialog<String>(
      context: context,
      builder: (context) => ImageUrlDialog(initialUrl: ''),
    );

    if (result != null && result.isNotEmpty) {
      // 如果用户输入了新的URL，并且存在旧的URL，尝试删除旧图片
      if (imageUrl != null && imageUrl!.isNotEmpty) {
        // 只有当新旧URL不同时才删除旧图片
        if (result != imageUrl) {
          try {
            // 设置loading状态
            onLoadingChanged(true);

            // 删除旧图片
            await FileUpload.deleteFile(imageUrl!);

            // 更新URL
            onImageUrlChanged(result);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('删除旧图片失败，但新URL已更新')),
              );
            }
          } finally {
            onLoadingChanged(false);
          }
        }
      } else {
        // 如果没有旧图片，直接更新URL
        onImageUrlChanged(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double verticalSpacing = DeviceUtils.isAndroidLandscape(context) ? 4.0 : 8.0;
    final double fontSize = DeviceUtils.isAndroidLandscape(context) ? 14.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '公告图片',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
        SizedBox(height: verticalSpacing),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: isLoading ? null : () => _pickImage(context),
              icon: Icon(Icons.upload_file),
              label: Text('上传本地图片'),
            ),
            ElevatedButton.icon(
              onPressed: isLoading ? null : () => _showUrlDialog(context),
              icon: Icon(Icons.link),
              label: Text('输入图片链接'),
            ),
          ],
        ),
        SizedBox(height: verticalSpacing),

        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildImagePreview(context),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '添加图片可以让您的公告更加生动，留空则不显示图片。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (imageUrl != null && imageUrl!.isNotEmpty)
          TextButton.icon(
            onPressed: isLoading ? null : () {
              _confirmDeleteImage(context);
            },
            icon: Icon(Icons.delete, color: Colors.red),
            label: Text('删除图片', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (imageUrl == null || imageUrl!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('请选择或输入公告图片', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SafeCachedImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        onError: (url, error) {
          print('公告图片预览加载失败: $url, 错误: $error');
        },
      ),
    );
  }

  Future<void> _confirmDeleteImage(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除此图片吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && imageUrl != null && imageUrl!.isNotEmpty) {
      try {
        onLoadingChanged(true);
        await FileUpload.deleteFile(imageUrl!);
        onImageUrlChanged('');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除图片失败：$e')),
          );
        }
      } finally {
        onLoadingChanged(false);
      }
    }
  }
}