import 'dart:io'; // 导入 dart:io
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 导入 XFile
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

// 确认以下导入路径正确
import '../../../../models/announcement/announcement.dart';
import '../../../../services/main/announcement/announcement_service.dart';
import '../../../ui/buttons/functional_text_button.dart';
import '../../../ui/image/safe_cached_image.dart';
import '../../../ui/snackbar/app_snackbar.dart';

// --- 显示公告对话框的辅助函数 (修改：增加 imageSource 参数) ---
void showAnnouncementDialog(
  BuildContext context,
  Announcement announcement, {
  dynamic imageSource, // 新增：可选的图片源 (XFile or String)
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
              // --- 修改：传递 imageSource 给 AnnouncementDialog ---
              child: AnnouncementDialog(
                announcement: announcement,
                imageSource: imageSource, // 传递 imageSource
                onClose: onClose,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      // 动画保持不变
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

// --- _getAnnouncementBorderColor 函数 (保持不变) ---
Color _getAnnouncementBorderColor(ThemeData theme, String type) {
  switch (type) {
    case 'warning':
      return Colors.orange.shade500; // 使用稍亮的橙色
    case 'error':
      return theme.colorScheme.error; // 直接用主题错误色
    case 'success':
      return Colors.green.shade500; // 稍亮的绿色
    case 'update':
      return Colors.blue.shade500; // 稍亮蓝色
    case 'event':
      return Colors.purple.shade400; // 稍亮紫色
    default: // info 或未知
      // 默认给一个比较柔和的主题色或灰色边框
      return theme.colorScheme.primary.withSafeOpacity(0.7);
    // 或者 return theme.dividerColor.withSafeOpacity(0.9);
  }
}

// --- AnnouncementDialog Widget (修改：增加 imageSource 参数，修改 _buildImage) ---
class AnnouncementDialog extends StatelessWidget {
  final Announcement announcement;
  final dynamic imageSource; // 新增：可选图片源
  final VoidCallback? onClose;

  const AnnouncementDialog({
    super.key,
    required this.announcement,
    this.imageSource, // 新增
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color iconColor = _getTypeIconColor(theme, announcement.type);

    final fileUploadService = context.read<RateLimitedFileUpload>();

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
                  // --- 修改：调用新的图片构建方法 ---
                  _buildImage(context, fileUploadService), // 不再传递 imageUrl
                  // 根据是否有图片决定是否添加间距
                  if (_shouldShowImage()) const SizedBox(height: 20),
                  _buildContent(context, theme),
                  const SizedBox(height: 24),
                  if (announcement.actionUrl != null &&
                      announcement.actionText != null)
                    _buildActionButton(context, theme),
                  // 如果没有按钮，但有内容，也加点底部间距
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

  // --- 构建头部 (保持不变) ---
  Widget _buildHeader(BuildContext context, ThemeData theme, Color iconColor) {
    // ... (代码不变) ...
    final Color titleColor = theme.colorScheme.onSurface;
    final Color closeButtonColor =
        theme.colorScheme.onSurfaceVariant.withSafeOpacity(0.8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 12.0, 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_getTypeIcon(announcement.type),
              color: iconColor, size: 26), // 传递 type
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
            tooltip: "关闭", // Tooltip 使用中文
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

  // --- 判断是否应该显示图片 ---
  bool _shouldShowImage() {
    if (imageSource is XFile) return true;
    if (imageSource is String && (imageSource as String).isNotEmpty) {
      return true;
    }
    // 如果 imageSource 为空，则检查 announcement.imageUrl
    if (imageSource == null &&
        announcement.imageUrl != null &&
        announcement.imageUrl!.isNotEmpty) {
      return true;
    }
    return false;
  }

  // --- 构建图片 (修改：优先使用 imageSource) ---
  Widget _buildImage(
      BuildContext context, RateLimitedFileUpload fileUploadService) {
    Widget imageWidget;
    final source = imageSource; // 获取传入的 source

    if (source is XFile) {
      // 显示本地 XFile
      imageWidget = Image.file(
        File(source.path),
        fit: BoxFit.contain, // Contain 可能更适合对话框
        errorBuilder: (context, error, stackTrace) =>
            _buildImageErrorPlaceholder('本地图片加载失败'),
      );
    } else if (source is String && source.isNotEmpty) {
      // 显示网络 URL (来自 imageSource)
      final String displayUrl = source.startsWith('http')
          ? source
          : '${fileUploadService.baseUrl}/$source';
      imageWidget = SafeCachedImage(
        imageUrl: displayUrl,
        fit: BoxFit.contain,
      );
    } else if (announcement.imageUrl != null &&
        announcement.imageUrl!.isNotEmpty) {
      // imageSource 为空，但 announcement.imageUrl 存在
      final String displayUrl = announcement.imageUrl!.startsWith('http')
          ? announcement.imageUrl!
          : '${fileUploadService.baseUrl}/${announcement.imageUrl!}';
      imageWidget = SafeCachedImage(
        imageUrl: displayUrl,
        fit: BoxFit.contain,
      );
    } else {
      // 没有图片源，返回空 SizedBox
      return const SizedBox.shrink();
    }

    // 返回带约束和圆角的图片容器
    return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250), // 保持最大高度约束
        child: ClipRRect(
          // 添加圆角
          borderRadius: BorderRadius.circular(12.0),
          child: imageWidget,
        ));
  }

  // 辅助方法：图片错误占位符
  Widget _buildImageErrorPlaceholder(String message) {
    return Container(
      // height: 150, // 可以给个固定高度
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

  // --- 构建内容区域 (保持不变) ---
  Widget _buildContent(BuildContext context, ThemeData theme) {
    // ... (代码不变) ...
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

  // --- 构建动作按钮 (保持不变) ---
  Widget _buildActionButton(BuildContext context, ThemeData theme) {
    // ... (代码不变) ...
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
          // ... (省略 launch url 逻辑，保持不变) ...
          if (announcement.actionUrl != null) {
            final Uri url = Uri.parse(announcement.actionUrl!);
            try {
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  AppSnackBar.showWarning(context, '无法打开链接');
                }
              }
            } catch (e) {
              if (context.mounted) {
                AppSnackBar.showError(context, '打开链接失败');
              }
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

  // --- 构建底部 (保持不变) ---
  Widget _buildFooter(BuildContext context, ThemeData theme) {
    final Color footerTextColor = theme.colorScheme.onSurfaceVariant;
    final Color dividerColor = theme.dividerColor.withSafeOpacity(0.5);
    final Color buttonCustomColor = theme.colorScheme.secondary; // 直接用次要色

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

  // --- Helper 方法 (保持不变) ---
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
    final announcementService = context.read<AnnouncementService>();
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
    Color defaultColor = theme.colorScheme.secondary; // 默认用次要颜色

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
        return defaultColor; // info 或未知
    }
  }
}
