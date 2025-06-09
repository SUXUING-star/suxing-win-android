// lib/widgets/ui/text/app_text.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/font/font_config.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'app_text_type.dart';

class AppText extends StatelessWidget {
  final String data;
  final AppTextType type;

  // --- 直接暴露的常用样式参数 ---
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;
  final FontStyle? fontStyle;
  final double? letterSpacing;
  final double? height;
  final TextDecoration? decoration;
  final Color? decorationColor;
  final TextDecorationStyle? decorationStyle;
  final double? decorationThickness;

  // --- Text 的所有原生参数，一个不漏 ---

  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  // --- 你自己的“高级操作”参数 ---
  final IconData? prefixIcon;
  final double iconSpacing;

  const AppText(
      this.data, {
        super.key,
        this.type = AppTextType.body,
        // --- 直接样式参数 ---
        this.color,
        this.fontWeight,
        this.fontSize,
        this.fontStyle,
        this.letterSpacing,
        this.height,
        this.decoration,
        this.decorationColor,
        this.decorationStyle,
        this.decorationThickness,
        // --- 其他参数 ---
        this.style, // <-- 仍然可选，作为最终覆盖
        this.strutStyle,
        this.textAlign,
        this.textDirection,
        this.locale,
        this.softWrap,
        this.overflow,
        this.textScaleFactor,
        this.textScaler,
        this.maxLines,
        this.semanticsLabel,
        this.textWidthBasis,
        this.textHeightBehavior,
        this.selectionColor,
        this.prefixIcon,
        this.iconSpacing = 4.0,
      });

  @override
  Widget build(BuildContext context) {
    // 1. 根据 type 获取基础样式
    final TextStyle styleFromType = _getStyleForType(context, type);

    // 2. 应用 FontConfig 字体 (作为基础，除非被覆盖)
    // 注意：这里先应用字体，后续直接参数和 style 可以覆盖它
    TextStyle currentStyle = styleFromType.copyWith(
      fontFamily: FontConfig.defaultFontFamily,
      fontFamilyFallback: FontConfig.fontFallback,
    );

    // 3. 应用直接传入的样式参数 (覆盖 type 和 FontConfig 的对应属性)
    //    使用 copyWith，只有当传入参数不为 null 时才会覆盖
    currentStyle = currentStyle.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );

    // 4. 合并外部传入的 style (最高优先级，覆盖前面所有步骤的样式)
    //    如果 style 为 null，merge 不会做任何事
    final TextStyle effectiveStyle = currentStyle.merge(style);

    // --- 处理缩放因子 ---
    final scaler = textScaler ?? (textScaleFactor != null ? TextScaler.linear(textScaleFactor!) : null);

    // --- 构建基础 Text Widget ---
    final textWidget = Text(
      data,
      style: effectiveStyle, // 使用最终计算的样式
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: scaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );

    // --- 处理高级操作 (prefixIcon) ---
    if (prefixIcon != null) {
      // 图标颜色和大小跟随最终文本样式
      final iconColor = effectiveStyle.color;
      // 优先使用 effectiveStyle 的字号，如果没指定，给个默认值或从 theme 获取
      final iconSize = effectiveStyle.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14.0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // 确保图标和文字垂直居中
        children: [
          Icon(prefixIcon, size: iconSize, color: iconColor),
          SizedBox(width: iconSpacing),
          // 使用 Flexible 或 Expanded 取决于布局需求，Flexible 更通用
          Flexible(child: textWidget),
        ],
      );
    } else {
      return textWidget;
    }
  }

  // --- 内部辅助方法：根据 type 获取主题样式和颜色 (保持不变) ---
  TextStyle _getStyleForType(BuildContext context, AppTextType type) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    TextStyle baseStyle = textTheme.bodyMedium ?? const TextStyle();
    // 默认颜色现在由 baseStyle 提供，后面根据 type 覆盖
    // Color? color = baseStyle.color; // 不再需要单独维护 color 变量

    switch (type) {
      case AppTextType.body:
        baseStyle = textTheme.bodyMedium ?? baseStyle;
        break;
      case AppTextType.caption:
        baseStyle = textTheme.bodySmall ?? baseStyle;
        break;
      case AppTextType.button:
        baseStyle = textTheme.labelLarge ?? baseStyle;
        break;
      case AppTextType.title:
        baseStyle = textTheme.titleMedium ?? baseStyle;
        break;
      case AppTextType.headline:
        baseStyle = textTheme.headlineSmall ?? baseStyle;
        break;
    // --- 下面这些类型主要是修改颜色 ---
      case AppTextType.primary:
      // 基础样式保持 bodyMedium，只改颜色
        baseStyle = (textTheme.bodyMedium ?? baseStyle).copyWith(color: colorScheme.primary);
        break;
      case AppTextType.secondary:
        baseStyle = (textTheme.bodyMedium ?? baseStyle).copyWith(color: colorScheme.onSurfaceVariant);
        break;
      case AppTextType.error:
        baseStyle = (textTheme.bodyMedium ?? baseStyle).copyWith(color: colorScheme.error);
        break;
      case AppTextType.disabled:
        baseStyle = (textTheme.bodyMedium ?? baseStyle).copyWith(color: colorScheme.onSurface.withSafeOpacity(0.38));
        break;
      case AppTextType.success:
        baseStyle = (textTheme.bodyMedium ?? baseStyle).copyWith(color: Colors.green); // 或者你自定义的成功色
        break;
      case AppTextType.warning:
        baseStyle = (textTheme.bodyMedium ?? baseStyle).copyWith(color: Colors.orange); // 或者你自定义的警告色
        break;
    }
    // 直接返回带有颜色信息的 baseStyle
    return baseStyle;
  }
}