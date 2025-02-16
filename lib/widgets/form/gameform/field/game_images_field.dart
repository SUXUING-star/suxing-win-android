import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../utils/file_upload.dart';
import '../../../../utils/device/device_utils.dart'; // 引入 DeviceUtils

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
        final urls = await FileUpload.uploadFiles(
          files,
          folder: 'games/screenshots',
        );
        onChanged([...gameImages, ...urls]);
      } catch (e) {
        // Handle error
      } finally {
        onLoadingChanged(false);
      }
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
              '游戏截图 - Game Screenshots',
              style: TextStyle(fontSize: fontSize),
            ),
            TextButton.icon(
              onPressed: _pickGameImages,
              icon: Icon(Icons.add, size: iconSize),
              label: Text(
                '添加截图 - Add Screenshot',
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
                      child: Image.network(
                        gameImages[index],
                        width: imageWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          final newImages = List<String>.from(gameImages);
                          newImages.removeAt(index);
                          onChanged(newImages);
                        },
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