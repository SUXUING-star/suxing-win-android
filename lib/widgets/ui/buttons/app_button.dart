import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/font/font_config.dart'; // 引入字体配置

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon; // 现在 icon 直接是 Widget，灵活性更高
  final double iconSpacing;
  final bool isMini;
  final bool isPrimaryAction;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconSpacing = 8.0,
    this.isMini = false,
    this.isPrimaryAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool effectiveIsDisabled = isDisabled || isLoading || onPressed == null;

    // --- 1. 计算样式变量 ---

    // 尺寸和边距 (保留 isMini 逻辑)
    final double borderRadius = isMini ? 8.0 : 12.0; // 统一圆角风格
    final EdgeInsets padding = isMini
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6) // 调整 mini 内边距
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 10); // 标准内边距
    // final Size minimumSize = isMini ? const Size(60, 30) : const Size(80, 38); // 可以设置最小尺寸

    // 图标和字体 (保留 isMini 逻辑)
    final double iconSize = isMini ? 16.0 : 18.0;
    final double fontSize = isMini ? 13.0 : 15.0; // 调整字体大小
    final double effectiveIconSpacing = isMini ? 5.0 : iconSpacing; // 调整 mini 图标间距
    const FontWeight fontWeight = FontWeight.w600; // 统一字体粗细

    // --- 2. 颜色计算 (核心修改) ---
    // 定义基础颜色
    final Color primaryBaseColor = colorScheme.primary;
    final Color secondaryBaseColor = colorScheme.secondary; // 用于 isPrimaryAction

    // 根据 isPrimaryAction 选择当前操作的基础色
    final Color activeBaseColor = isPrimaryAction ? secondaryBaseColor : primaryBaseColor;

    // 定义透明度 (alpha 值 0-255)
    final int backgroundAlpha = (255 * 0.15).round(); // 15% 透明度

    // 计算激活状态的颜色
    final Color activeBgColor = activeBaseColor.withAlpha(backgroundAlpha);
    final Color activeFgColor = activeBaseColor; // 文字/图标用基础色，保持清晰

    // 定义禁用状态的颜色
    final Color disabledBgColor = Colors.grey.shade200.withAlpha(150); // 半透明灰
    final Color disabledFgColor = Colors.grey.shade400; // 禁用文字/图标颜色

    // 根据禁用状态确定最终颜色
    final Color currentBgColor = effectiveIsDisabled ? disabledBgColor : activeBgColor;
    final Color currentFgColor = effectiveIsDisabled ? disabledFgColor : activeFgColor;

    // --- 3. 构建按钮内容 (Child) ---
    Widget buttonChild;
    if (isLoading) {
      // 加载状态
      buttonChild = SizedBox(
        width: iconSize, // 使用计算出的图标大小作为菊花图尺寸
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.0, // 细一点的线条
          color: currentFgColor, // 使用当前前景色
        ),
      );
    } else if (icon != null) {
      // 带图标状态
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 使用 Theme 来统一设置图标颜色和大小，而不是 IconTheme
          Theme(
            data: theme.copyWith(
                iconTheme: theme.iconTheme.copyWith(
                  color: currentFgColor,
                  size: iconSize,
                )),
            child: icon!, // 直接使用传入的 Widget
          ),
          SizedBox(width: effectiveIconSpacing),
          Text(
            text,
            style: TextStyle(
              fontFamily: FontConfig.defaultFontFamily, // 应用字体
              fontFamilyFallback: FontConfig.fontFallback,
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: currentFgColor,
            ),
            overflow: TextOverflow.ellipsis, // 防止文字溢出
            maxLines: 1,
          ),
        ],
      );
    } else {
      // 纯文本状态
      buttonChild = Text(
        text,
        style: TextStyle(
          fontFamily: FontConfig.defaultFontFamily, // 应用字体
          fontFamilyFallback: FontConfig.fontFallback,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: currentFgColor,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      );
    }

    // --- 4. 返回 ElevatedButton ---
    return ElevatedButton(
      onPressed: effectiveIsDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        // 颜色
        backgroundColor: currentBgColor,
        foregroundColor: currentFgColor, // 对波纹效果等有影响
        disabledBackgroundColor: disabledBgColor,
        disabledForegroundColor: disabledFgColor,
        // 阴影 (设置为 0)
        elevation: 0,
        shadowColor: Colors.transparent, // 明确设置透明阴影色
        // 形状和尺寸
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        // minimumSize: minimumSize, // 如果需要可以取消注释
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      // 使用 Center 确保内容居中
      child: Center(child: buttonChild),
    );
  }
}