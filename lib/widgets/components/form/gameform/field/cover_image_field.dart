// lib/widgets/components/form/gameform/field/cover_image_field.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// 确认导入 AppButton
import '../../../../ui/buttons/app_button.dart';
// 其他必要的 import
import '../../../../../services/common/upload/file_upload_service.dart';
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

  Future<void> _showUrlDialog(BuildContext context) async {
    if (isLoading) return;
    final currentUrl = coverImageSource is String ? coverImageSource as String : '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => ImageUrlDialog(initialUrl: currentUrl),
    );
    if (result != null && result != currentUrl) {
      onChanged(result);
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
          // 让按钮自动分配空间可能更好看
          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // --- 使用 AppButton 替换本地图片按钮 ---
            Expanded( // 使用 Expanded 让按钮填充可用空间
              child: AppButton(
                icon: const Icon(Icons.upload_file), // 传入图标
                text: '本地图片',
                // 注意 onPressed 需要一个无参数回调
                onPressed: () => _pickCoverImage(context),
                isDisabled: isLoading, // 根据父组件状态禁用
                isPrimaryAction: true,
              ),
            ),
            const SizedBox(width: 12), // 按钮间距

            // --- 使用 AppButton 替换图片链接按钮 ---
            Expanded( // 使用 Expanded
              child: AppButton(
                icon: const Icon(Icons.link), // 传入图标
                text: '图片链接',
                onPressed: () => _showUrlDialog(context),
                isDisabled: isLoading,
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
    // ... (_buildCoverPreview 方法保持不变) ...
    final source = coverImageSource;
    if (source == null || (source is String && source.isEmpty)) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ Icon(Icons.image_outlined, size: 48, color: Colors.grey), Text('请添加封面图片') ],
        ),
      );
    }
    Widget imageWidget;
    if (source is XFile) {
      imageWidget = Image.file(
        File(source.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("本地封面预览错误: ${source.path}, $error");
          return const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.redAccent));
        },
      );
    } else if (source is String) {
      final imageUrl = source;
      final String displayUrl = imageUrl.startsWith('http') ? imageUrl : '${FileUpload.baseUrl}/$imageUrl';
      imageWidget = SafeCachedImage(
        imageUrl: displayUrl,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = const Center(child: Icon(Icons.help_outline, size: 48));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(7.0),
      child: imageWidget,
    );
  }
}