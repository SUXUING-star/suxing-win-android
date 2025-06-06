// lib/widgets/components/form/gameform/field/game_images_field.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';

class GameImagesField extends StatelessWidget {
  final List<dynamic> gameImagesSources;
  final ValueChanged<List<dynamic>> onChanged;
  final bool isLoading;

  const GameImagesField({
    super.key,
    required this.gameImagesSources,
    required this.onChanged,
    required this.isLoading, // 父组件的加载状态
  });

  // 选择多张本地图片
  Future<void> _pickGameImages() async {
    if (isLoading) return; // 父组件加载时禁用

    final ImagePicker picker = ImagePicker();
    // 选择多张图片
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      // 将新选的 XFile 添加到现有列表末尾
      final newList = [...gameImagesSources, ...images];
      onChanged(newList); // 将包含新 XFile 的完整列表传递给父组件
    }
  }

  // 删除指定索引的图片（可能是 URL 或 XFile）
  Future<void> _deleteImage(int index) async {
    if (isLoading) return; // 父组件加载时禁用
    if (index < 0 || index >= gameImagesSources.length) return;

    // 创建一个不包含该索引项的新列表
    final newList = List<dynamic>.from(gameImagesSources);
    newList.removeAt(index);

    // 立即更新父组件状态，让 UI 刷新
    onChanged(newList);
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
            Text('游戏截图', style: TextStyle(fontSize: fontSize)),
            FunctionalButton(
              onPressed: isLoading ? null : _pickGameImages,
              icon: Icons.add,
              iconSize: iconSize,
              label: '添加截图',
              isEnabled: !isLoading,
            ),
          ],
        ),
        // 图片列表预览
        if (gameImagesSources.isNotEmpty)
          Container(
            height: imageHeight + 8,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: gameImagesSources.length,
              itemBuilder: (context, index) {
                if (index >= gameImagesSources.length) {
                  return const SizedBox.shrink();
                }
                final source = gameImagesSources[index];
                Widget imageWidget;

                // 根据源类型创建预览 Widget
                if (source is XFile) {
                  // print(
                  //     "Game Image Preview [$index]: Rendering XFile: ${source.path}");
                  imageWidget =
                      Image.file(File(source.path), // <--- 从 XFile 创建 File
                          width: imageWidth,
                          height: imageHeight,
                          fit: BoxFit.cover, errorBuilder: (ctx, err, st) {
                    // print("Error rendering XFile preview ${source.path}: $err");
                    return Container(
                        width: imageWidth,
                        height: imageHeight,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image));
                  });
                } else if (source is File) {
                  // print(
                  //     "Game Image Preview [$index]: Rendering File: ${source.path}");
                  imageWidget = Image.file(source, // <--- 直接使用 File 对象
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.cover, errorBuilder: (ctx, err, st) {
                    // print("Error rendering File preview ${source.path}: $err");
                    return Container(
                        width: imageWidth,
                        height: imageHeight,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image));
                  });
                } else if (source is String) {
                  // print(
                  //     "Game Image Preview [$index]: Rendering String URL: $source");
                  final imageUrl = source;
                  // 不需要再拼接 baseUrl
                  final String displayUrl = imageUrl;
                  imageWidget = SafeCachedImage(
                    imageUrl: displayUrl,
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.cover,
                  );
                } else {
                  imageWidget = Container(
                      width: imageWidth,
                      height: imageHeight,
                      color: Colors.grey[200],
                      child: const Icon(Icons.help_outline));
                }

                // Stack with delete button (保持不变)
                return Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: imageWidget,
                      ),
                      Positioned(
                          top: -4,
                          right: 0,
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap:
                                  isLoading ? null : () => _deleteImage(index),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close,
                                    size: iconSize, color: Colors.white),
                              ),
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
          )
        // 没有图片时的提示
        else if (!isLoading) // 不在加载时才显示提示
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('暂无截图，点击 "添加截图" 上传。',
                style: TextStyle(color: Colors.grey[600])),
          ),
      ],
    );
  }
}
