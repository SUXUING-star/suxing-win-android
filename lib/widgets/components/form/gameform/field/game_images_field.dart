// lib/widgets/form/gameform/field/game_images_field.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:suxingchahui/widgets/ui/buttons/app_button.dart';
import 'dart:io';
import '../../../../../services/common/upload/file_upload_service.dart'; // 可能需要基础 URL
import '../../../../../utils/device/device_utils.dart';
import '../../../../ui/image/safe_cached_image.dart'; // 确认路径

class GameImagesField extends StatelessWidget {
  // --- 属性修改 ---
  final List<dynamic> gameImagesSources; // List<String or XFile>
  final ValueChanged<List<dynamic>> onChanged; // 回调传递更新后的完整列表
  final bool isLoading; // 从父组件接收的加载状态
  // 移除了内部 onLoadingChanged 和 initialGameImages

  const GameImagesField({
    Key? key,
    required this.gameImagesSources,
    required this.onChanged,
    required this.isLoading, // 父组件的加载状态
  }) : super(key: key);

  // 选择多张本地图片
  Future<void> _pickGameImages() async {
    if (isLoading) return; // 父组件加载时禁用

    final ImagePicker picker = ImagePicker();
    // 选择多张图片
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      // 将新选的 XFile 添加到现有列表末尾
      final newList = [...gameImagesSources, ...images];
      onChanged(newList); // 将包含新 XFile 的完整列表传递给父组件
    }
  }

  // 删除指定索引的图片（可能是 URL 或 XFile）
  Future<void> _deleteImage(int index) async {
    if (isLoading) return; // 父组件加载时禁用
    if (index < 0 || index >= gameImagesSources.length) return;

    // 获取要删除的源（可能是 String 或 XFile）
    final sourceToDelete = gameImagesSources[index];

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
            AppButton(
              // 父组件加载时禁用按钮
              onPressed: isLoading ? null : _pickGameImages,
              icon: Icon(Icons.add, size: iconSize),
              text: '添加截图',
              isMini: true,
              isPrimaryAction: true,
            ),
          ],
        ),
        // 图片列表预览
        if (gameImagesSources.isNotEmpty)
          Container(
            height: imageHeight + 8, // 稍微增加高度以容纳内边距或阴影
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: gameImagesSources.length,
              itemBuilder: (context, index) {
                if (index >= gameImagesSources.length) return const SizedBox.shrink(); // 安全检查
                final source = gameImagesSources[index];
                Widget imageWidget;

                // 根据源类型创建预览 Widget
                if (source is XFile) {
                  imageWidget = Image.file(
                    File(source.path),
                    width: imageWidth, height: imageHeight, fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(width: imageWidth, height: imageHeight, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                  );
                } else if (source is String) {
                  final imageUrl = source;
                  final String displayUrl = imageUrl.startsWith('http') ? imageUrl : '${FileUpload.baseUrl}/$imageUrl'; // 调整 URL 构造
                  imageWidget = SafeCachedImage(
                    imageUrl: displayUrl,
                    width: imageWidth, height: imageHeight, fit: BoxFit.cover,
                  );
                } else {
                  // 未知类型占位符
                  imageWidget = Container(width: imageWidth, height: imageHeight, color: Colors.grey[200], child: const Icon(Icons.help_outline));
                }

                // 使用 Stack 添加删除按钮
                return Padding(
                  padding: EdgeInsets.only(right: 8.0), // 图片间距
                  child: Stack(
                    clipBehavior: Clip.none, // 允许删除按钮稍微超出边界
                    children: [
                      ClipRRect( // 图片圆角
                        borderRadius: BorderRadius.circular(4.0),
                        child: imageWidget,
                      ),
                      // 删除按钮 (右上角)
                      Positioned(
                          top: -4, // 微调位置
                          right: 0,  // 微调位置
                          child: Material( // 添加 Material 实现水波纹效果
                            type: MaterialType.transparency,
                            child: InkWell(
                              // 父组件加载时禁用删除
                              onTap: isLoading ? null : () => _deleteImage(index),
                              borderRadius: BorderRadius.circular(12), // 水波纹范围
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, size: iconSize, color: Colors.white),
                              ),
                            ),
                          )
                      ),
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
            child: Text('暂无截图，点击 "添加截图" 上传。', style: TextStyle(color: Colors.grey[600])),
          ),
      ],
    );
  }
}