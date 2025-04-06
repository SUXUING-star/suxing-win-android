// import 'dart:io'; // 这个文件不再需要 dart:io 或 XFile
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // 移除
// import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 移除
import '../../../../../models/announcement/announcement.dart';
// --- 直接调用 showAnnouncementDialog ---
import '../../../dialogs/announcement/announcement_dialog.dart'; // 导入修改后的 dialog

class AnnouncementPreviewScreen extends StatelessWidget {
  final AnnouncementFull announcementFormData; // 从表单传递的完整数据
  final dynamic imageSource; // 图片源 (XFile, String, or null)

  const AnnouncementPreviewScreen({
    Key? key,
    required this.announcementFormData, // 修改变量名以区分
    required this.imageSource,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- 创建临时的 Announcement 对象用于 Dialog ---
    // 这个对象主要用于传递非图片信息给 Dialog
    final Announcement previewDisplayData = Announcement(
      id: 'preview-id', // 预览不需要真实 ID
      title: announcementFormData.title,
      content: announcementFormData.content,
      type: announcementFormData.type,
      imageUrl: null, // imageUrl 设为 null，因为图片由 imageSource 控制
      actionUrl: announcementFormData.actionUrl,
      actionText: announcementFormData.actionText,
      // 使用表单的开始日期作为预览的日期，或者用 DateTime.now()
      date: announcementFormData.startDate,
      priority: announcementFormData.priority,
    );

    // --- 使用 Scaffold 包装，并在 build 完成后显示 Dialog ---
    // 这样可以确保 context 是有效的，并且 Dialog 出现在屏幕之上
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) { // 再次检查 context
        showAnnouncementDialog(
          context,
          previewDisplayData, // 传递临时的 Announcement 对象
          imageSource: imageSource, // !!! 传递当前的图片源 !!!
          onClose: () {
            // 当用户关闭预览对话框时，自动关闭预览屏幕
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
          barrierDismissible: true, // 允许点击外部关闭预览
        );
      }
    });

    // 返回一个简单的背景或占位符，因为主要内容是 Dialog
    return Scaffold(
      appBar: AppBar(
        title: const Text('公告预览'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '关闭预览',
        ),
        backgroundColor: Colors.transparent, // 让背景透明或匹配主题
        elevation: 0,
      ),
      backgroundColor: Colors.black.withOpacity(0.1), // 给屏幕一个轻微的遮罩感
      body: const Center(
        // 可以放一个加载指示器或提示文字
        // child: CircularProgressIndicator(),
        child: Text(
          '正在加载预览...',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );

    // 移除之前自己构建UI的逻辑
    /*
    return Scaffold(
      appBar: AppBar(...),
      body: Container(
        child: Column(
          children: [
            Container(...), // 预览信息栏
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: _buildPreviewDialogContent(context), // 移除
                ),
              ),
            ),
          ],
        ),
      ),
    );
    */
  }

// 移除所有内部构建 UI 的方法 (_buildInfoChip, _buildPreviewDialogContent, etc.)
// 移除 _formatDate 方法，因为 Dialog 内部会处理
}