import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../utils/file_upload.dart';
import '../../../../utils/device/device_utils.dart'; // 引入 DeviceUtils

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

  Future<void> _pickCoverImage() async {
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
        // Handle error
      } finally {
        onLoadingChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据设备类型调整间距
    final double verticalSpacing = DeviceUtils.isAndroidLandscape(context) ? 4.0 : 8.0;
    final double fontSize = DeviceUtils.isAndroidLandscape(context) ? 14.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '封面图片 - Cover Image',
          style: TextStyle(fontSize: fontSize),
        ),
        SizedBox(height: verticalSpacing),

        TextFormField(
          initialValue: coverImageUrl,
          decoration: InputDecoration(
            labelText: '封面图片链接 (HTTPS) - Cover Image Link (HTTPS)',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
          validator: (value) {
            if ((value == null || value.isEmpty) && coverImageUrl == null) {
              return '请选择或输入封面图片 - Please select or enter a cover image';
            }
            return null;
          },
        ),
        SizedBox(height: verticalSpacing),

        AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildCoverPreview(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPreview() {
    if (coverImageUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 48),
            Text('点击选择本地图片 - Tap to select local image'),
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
          return Center(child: Text('图片加载失败 - Image failed to load'));
        },
      )
          : Image.file(
        File(coverImageUrl!),
        fit: BoxFit.cover,
      ),
    );
  }
}