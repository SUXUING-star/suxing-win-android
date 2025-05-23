// lib/widgets/common/robust_network_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 一个健壮的网络图片组件，处理错误情况并提供缓存支持
class RobustNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final String? heroTag;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final String defaultImage;

  /// 构造函数
  ///
  /// [imageUrl] 图片URL
  /// [width] 可选的宽度
  /// [height] 可选的高度
  /// [fit] 图片填充模式，默认为BoxFit.cover
  /// [borderRadius] 可选的圆角
  /// [errorWidget] 自定义错误组件
  /// [loadingWidget] 自定义加载组件
  /// [heroTag] 可选的Hero动画标签
  /// [onTap] 点击回调
  /// [backgroundColor] 背景颜色
  /// [defaultImage] 默认图片路径，用于所有情况失败时显示
  const RobustNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.loadingWidget,
    this.heroTag,
    this.onTap,
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.defaultImage = 'assets/images/image_placeholder.png',
  });

  @override
  Widget build(BuildContext context) {
    // 包装点击事件
    Widget contentWidget = _buildContentWidget(context);
    if (onTap != null) {
      contentWidget = GestureDetector(
        onTap: onTap,
        child: contentWidget,
      );
    }

    // 添加圆角
    if (borderRadius != null) {
      contentWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: contentWidget,
      );
    }

    return contentWidget;
  }

  Widget _buildContentWidget(BuildContext context) {
    // 处理空URL
    if (imageUrl.isEmpty) {
      return _buildErrorContainer(context);
    }

    // 处理URL编码，确保URL不包含未编码的特殊字符
    String safeUrl = _getSafeUrl(imageUrl);

    // 使用Hero动画
    Widget imageWidget = _buildCachedImage(context, safeUrl);
    if (heroTag != null) {
      imageWidget = Hero(
        tag: heroTag!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// 将URL转换为安全的格式
  String _getSafeUrl(String url) {
    try {
      // 解析URL
      Uri uri = Uri.parse(url);

      // 重新编码路径部分
      String newPath = uri.pathSegments.map((segment) {
        // 如果段已经包含%编码，则不再重新编码
        if (segment.contains('%')) return segment;
        return Uri.encodeComponent(segment);
      }).join('/');

      if (!newPath.startsWith('/')) {
        newPath = '/$newPath';
      }

      // 重建URL
      Uri safeUri = uri.replace(path: newPath);
      return safeUri.toString();
    } catch (e) {
      // print('URL编码错误: $e');
      // 如果解析失败，尝试简单的编码
      try {
        // 分离协议和主机部分
        int protocolEnd = url.indexOf('://');
        if (protocolEnd > 0) {
          String protocol = url.substring(0, protocolEnd + 3);
          String remaining = url.substring(protocolEnd + 3);

          // 分离主机和路径
          int pathStart = remaining.indexOf('/');
          if (pathStart > 0) {
            String host = remaining.substring(0, pathStart);
            String path = remaining.substring(pathStart);

            // 编码路径部分，保留"/"
            List<String> segments = path.split('/');
            String encodedPath = segments.map((segment) {
              if (segment.isEmpty) return '';
              return Uri.encodeComponent(segment);
            }).join('/');

            return '$protocol$host$encodedPath';
          }
        }
      } catch (e) {
        // print('简单URL编码失败: $e');
      }

      // 所有尝试都失败，返回原始URL
      return url;
    }
  }

  /// 构建CachedNetworkImage
  Widget _buildCachedImage(BuildContext context, String url) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildLoadingContainer(context),
      errorWidget: (context, url, error) {
        // print('图片加载错误[$url]: $error');
        return _buildErrorContainer(context);
      },
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
      memCacheHeight: height != null ? (height! * 2).toInt() : null,
    );
  }

  /// 构建加载状态的容器
  Widget _buildLoadingContainer(BuildContext context) {
    if (loadingWidget != null) {
      return loadingWidget!;
    }

    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  /// 构建错误状态的容器
  Widget _buildErrorContainer(BuildContext context) {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 尝试加载默认图片
          Image.asset(
            defaultImage,
            width: width,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // 默认图片也加载失败时显示图标
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '图片不可用',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 扩展提供快捷方法
extension RobustImageExtensions on String {
  /// 将字符串URL转换为RobustNetworkImage
  Widget toRobustImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return RobustNetworkImage(
      imageUrl: this,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      onTap: onTap,
    );
  }
}