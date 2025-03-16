// lib/widgets/dialogs/announcement_dialog.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/announcement/announcement.dart';
import '../../../../services/main/announcement/announcement_service.dart';

class AnnouncementDialog extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onClose;

  const AnnouncementDialog({
    Key? key,
    required this.announcement,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color borderColor = _getTypeColor(theme);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2),
      ),
      elevation: 10,
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (announcement.imageUrl != null) _buildImage(),
                    const SizedBox(height: 16),
                    Text(
                      announcement.content,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    if (announcement.actionUrl != null && announcement.actionText != null)
                      _buildActionButton(context),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final Color backgroundColor = _getHeaderColor(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getTypeIcon(),
            color: theme.colorScheme.onPrimary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              announcement.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onPrimary,
            ),
            onPressed: () {
              _markAsRead();
              Navigator.of(context).pop();
              if (onClose != null) onClose!();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
      ),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          announcement.imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 40),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 100,
              color: Colors.grey[100],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _getButtonColor(theme),
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () async {
          if (announcement.actionUrl != null) {
            final Uri url = Uri.parse(announcement.actionUrl!);
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          }
        },
        child: Text(
          announcement.actionText ?? '详情',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '发布日期: ${_formatDate(announcement.date)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: () {
              _markAsRead();
              Navigator.of(context).pop();
              if (onClose != null) onClose!();
            },
            child: const Text('不再显示'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _markAsRead() {
    AnnouncementService().markAsRead(announcement.id);
  }

  IconData _getTypeIcon() {
    switch (announcement.type) {
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'success':
        return Icons.check_circle;
      case 'update':
        return Icons.system_update;
      case 'event':
        return Icons.event;
      default: // 'info'
        return Icons.info;
    }
  }

  Color _getHeaderColor(ThemeData theme) {
    switch (announcement.type) {
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'event':
        return Colors.purple;
      default: // 'info'
        return theme.colorScheme.primary;
    }
  }

  Color _getTypeColor(ThemeData theme) {
    switch (announcement.type) {
      case 'warning':
        return Colors.orange.shade300;
      case 'error':
        return Colors.red.shade300;
      case 'success':
        return Colors.green.shade300;
      case 'update':
        return Colors.blue.shade300;
      case 'event':
        return Colors.purple.shade300;
      default: // 'info'
        return theme.colorScheme.primary.withOpacity(0.5);
    }
  }

  Color _getButtonColor(ThemeData theme) {
    switch (announcement.type) {
      case 'warning':
        return Colors.orange.shade700;
      case 'error':
        return Colors.red.shade700;
      case 'success':
        return Colors.green.shade700;
      case 'update':
        return Colors.blue.shade700;
      case 'event':
        return Colors.purple.shade700;
      default: // 'info'
        return theme.colorScheme.primary;
    }
  }
}

// 辅助函数: 显示公告对话框
void showAnnouncementDialog(
    BuildContext context,
    Announcement announcement,
    {VoidCallback? onClose}
    ) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AnnouncementDialog(
      announcement: announcement,
      onClose: onClose,
    ),
  );
}