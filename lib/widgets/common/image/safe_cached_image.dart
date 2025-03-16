// lib/widgets/common/safe_cached_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/network/url_utils.dart';

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
    Key? key,
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
  }) : super(key: key);

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
  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.grey[200],
      width: width,
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.image_not_supported_outlined,
              size: 32,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              '图片不可用',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}