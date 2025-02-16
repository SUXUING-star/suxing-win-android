// lib/widgets/form/gameform/field/cover_image_field.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../utils/file_upload.dart';
import '../../../../utils/device/device_utils.dart';
import 'dialog/image_url_dialog.dart';

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
        final coverUrl = await FileUpload.uploadImage(
          File(image.path),
          folder: 'games/covers',
          maxWidth: 1200,
          maxHeight: 1200,
          quality: 85,
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
    final result = await showDialog<String>(
      context: context,
      builder: (context) => ImageUrlDialog(
        initialUrl: coverImageUrl?.startsWith('http') == true ? coverImageUrl : null,
      ),
    );

    if (result != null) {
      onChanged(result);
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
              onPressed: () => _pickCoverImage(context),
              icon: Icon(Icons.upload_file),
              label: Text('上传本地图片'),
            ),
            ElevatedButton.icon(
              onPressed: () => _showUrlDialog(context),
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
      child: coverImageUrl!.startsWith('http')
          ? Image.network(
        coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(child: Text('图片加载失败'));
        },
      )
          : Image.network(
        'uploads/games/covers/${coverImageUrl!.split('/').last}',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(child: Text('图片加载失败'));
        },
      ),
    );
  }
}