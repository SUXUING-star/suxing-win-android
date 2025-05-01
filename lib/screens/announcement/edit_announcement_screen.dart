// lib/screens/admin/widgets/announcement_management/edit_announcement_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../models/announcement/announcement.dart';
import '../../../../services/main/announcement/announcement_service.dart';
import '../../../../widgets/components/form/announcementform/announcement_form.dart';

class EditAnnouncementScreen extends StatelessWidget {
  final AnnouncementFull announcement;


  EditAnnouncementScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final announcementService = context.read<AnnouncementService>();
    return Scaffold(
      appBar: CustomAppBar(title: announcement.id.isEmpty ? '创建新公告' : '编辑公告'),
      body: AnnouncementForm(
        announcement: announcement,
        onSubmit: (AnnouncementFull updatedAnnouncement) async {
          try {
            if (announcement.id.isEmpty) {
              // 创建新公告
              await announcementService
                  .createAnnouncement(updatedAnnouncement);
              if (context.mounted) {
                AppSnackBar.showSuccess(context, '新公告已创建');
              }
            } else {
              // 更新现有公告
              await announcementService.updateAnnouncement(
                  announcement.id, updatedAnnouncement);
              if (context.mounted) {
                AppSnackBar.showSuccess(context, '公告已更新');
              }
            }

            if (context.mounted) {
              Navigator.of(context).pop(true); // 返回 true 表示成功
            }
          } catch (e) {
            if (context.mounted) {
              AppSnackBar.showError(context, '操作失败: $e');
            }
          }
        },
        onCancel: () {
          Navigator.of(context).pop(false); // 返回 false 表示取消
        },
      ),
    );
  }
}
