// lib/widgets/components/form/gameform/field/cover_image_field.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../ui/buttons/app_button.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../ui/image/safe_cached_image.dart';
import 'dialogs/image_url_dialog.dart';

class CoverImageField extends StatelessWidget {
  final dynamic coverImageSource;
  final ValueChanged<dynamic> onChanged;
  final bool isLoading; // 父组件加载状态

  const CoverImageField({
    super.key,
    this.coverImageSource,
    required this.onChanged,
    required this.isLoading,
  });

  Future<void> _pickCoverImage(BuildContext context) async {
    if (isLoading) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      onChanged(image);
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isLandscape = DeviceUtils.isLandscape(context);
    final double verticalSpacing = isLandscape ? 4.0 : 8.0;
    final double fontSize = isLandscape ? 14.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('封面图片', style: TextStyle(fontSize: fontSize)),
        SizedBox(height: verticalSpacing),
        Row(
          children: [
            Expanded(
              // 使用 Expanded 让按钮填充可用空间
              child: AppButton(
                icon: const Icon(Icons.upload_file), // 传入图标
                text: '本地图片',
                // 注意 onPressed 需要一个无参数回调
                onPressed: () => _pickCoverImage(context),
                isDisabled: isLoading, // 根据父组件状态禁用
                isPrimaryAction: true,
              ),
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
    final source = coverImageSource;

    if (source == null || (source is String && source.isEmpty)) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Colors.grey),
            Text('请添加封面图片')
          ],
        ),
      );
    }

    Widget imageWidget;
    if (source is XFile) {
      print("Cover Preview: Rendering XFile: ${source.path}");
      imageWidget = Image.file(
        File(source.path), // <--- 从 XFile 创建 File
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error rendering XFile preview ${source.path}: $error");
          return const Center(
              child:
                  Icon(Icons.broken_image, size: 48, color: Colors.redAccent));
        },
      );
    } else if (source is File) {
      // <--- 新增: 处理 File 对象
      print("Cover Preview: Rendering File: ${source.path}");
      imageWidget = Image.file(
        source, // <--- 直接使用 File 对象
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error rendering File preview ${source.path}: $error");
          return const Center(
              child:
                  Icon(Icons.broken_image, size: 48, color: Colors.redAccent));
        },
      );
    } else if (source is String) {
      print("Cover Preview: Rendering String URL: $source");
      final imageUrl = source;
      // 不需要再拼接 baseUrl，因为存的时候已经是完整路径或 URL
      final String displayUrl = imageUrl;
      imageWidget = SafeCachedImage(
        imageUrl: displayUrl,
        fit: BoxFit.cover,
      );
    } else {
      print("Cover Preview: Unknown source type: ${source.runtimeType}");
      imageWidget = const Center(child: Icon(Icons.help_outline, size: 48));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(7.0), // 应用圆角
      child: imageWidget,
    );
  }
}
