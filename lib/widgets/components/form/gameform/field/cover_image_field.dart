// lib/widgets/form/gameform/field/cover_image_field.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../services/common/file_upload_service.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../common/image/safe_cached_image.dart';
import 'image_url_dialog.dart';

class CoverImageField extends StatelessWidget {
  final String? coverImageUrl;
  final ValueChanged<String?> onChanged;
  final bool isLoading;
  final ValueChanged<bool> onLoadingChanged;

  const CoverImageField({
    Key? key,
    this.coverImageUrl,
    required this.onChanged,
    required this.isLoading,
    required this.onLoadingChanged,
  }) : super(key: key);

  Future<void> _pickCoverImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      try {
        onLoadingChanged(true);

        // 上传新图片时传递旧图片URL，以便后端删除旧图片
        final coverUrl = await FileUpload.uploadImage(
          File(image.path),
          folder: 'games/covers',
          maxWidth: 1200,
          maxHeight: 1200,
          quality: 85,
          oldImageUrl: coverImageUrl, // 传递旧图片URL
        );
        onChanged(coverUrl);
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

    if (result != null) {
      // 如果用户输入了新的URL，并且存在旧的URL，尝试删除旧图片
      if (coverImageUrl != null && coverImageUrl!.isNotEmpty) {
        // 只有当新旧URL不同时才删除旧图片
        if (result != coverImageUrl) {
          try {
            // 设置loading状态
            onLoadingChanged(true);

            // 删除旧图片
            await FileUpload.deleteFile(coverImageUrl!);

            // 更新URL
            onChanged(result);
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
        onChanged(result);
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
          '封面图片',
          style: TextStyle(fontSize: fontSize),
        ),
        SizedBox(height: verticalSpacing),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: isLoading ? null : () => _pickCoverImage(context),
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
            child: _buildCoverPreview(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPreview(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (coverImageUrl == null || coverImageUrl!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48),
            Text('请选择或输入封面图片'),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SafeCachedImage(
        imageUrl: coverImageUrl!.startsWith('http')
            ? coverImageUrl!
            : 'uploads/games/covers/${coverImageUrl!.split('/').last}',
        fit: BoxFit.cover,
        onError: (url, error) {
          print('封面图片预览加载失败: $url, 错误: $error');
        },
      ),
    );
  }
}