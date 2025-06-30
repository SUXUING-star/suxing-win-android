// lib/widgets/components/form/gameform/field/game_images_form_field.dart

/// 该文件定义了 [GameImagesFormField] 组件，用于游戏图片的选择和管理。
/// [GameImagesFormField] 提供添加和删除游戏图片的功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:image_picker/image_picker.dart'; // 图片选择器所需
import 'dart:io'; // 文件操作所需
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类所需
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 功能按钮组件所需
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart'; // 安全缓存图片组件所需

/// [GameImagesFormField] 类：游戏图片选择和管理的 StatelessWidget。
///
/// 该组件提供图片上传、预览和删除功能。
class GameImagesFormField extends StatelessWidget {
  final List<dynamic> gameImagesSources; // 游戏图片来源列表
  final ValueChanged<List<dynamic>> onChanged; // 图片列表变化时的回调
  final bool isLoading; // 父组件加载状态

  /// 构造函数。
  ///
  /// [gameImagesSources]：游戏图片来源列表。
  /// [onChanged]：图片列表变化时的回调。
  /// [isLoading]：父组件加载状态。
  const GameImagesFormField({
    super.key,
    required this.gameImagesSources,
    required this.onChanged,
    required this.isLoading,
  });

  /// 选择多张本地图片。
  ///
  /// 该方法调用图片选择器，并将选中的图片添加到当前列表中。
  Future<void> _pickGameImages() async {
    if (isLoading) return; // 父组件加载时阻止操作

    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(); // 唤起图片选择器选择多张图片

    if (images.isNotEmpty) {
      final newList = [...gameImagesSources, ...images]; // 将新图片添加到列表末尾
      onChanged(newList); // 通知父组件列表已更新
    }
  }

  /// 删除指定索引的图片。
  ///
  /// [index]：要删除图片的索引。
  /// 该方法从列表中移除图片并通知父组件。
  Future<void> _deleteImage(int index) async {
    if (isLoading) return; // 父组件加载时阻止操作
    if (index < 0 || index >= gameImagesSources.length) return; // 索引越界检查

    final newList = List<dynamic>.from(gameImagesSources); // 创建新列表
    newList.removeAt(index); // 移除指定索引的图片

    onChanged(newList); // 通知父组件列表已更新
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = DeviceUtils.isLandscape(context); // 判断是否为横屏
    final double imageWidth = isLandscape ? 120 : 160; // 图片宽度
    final double imageHeight = isLandscape ? 90 : 120; // 图片高度
    final double fontSize = isLandscape ? 14 : 16; // 字体大小
    final double iconSize = isLandscape ? 14 : 16; // 图标大小

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('游戏截图', style: TextStyle(fontSize: fontSize)), // 标题文本
            FunctionalButton(
              onPressed: isLoading ? null : _pickGameImages, // 加载时禁用按钮
              icon: Icons.add, // 添加图标
              iconSize: iconSize,
              label: '添加截图',
              isEnabled: !isLoading, // 根据加载状态设置按钮可用性
            ),
          ],
        ),
        if (gameImagesSources.isNotEmpty) // 图片列表不为空时显示
          Container(
            height: imageHeight + 8,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // 水平滚动
              itemCount: gameImagesSources.length,
              itemBuilder: (context, index) {
                if (index >= gameImagesSources.length) {
                  return const SizedBox.shrink();
                }
                final source = gameImagesSources[index];
                Widget imageWidget;

                if (source is XFile) {
                  imageWidget =
                      Image.file(File(source.path), // 从 XFile 创建 File 图片
                          width: imageWidth,
                          height: imageHeight,
                          fit: BoxFit.cover, errorBuilder: (ctx, err, st) {
                    return Container(
                        width: imageWidth,
                        height: imageHeight,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image));
                  });
                } else if (source is File) {
                  imageWidget = Image.file(source, // 直接使用 File 对象
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.cover, errorBuilder: (ctx, err, st) {
                    return Container(
                        width: imageWidth,
                        height: imageHeight,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image));
                  });
                } else if (source is String) {
                  final String displayUrl = source;
                  imageWidget = SafeCachedImage(
                    imageUrl: displayUrl, // 使用 URL 显示图片
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                  );
                } else {
                  imageWidget = Container(
                      width: imageWidth,
                      height: imageHeight,
                      color: Colors.grey[200],
                      child: const Icon(Icons.help_outline));
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
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
                              onTap: isLoading
                                  ? null
                                  : () => _deleteImage(index), // 加载时禁用删除
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
        else if (!isLoading) // 没有图片且不在加载时显示提示
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('暂无截图，点击 "添加截图" 上传。',
                style: TextStyle(color: Colors.grey[600])),
          ),
      ],
    );
  }
}
