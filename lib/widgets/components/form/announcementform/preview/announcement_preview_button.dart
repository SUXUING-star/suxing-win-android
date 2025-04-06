import 'package:flutter/material.dart';
// 移除 navigation_utils，如果只用 Navigator.push
// import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/announcement/announcement.dart';
import 'announcement_preview_screen.dart'; // 保持导入

class AnnouncementPreviewButton extends StatelessWidget {
  final AnnouncementFull announcement; // 当前表单数据
  final dynamic imageSourceForPreview; // 新增：接收当前图片源
  final bool isLoading;

  const AnnouncementPreviewButton({
    Key? key,
    required this.announcement,
    required this.imageSourceForPreview, // 新增：设为 required
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 按钮样式可以保持或调整
    return OutlinedButton.icon( // 使用 OutlinedButton 可能更适合预览
      onPressed: isLoading
          ? null
          : () {
        // 使用标准 Navigator.push
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnnouncementPreviewScreen(
              // 传递表单数据和当前的图片源
              announcementFormData: announcement,
              imageSource: imageSourceForPreview, // 传递 imageSource
            ),
            fullscreenDialog: true, // 保持全屏对话框样式
          ),
        );
      },
      icon: const Icon(Icons.visibility_outlined), // 使用 visibility 图标
      label: const Text('预览'), // 简化文字
      style: OutlinedButton.styleFrom( // 调整样式以匹配其他按钮
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}