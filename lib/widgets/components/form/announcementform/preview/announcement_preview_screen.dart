// lib/widgets/components/form/announcementform/preview/announcement_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/announcement/announcement.dart';
import '../../../dialogs/announcement/announcement_dialog.dart';

class AnnouncementPreviewScreen extends StatelessWidget {
  final AnnouncementFull announcement;

  const AnnouncementPreviewScreen({
    Key? key,
    required this.announcement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 将AnnouncementFull转换为Announcement用于预览
    final previewAnnouncement = Announcement(
      id: announcement.id.isEmpty ? 'preview-id' : announcement.id,
      title: announcement.title,
      content: announcement.content,
      type: announcement.type,
      imageUrl: announcement.imageUrl,
      actionUrl: announcement.actionUrl,
      actionText: announcement.actionText,
      date: announcement.startDate, // 使用开始日期作为发布日期
      priority: announcement.priority,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('公告预览'),
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text('返回编辑', style: TextStyle(color: Colors.white)),
            onPressed: () => NavigationUtils.of(context).pop(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade200,
            ],
          ),
        ),
        child: Column(
          children: [
            // 预览信息栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.amber.withOpacity(0.2),
              child: Column(
                children: [
                  const Text(
                    '预览模式 - 这是用户将看到的公告效果',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (announcement.isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '公告已激活',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '公告未激活 - 用户看不到',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '显示时间: ${_formatDate(announcement.startDate)} 至 ${_formatDate(announcement.endDate)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '优先级: ${announcement.priority}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // 预览对话框
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: AnnouncementDialog(
                    announcement: previewAnnouncement,
                    onClose: () {
                      // 预览模式下不需要真正关闭
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => NavigationUtils.of(context).pop(),
        label: const Text('返回继续编辑'),
        icon: const Icon(Icons.edit),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}