// lib/screens/admin/widgets/announcement_management/edit_announcement_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../models/announcement/announcement.dart';
import '../../../../services/main/announcement/announcement_service.dart';
import '../../../../widgets/components/form/announcementform/announcement_form.dart';

class EditAnnouncementScreen extends StatelessWidget {
  final AnnouncementFull announcement;
  final AnnouncementService _announcementService = AnnouncementService();

  EditAnnouncementScreen({Key? key, required this.announcement})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: announcement.id.isEmpty ? '创建新公告' : '编辑公告'),
      body: AnnouncementForm(
        announcement: announcement,
        onSubmit: (AnnouncementFull updatedAnnouncement) async {
          try {
            if (announcement.id.isEmpty) {
              // 创建新公告
              await _announcementService
                  .createAnnouncement(updatedAnnouncement);
              if (context.mounted) {
                AppSnackBar.showSuccess(context, '新公告已创建');
              }
            } else {
              // 更新现有公告
              await _announcementService.updateAnnouncement(
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
