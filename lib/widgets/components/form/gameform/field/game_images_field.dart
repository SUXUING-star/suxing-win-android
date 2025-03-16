// lib/widgets/form/gameform/field/game_images_field.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../utils/upload/file_upload.dart';
import '../../../../utils/device/device_utils.dart';
import '../../../common/image/safe_cached_image.dart';

class GameImagesField extends StatelessWidget {
  final List<String> gameImages;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<bool> onLoadingChanged;

  const GameImagesField({
    Key? key,
    required this.gameImages,
    required this.onChanged,
    required this.onLoadingChanged,
  }) : super(key: key);

  Future<void> _pickGameImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      try {
        onLoadingChanged(true);
        final files = images.map((image) => File(image.path)).toList();

        // A上传新图片（不需要删除旧图片，因为这是添加新截图）
        final urls = await FileUpload.uploadFiles(
          files,
          folder: 'games/screenshots',
        );
        onChanged([...gameImages, ...urls]);
      } catch (e) {
        // 处理错误
        print('上传游戏截图失败: $e');
      } finally {
        onLoadingChanged(false);
      }
    }
  }

  // 删除单个截图
  Future<void> _deleteImage(int index) async {
    try {
      onLoadingChanged(true);

      // 获取要删除的URL
      final urlToDelete = gameImages[index];

      // 创建新的图片列表（不包含要删除的图片）
      final newImages = List<String>.from(gameImages);
      newImages.removeAt(index);

      // 先更新UI，移除图片
      onChanged(newImages);

      // 然后在后台删除图片文件
      await FileUpload.deleteFile(urlToDelete);
    } catch (e) {
      print('删除游戏截图失败: $e');
    } finally {
      onLoadingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = DeviceUtils.isLandscape(context);
    final double imageWidth = isLandscape ? 120 : 160;
    final double imageHeight = isLandscape ? 90 : 120;
    final double fontSize = isLandscape ? 14 : 16;
    final double iconSize = isLandscape ? 14 : 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '游戏截图',
              style: TextStyle(fontSize: fontSize),
            ),
            TextButton.icon(
              onPressed: _pickGameImages,
              icon: Icon(Icons.add, size: iconSize),
              label: Text(
                '添加截图',
                style: TextStyle(fontSize: fontSize),
              ),
            ),
          ],
        ),
        if (gameImages.isNotEmpty)
          Container(
            height: imageHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: gameImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SafeCachedImage(
                        imageUrl: gameImages[index],
                        width: imageWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        onError: (url, error) {
                          print('游戏截图加载失败: $url, 错误: $error');
                        },
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _deleteImage(index),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}