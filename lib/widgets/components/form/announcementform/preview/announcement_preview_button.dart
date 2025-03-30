// lib/widgets/components/form/announcementform/preview/announcement_preview_button.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/announcement/announcement.dart';
import 'announcement_preview_screen.dart';

class AnnouncementPreviewButton extends StatelessWidget {
  final AnnouncementFull announcement;
  final bool isLoading;

  const AnnouncementPreviewButton({
    Key? key,
    required this.announcement,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading
          ? null
          : () {
        NavigationUtils.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnnouncementPreviewScreen(
              announcement: announcement,
            ),
            fullscreenDialog: true,
          ),
        );
      },
      icon: const Icon(Icons.preview),
      label: const Text('预览公告'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}