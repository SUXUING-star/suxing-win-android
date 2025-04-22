// lib/widgets/ui/appbar/custom_sliver_app_bar.dart
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class CustomSliverAppBar extends StatelessWidget {
  final String titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool pinned;
  final bool floating;
  final bool snap;
  final double? expandedHeight;
  final double? collapsedHeight;
  final double toolbarHeight;
  final bool? centerTitle; // 可选，让它根据平台/主题决定
  final Widget? flexibleSpaceBackground; // 用于展开时的背景
  final Color collapsedBackgroundColor; // 收起时的背景色 (非可选)
  final TextStyle? titleTextStyle; // 允许自定义标题样式
  final IconThemeData? iconTheme; // 控制 leading 图标颜色
  final IconThemeData? actionsIconTheme; // 控制 actions 图标颜色


  const CustomSliverAppBar({
    super.key,
    required this.titleText,
    this.actions,
    this.leading,
    this.bottom,
    this.pinned = false,
    this.floating = false,
    this.snap = false,
    this.expandedHeight,
    this.collapsedHeight,
    this.toolbarHeight = kToolbarHeight, // 默认标准高度
    this.centerTitle, // 不设置默认值，让 SliverAppBar 自己决定
    this.flexibleSpaceBackground,
    this.collapsedBackgroundColor = const Color(0xFF6AB7F0), // 默认浅蓝
    this.titleTextStyle, // 允许覆盖默认样式
    this.iconTheme = const IconThemeData(color: Colors.white), // 默认白色图标
    this.actionsIconTheme = const IconThemeData(color: Colors.white), // 默认白色图标
  }) : assert(!snap || floating, 'snap=true requires floating=true');

  // 辅助函数：构建默认底部线条 (可选)
  PreferredSizeWidget _buildDefaultBottom(BuildContext context, bool isAndroidLandscape) {
    final double bottomLineHeightFactor = isAndroidLandscape ? 0.5 : 1.0;
    final double visualHeight = 1.0 * bottomLineHeightFactor;
    final double preferredHeight = 4.0 * bottomLineHeightFactor;

    return PreferredSize(
      preferredSize: Size.fromHeight(preferredHeight),
      child: Opacity(
        opacity: 0.7,
        child: Container(
          color: Colors.white.withOpacity(0.2),
          height: visualHeight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAndroidLandscape = Platform.isAndroid &&
        MediaQuery.of(context).orientation == Orientation.landscape;

    // 1. 确定标题样式
    final double defaultFontSize = isAndroidLandscape ? 18.0 : 20.0;
    final TextStyle effectiveTitleStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: defaultFontSize,
      shadows: const [
        Shadow(
          offset: Offset(0, 1),
          blurRadius: 3.0,
          color: Color.fromARGB(150, 0, 0, 0),
        ),
      ],
    ).merge(titleTextStyle); // 合并外部传入的样式

    // 2. 创建简单的 Text Widget
    final Widget titleContent = Text(
      titleText,
      style: effectiveTitleStyle,
      maxLines: 1, // 确保单行
      overflow: TextOverflow.ellipsis, // 超出省略
    );

    // 3. 创建默认渐变背景 (如果 flexibleSpaceBackground 未提供)
    final Widget defaultGradientBackground = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF6AB7F0),
            Color(0xFF4E9DE3),
          ],
        ),
      ),
    );

    // 4. 准备 FlexibleSpaceBar (严格按照原始逻辑)
    Widget? effectiveFlexibleSpace;
    // 只有在需要展开时才创建 FlexibleSpaceBar
    if (expandedHeight != null && expandedHeight! > toolbarHeight) {
      effectiveFlexibleSpace = FlexibleSpaceBar(
        // *** 关键：title 放在 FlexibleSpaceBar 里 ***
        title: titleContent,
        centerTitle: centerTitle, // 使用传入的 centerTitle 或让 FlexibleSpaceBar 决定
        background: flexibleSpaceBackground ?? defaultGradientBackground,
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        // 让 FlexibleSpaceBar 使用默认的 titlePadding 计算逻辑
        // titlePadding: ..., // 不设置，使用默认值
      );
    } else {
      // 如果不展开，flexibleSpace 就是背景
      effectiveFlexibleSpace = flexibleSpaceBackground ?? defaultGradientBackground;
    }

    // 5. 返回标准 SliverAppBar
    return SliverAppBar(
      // --- 基础参数 ---
      leading: leading,
      automaticallyImplyLeading: leading == null,
      actions: actions,
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      toolbarHeight: toolbarHeight,
      centerTitle: centerTitle, // 传递给 SliverAppBar

      // --- 样式 ---
      backgroundColor: collapsedBackgroundColor, // 收起时的背景色
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white, // 影响默认图标颜色
      iconTheme: iconTheme,
      actionsIconTheme: actionsIconTheme,
      // 提供基础的 titleTextStyle，但会被 FlexibleSpaceBar 里的 title 覆盖
      titleTextStyle: effectiveTitleStyle.copyWith(fontSize: 16), // 收起时可以稍微小一点字号，可选

      // --- 核心逻辑：title 和 titleSpacing ---
      flexibleSpace: effectiveFlexibleSpace,
      // *** 关键：如果使用了 FlexibleSpaceBar，这里的 title 必须为 null ***
      title: (effectiveFlexibleSpace is FlexibleSpaceBar) ? null : titleContent,
      // *** 关键：不设置 titleSpacing，使用 Flutter 默认值！ ***
      // titleSpacing: null, // 或者干脆不写这行

      // --- 底部 ---
      bottom: bottom, // 直接使用传入的 bottom，不再加默认线，如果需要线，从外部传入

      // --- 其他 ---
      primary: true,
    );
  }
}