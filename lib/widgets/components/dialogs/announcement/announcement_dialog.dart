import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:suxingchahui/models/announcement/announcement.dart';
import 'package:suxingchahui/services/main/announcement/announcement_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

void showAnnouncementDialog(
  BuildContext context,
  AnnouncementService announcementService,
  Announcement announcement, {
  dynamic imageSource,
  VoidCallback? onClose,
  bool barrierDismissible = false,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Curve transitionCurve = Curves.fastOutSlowIn,
}) {
  final ThemeData theme = Theme.of(context);
  final Color borderColor =
      _getAnnouncementBorderColor(theme, announcement.type);

  showGeneralDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withSafeOpacity(0.4),
    transitionDuration: transitionDuration,
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.dialogBackgroundColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: borderColor, width: 2.5),
              ),
              child: AnnouncementDialog(
                announcementService: announcementService,
                announcement: announcement,
                imageSource: imageSource,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      return ScaleTransition(
        scale: CurvedAnimation(
            parent: animation,
            curve: transitionCurve,
            reverseCurve: Curves.easeOutCubic),
        child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child),
      );
    },
  );
}

Color _getAnnouncementBorderColor(ThemeData theme, String type) {
  switch (type) {
    case 'warning':
      return Colors.orange.shade500;
    case 'error':
      return theme.colorScheme.error;
    case 'success':
      return Colors.green.shade500;
    case 'update':
      return Colors.blue.shade500;
    case 'event':
      return Colors.purple.shade400;
    default:
      return theme.colorScheme.primary.withSafeOpacity(0.7);
  }
}

class AnnouncementDialog extends StatelessWidget {
  final Announcement announcement;
  final AnnouncementService announcementService;
  final dynamic imageSource;
  final VoidCallback? onClose;

  const AnnouncementDialog({
    super.key,
    required this.announcement,
    required this.announcementService,
    this.imageSource,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color iconColor = _getTypeIconColor(theme, announcement.type);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, theme, iconColor),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildImageWidget(context),
                  if (_shouldShowImage()) const SizedBox(height: 20),
                  _buildContent(context, theme),
                  const SizedBox(height: 24),
                  if (announcement.actionUrl != null &&
                      announcement.actionText != null)
                    _buildActionButton(context, theme),
                  if (!(announcement.actionUrl != null &&
                          announcement.actionText != null) &&
                      announcement.content.isNotEmpty)
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildFooter(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, Color iconColor) {
    final Color titleColor = theme.colorScheme.onSurface;
    final Color closeButtonColor =
        theme.colorScheme.onSurfaceVariant.withSafeOpacity(0.8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 12.0, 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_getTypeIcon(announcement.type), color: iconColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              announcement.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close_rounded, color: closeButtonColor),
            tooltip: "关闭",
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _closeDialog(context),
          ),
        ],
      ),
    );
  }

  bool _shouldShowImage() {
    if (imageSource is XFile) return true;
    if (imageSource is String && (imageSource as String).isNotEmpty) {
      return true;
    }
    return announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty;
  }

  Widget _buildImageWidget(BuildContext context) {
    Widget imageContent;
    final currentImageSource = imageSource;

    if (currentImageSource is XFile) {
      imageContent = Image.file(
        File(currentImageSource.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildImageErrorPlaceholder('本地图片加载失败'),
      );
    } else if (currentImageSource is String && currentImageSource.isNotEmpty) {
      imageContent = SafeCachedImage(
        imageUrl: currentImageSource,
        fit: BoxFit.contain,
      );
    } else if (announcement.imageUrl != null &&
        announcement.imageUrl!.isNotEmpty) {
      imageContent = SafeCachedImage(
        imageUrl: announcement.imageUrl!,
        fit: BoxFit.contain,
      );
    } else {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: imageContent,
      ),
    );
  }

  Widget _buildImageErrorPlaceholder(String message) {
    return Container(
      color: Colors.red.shade50,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 36),
              const SizedBox(height: 4),
              Text(message,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    final Color contentColor = theme.colorScheme.onSurface.withSafeOpacity(0.8);
    final Color placeholderColor = theme.colorScheme.onSurfaceVariant;

    if (announcement.content.isNotEmpty) {
      return Text(
        announcement.content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: contentColor,
          height: 1.6,
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30.0),
          child: Text(
            '(暂无详细内容)',
            style:
                theme.textTheme.bodyMedium?.copyWith(color: placeholderColor),
          ),
        ),
      );
    }
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme) {
    final Color buttonBackgroundColor = theme.colorScheme.primary;
    final Color buttonTextColor = theme.colorScheme.onPrimary;

    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackgroundColor,
          foregroundColor: buttonTextColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          elevation: 2,
          shadowColor: buttonBackgroundColor.withSafeOpacity(0.4),
        ),
        onPressed: () async {
          if (announcement.actionUrl != null) {
            final Uri url = Uri.parse(announcement.actionUrl!);
            try {
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                AppSnackBar.showWarning('无法打开链接');
              }
            } catch (e) {
              AppSnackBar.showError("操作失败,${e.toString()}");
            }
          }
        },
        child: Text(
          announcement.actionText ?? '查看详情',
          style: theme.textTheme.labelLarge?.copyWith(
            color: buttonTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    final Color footerTextColor = theme.colorScheme.onSurfaceVariant;
    final Color dividerColor = theme.dividerColor.withSafeOpacity(0.5);
    final Color buttonCustomColor = theme.colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '发布于: ${_formatDate(announcement.date)}',
            style: theme.textTheme.bodySmall?.copyWith(color: footerTextColor),
          ),
          FunctionalTextButton(
            label: '不再显示',
            onPressed: () => _closeDialog(context, markAsRead: true),
            foregroundColor: buttonCustomColor,
            fontSize: 14.0,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ],
      ),
    );
  }

  void _closeDialog(BuildContext context, {bool markAsRead = false}) {
    if (markAsRead) {
      _markAsRead(context);
    }
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    onClose?.call();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _markAsRead(BuildContext context) async {
    await announcementService.markAsRead(announcement.id);
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      case 'success':
        return Icons.check_circle_outline_rounded;
      case 'update':
        return Icons.system_update_alt_rounded;
      case 'event':
        return Icons.event_available_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getTypeIconColor(ThemeData theme, String type) {
    Color defaultColor = theme.colorScheme.secondary;
    switch (type) {
      case 'warning':
        return Colors.orange.shade600;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green.shade600;
      case 'update':
        return Colors.blue.shade600;
      case 'event':
        return Colors.purple.shade500;
      default:
        return defaultColor;
    }
  }
}
