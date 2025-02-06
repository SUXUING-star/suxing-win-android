// widgets/form/gameform/cover_image_field.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../utils/oss_upload.dart';

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
        final coverUrl = await OSSUpload.uploadImage(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('封面图片 - Cover Image'),
        SizedBox(height: 8),

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
        SizedBox(height: 8),

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