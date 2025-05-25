// lib/widgets/components/indicators/announcement_indicator.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/announcement/announcement.dart';
import 'package:suxingchahui/widgets/components/dialogs/announcement/announcement_dialog.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/services/main/announcement/announcement_service.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';

bool _isDialogSequenceActive = false;

class AnnouncementIndicator extends StatelessWidget {
  final AuthProvider authProvider;
  final AnnouncementService announcementService;

  const AnnouncementIndicator({
    super.key,
    required this.announcementService,
    required this.authProvider,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (_isDialogSequenceActive) {
      return;
    }

    try {
      await announcementService.getActiveAnnouncements(forceRefresh: false);
      final unread = announcementService.getUnreadAnnouncements();

      if (!context.mounted) return;
      if (unread.isNotEmpty) {
        _showAnnouncementsDialogs(context, unread);
      } else {
        if (context.mounted) AppSnackBar.showInfo(context, '没有新的公告');
      }
    } catch (e) {
      if (context.mounted) AppSnackBar.showError(context, '获取公告失败');
    }
  }

  void _showAnnouncementsDialogs(
      BuildContext context, List<Announcement> announcementsToShow) async {
    if (!context.mounted || announcementsToShow.isEmpty) {
      _isDialogSequenceActive = false;
      return;
    }

    _isDialogSequenceActive = true;
    try {
      for (int i = 0; i < announcementsToShow.length; i++) {
        if (!context.mounted) {
          _isDialogSequenceActive = false;
          return;
        }
        final announcement = announcementsToShow[i];
        bool continueToNext =
            await _showSingleAnnouncementDialog(context, announcement);
        if (!continueToNext || !context.mounted) {
          _isDialogSequenceActive = false;
          return;
        }
        if (i < announcementsToShow.length - 1 && context.mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } finally {
      _isDialogSequenceActive = false;
    }
  }

  Future<bool> _showSingleAnnouncementDialog(
      BuildContext context, Announcement announcement) async {
    final completer = Completer<bool>();
    if (!context.mounted) {
      completer.complete(false);
      return completer.future;
    }

    showAnnouncementDialog(
      context,
      announcementService,
      announcement,
      onClose: () async {
        if (context.mounted) {
          await announcementService.markAsRead(announcement.id);
        }
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AnnouncementIndicatorData>(
      stream: announcementService.indicatorDataStream,
      initialData: AnnouncementIndicatorData.initial(),
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (snapshot.hasError || data == null) {
          return GestureDetector(
            onTap: () => _handleTap(context),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.campaign_outlined,
                    size: 16, color: Colors.white),
              ),
            ),
          );
        }

        if (data.isLoading && data.unreadCount == 0) {
          return SizedBox(
              width: 24, height: 24, child: LoadingWidget.inline(size: 12));
        }

        if (data.unreadCount > 0) {
          return GestureDetector(
            onTap: () => _handleTap(context),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  data.unreadCount > 9 ? '9+' : '${data.unreadCount}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _handleTap(context),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.lightGreen[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.campaign, size: 16, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
