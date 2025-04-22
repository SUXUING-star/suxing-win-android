// lib/widgets/ui/image/safe_cached_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/network/url_utils.dart';

/// 安全的缓存图片组件
///
/// 结合URL安全处理和CachedNetworkImage的功能
class SafeCachedImage extends StatelessWidget {
  /// 图片URL
  final String imageUrl;

  /// 图片宽度
  final double? width;

  /// 图片高度
  final double? height;

  /// 图片填充模式
  final BoxFit fit;

  /// 图片边框圆角
  final BorderRadius? borderRadius;

  /// 点击回调
  final VoidCallback? onTap;

  /// 图片加载错误回调
  final Function(String url, dynamic error)? onError;

  /// 内存缓存宽度
  final int? memCacheWidth;

  /// 内存缓存高度
  final int? memCacheHeight;

  /// 背景颜色
  final Color? backgroundColor;

  const SafeCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onTap,
    this.onError,
    this.memCacheWidth,
    this.memCacheHeight,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // 获取安全URL
    final safeUrl = UrlUtils.getSafeUrl(imageUrl);

    // 构建图片组件
    Widget imageWidget = CachedNetworkImage(
      imageUrl: safeUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => _buildPlaceholder(context),
      errorWidget: (context, url, error) {
        // 触发错误回调
        if (onError != null) {
          onError!(url, error);
        }
        return _buildErrorWidget(context);
      },
    );

    // 添加背景色
    if (backgroundColor != null) {
      imageWidget = Container(
        color: backgroundColor,
        width: width,
        height: height,
        child: imageWidget,
      );
    }

    // 添加圆角
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    // 添加点击事件
    if (onTap != null) {
      imageWidget = GestureDetector(
        onTap: onTap,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// 构建加载中占位符
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.grey[200],
      width: width,
      height: height,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  /// 构建错误占位符
  /// 构建错误占位符
  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      // 保留背景色、宽度、高度设置，让占位符和图片本身大小一致
      color: backgroundColor ?? Colors.grey[200],
      width: width,
      height: height,
      child: Center( // 让图片居中显示
        child: Image.asset(
          'assets/images/icons/main.png', // <-- 使用你的图片路径
          // 你可以根据需要调整图片的显示方式：
          fit: BoxFit.contain, // contain 会完整显示图片，可能会留白
          // cover 会填充满容器，可能会裁剪图片
          // scaleDown 如果图片比容器小，按原尺寸；如果大，则缩小以适应，类似 contain
          // 如果想给占位图一个固定的大小（不一定等于外层width/height），可以在这里设置
          // width: 32,
          // height: 32,
          // 可以给图片加点颜色蒙版，比如灰色，让它看起来更像占位符
          // color: Colors.grey.withOpacity(0.8),
          // colorBlendMode: BlendMode.srcATop, // 配合 color 使用
        ),
      ),
    );
  }
}