// lib/widgets/ui/appbar/custom_sliver_app_bar.dart

/// 该文件定义了 CustomSliverAppBar 组件，一个可定制的 SliverAppBar。
/// CustomSliverAppBar 支持自定义标题、动作按钮、背景和折叠行为。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'dart:io' show Platform; // 导入 Platform 类，用于获取平台信息

/// `CustomSliverAppBar` 类：一个可定制的 SliverAppBar 组件。
///
/// 该组件提供标题、动作按钮、前导组件和底部组件，并支持折叠、悬浮和吸顶行为。
class CustomSliverAppBar extends StatelessWidget {
  final String titleText; // 顶部栏标题文本
  final List<Widget>? actions; // 右侧动作按钮列表
  final Widget? leading; // 左侧前导组件
  final PreferredSizeWidget? bottom; // 底部组件
  final bool pinned; // AppBar 是否吸顶
  final bool floating; // AppBar 是否悬浮
  final bool snap; // AppBar 是否在浮动时自动吸附
  final double? expandedHeight; // AppBar 展开时的高度
  final double? collapsedHeight; // AppBar 收起时的高度
  final double toolbarHeight; // 工具栏高度
  final bool? centerTitle; // 标题是否居中
  final Widget? flexibleSpaceBackground; // 灵活空间背景
  final Color collapsedBackgroundColor; // 收起时的背景色
  final TextStyle? titleTextStyle; // 标题文本样式
  final IconThemeData? iconTheme; // 前导图标主题
  final IconThemeData? actionsIconTheme; // 动作图标主题

  /// 构造函数。
  ///
  /// [titleText]：标题文本。
  /// [actions]：动作按钮。
  /// [leading]：前导组件。
  /// [bottom]：底部组件。
  /// [pinned]：是否吸顶。
  /// [floating]：是否悬浮。
  /// [snap]：是否吸附。
  /// [expandedHeight]：展开高度。
  /// [collapsedHeight]：收起高度。
  /// [toolbarHeight]：工具栏高度。
  /// [centerTitle]：标题是否居中。
  /// [flexibleSpaceBackground]：灵活空间背景。
  /// [collapsedBackgroundColor]：收起时背景色。
  /// [titleTextStyle]：标题文本样式。
  /// [iconTheme]：前导图标主题。
  /// [actionsIconTheme]：动作图标主题。
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
    this.toolbarHeight = kToolbarHeight,
    this.centerTitle,
    this.flexibleSpaceBackground,
    this.collapsedBackgroundColor = const Color(0xFF6AB7F0),
    this.titleTextStyle,
    this.iconTheme = const IconThemeData(color: Colors.white),
    this.actionsIconTheme = const IconThemeData(color: Colors.white),
  }) : assert(!snap || floating, 'snap=true 需要 floating=true。');

  /// 构建自定义 SliverAppBar。
  ///
  /// 该方法根据平台、高度、样式等参数构建 SliverAppBar。
  @override
  Widget build(BuildContext context) {
    final bool isAndroidLandscape = Platform.isAndroid &&
        MediaQuery.of(context).orientation ==
            Orientation.landscape; // 判断是否为 Android 横屏

    final double defaultFontSize = isAndroidLandscape ? 18.0 : 20.0; // 默认字体大小
    final TextStyle effectiveTitleStyle = TextStyle(
      color: Colors.white, // 文本颜色
      fontWeight: FontWeight.bold, // 字体粗细
      fontSize: defaultFontSize, // 字体大小
      shadows: const [
        // 文本阴影
        Shadow(
          offset: Offset(0, 1),
          blurRadius: 3.0,
          color: Color.fromARGB(150, 0, 0, 0),
        ),
      ],
    ).merge(titleTextStyle); // 合并外部传入的样式

    final Widget titleContent = Text(
      titleText, // 标题文本
      style: effectiveTitleStyle, // 文本样式
      maxLines: 1, // 最大行数
      overflow: TextOverflow.ellipsis, // 溢出显示省略号
    );

    final Widget defaultGradientBackground = Container(
      // 默认渐变背景
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

    Widget? effectiveFlexibleSpace; // 有效的 FlexibleSpace
    if (expandedHeight != null && expandedHeight! > toolbarHeight) {
      // 需要展开时创建 FlexibleSpaceBar
      effectiveFlexibleSpace = FlexibleSpaceBar(
        title: titleContent, // 标题
        centerTitle: centerTitle, // 标题是否居中
        background: flexibleSpaceBackground ?? defaultGradientBackground, // 背景
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle
        ], // 拉伸模式
      );
    } else {
      // 不展开时，FlexibleSpace 为背景
      effectiveFlexibleSpace =
          flexibleSpaceBackground ?? defaultGradientBackground;
    }

    return SliverAppBar(
      leading: leading, // 前导组件
      automaticallyImplyLeading: leading == null, // 自动推断前导组件
      actions: actions, // 动作按钮
      pinned: pinned, // 是否吸顶
      floating: floating, // 是否悬浮
      snap: snap, // 是否吸附
      expandedHeight: expandedHeight, // 展开高度
      collapsedHeight: collapsedHeight, // 收起高度
      toolbarHeight: toolbarHeight, // 工具栏高度
      centerTitle: centerTitle, // 标题是否居中

      backgroundColor: collapsedBackgroundColor, // 收起时的背景色
      elevation: 0, // 阴影高度
      shadowColor: Colors.transparent, // 阴影颜色透明
      surfaceTintColor: Colors.transparent, // 表面着色透明
      foregroundColor: Colors.white, // 前景色
      iconTheme: iconTheme, // 前导图标主题
      actionsIconTheme: actionsIconTheme, // 动作图标主题
      titleTextStyle: effectiveTitleStyle.copyWith(fontSize: 16), // 标题文本样式

      flexibleSpace: effectiveFlexibleSpace, // 灵活空间
      title: (effectiveFlexibleSpace is FlexibleSpaceBar)
          ? null
          : titleContent, // 标题
      bottom: bottom, // 底部组件

      primary: true, // 是否为主 AppBar
    );
  }
}
