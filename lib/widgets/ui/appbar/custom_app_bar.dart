// lib/widgets/ui/appbar/custom_app_bar.dart

/// 该文件定义了 CustomAppBar 组件，一个自定义的应用顶部栏。
/// CustomAppBar 支持自定义标题、动作按钮和背景，并根据平台调整其高度和样式。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/constants/global_constants.dart'; // 导入全局常量
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/buttons/functional_icon_button.dart'; // 导入功能图标按钮
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件
import 'dart:io' show Platform; // 导入 Platform 类，用于获取平台信息
import 'dart:ui' as ui; // 导入 dart:ui，用于获取屏幕物理尺寸

/// `CustomAppBar` 类：自定义应用顶部栏组件。
///
/// 该组件实现 [PreferredSizeWidget]，提供标题、动作按钮、前导组件和底部组件，
/// 并根据平台（桌面或移动端横屏）调整其高度和字体大小。
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title; // 顶部栏标题
  final List<Widget>? actions; // 右侧动作按钮列表
  final Widget? leading; // 左侧前导组件
  final PreferredSizeWidget? bottom; // 底部组件
  final bool showTitleInDesktop; // 是否在桌面平台显示标题

  static const double _desktopToolbarHeightFactor =
      GlobalConstants.appBarDesktopToolbarHeightFactor; // 桌面端工具栏高度因子
  static const double _desktopBottomHeight =
      GlobalConstants.defaultAppBarBottomHeight; // 桌面端底部线条高度
  static const double _desktopFontSize =
      GlobalConstants.appBarDesktopFontSize; // 桌面端标题字体大小

  static const double _androidLandscapeToolbarHeightFactor = GlobalConstants
      .appBarAndroidLandscapeToolbarHeightFactor; // Android 横屏工具栏高度因子
  static const double _androidLandscapeBottomHeight =
      GlobalConstants.appBarAndroidLandscapeBottomHeight; // Android 横屏底部线条高度
  static const double _androidLandscapeFontSize =
      GlobalConstants.appBarAndroidLandscapeFontSize; // Android 横屏标题字体大小

  static const double _defaultBottomHeight =
      GlobalConstants.defaultAppBarBottomHeight; // 默认底部线条高度
  static const double _defaultFontSize =
      GlobalConstants.defaultAppBarFontSize; // 默认标题字体大小

  /// 构造函数。
  ///
  /// [title]：标题。
  /// [showTitleInDesktop]：是否在桌面显示标题。
  /// [actions]：动作按钮。
  /// [leading]：前导组件。
  /// [bottom]：底部组件。
  const CustomAppBar({
    super.key,
    required this.title,
    this.showTitleInDesktop = false,
    this.actions,
    this.leading,
    this.bottom,
  });

  /// 返回顶部栏的首选尺寸。
  ///
  /// 根据平台类型（桌面或 Android 横屏）和 `bottom` 组件的存在，
  /// 计算并返回顶部栏的总高度。
  @override
  Size get preferredSize {
    final bool isDesktop = DeviceUtils.isDesktop; // 判断是否为桌面平台

    bool isAndroidLandscape = false; // 是否为 Android 横屏
    if (!isDesktop && Platform.isAndroid) {
      final ui.FlutterView? view =
          ui.PlatformDispatcher.instance.implicitView; // 获取主视图信息
      if (view != null) {
        isAndroidLandscape =
            view.physicalSize.width > view.physicalSize.height; // 根据物理尺寸判断横屏
      }
    }

    double baseHeight; // 基础高度
    if (isDesktop) {
      baseHeight = kToolbarHeight * _desktopToolbarHeightFactor; // 桌面端高度
    } else if (isAndroidLandscape) {
      baseHeight =
          kToolbarHeight * _androidLandscapeToolbarHeightFactor; // Android 横屏高度
    } else {
      baseHeight = kToolbarHeight; // 默认高度
    }

    final double bottomHeight = bottom?.preferredSize.height ??
        _calculateDefaultBottomHeight(isDesktop, isAndroidLandscape); // 底部组件高度

    return Size.fromHeight(baseHeight + bottomHeight); // 返回总高度
  }

  /// 计算默认底部线条的高度。
  ///
  /// [isDesktop]：是否为桌面平台。
  /// [isAndroidLandscape]：是否为 Android 横屏。
  /// 返回计算得到的底部线条高度。
  double _calculateDefaultBottomHeight(
      bool isDesktop, bool isAndroidLandscape) {
    if (isDesktop) {
      return _desktopBottomHeight; // 桌面端底部高度
    } else if (isAndroidLandscape) {
      return _androidLandscapeBottomHeight; // Android 横屏底部高度
    } else {
      return _defaultBottomHeight; // 默认底部高度
    }
  }

  /// 构建自定义应用顶部栏。
  ///
  /// 该方法根据平台、是否显示标题和动作按钮等参数构建顶部栏。
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop; // 判断是否为桌面平台
    final bool hasNoActions = actions == null || actions!.isEmpty; // 判断是否没有动作按钮
    final bool isActualAndroidLandscape = !isDesktop &&
        Platform.isAndroid &&
        MediaQuery.of(context).orientation ==
            Orientation.landscape; // 判断是否为实际的 Android 横屏

    final double fontSize = isDesktop
        ? _desktopFontSize
        : (isActualAndroidLandscape
            ? _androidLandscapeFontSize
            : _defaultFontSize); // 根据平台调整字体大小

    final double actualBottomHeight = bottom?.preferredSize.height ??
        _calculateDefaultBottomHeight(
            isDesktop, isActualAndroidLandscape); // 实际底部组件高度
    final double toolbarHeight =
        preferredSize.height - actualBottomHeight; // 工具栏高度

    final double desktopActionsPadding = 140; // 桌面端动作按钮右边距
    final canBack = NavigationUtils.canPop(context); // 是否可以返回

    final needShowTitle =
        !(showTitleInDesktop == false && isDesktop); // 是否需要显示标题

    if (leading == null && isDesktop && hasNoActions) {
      return const SizedBox.shrink(); // 在特定条件下返回空组件
    }

    return AppBar(
      title: AppText(
        needShowTitle ? title : '', // 标题文本
        color: Colors.black, // 文本颜色
        fontWeight: FontWeight.bold, // 字体粗细
        fontSize: fontSize, // 字体大小
      ),
      leading: canBack && !isDesktop && leading == null // 前导组件
          ? FunctionalIconButton(
              onPressed: () => NavigationUtils.pop(context), // 点击返回上一页
              icon: Icons.arrow_back, // 返回图标
              iconColor: Colors.black, // 图标颜色
              hoverColor: Colors.white, // 悬停颜色
              tooltip: "返回上一页", // 提示
            )
          : leading,
      actions: [
        if (actions != null) ...actions!, // 动作按钮列表

        if (isDesktop) SizedBox(width: desktopActionsPadding), // 桌面平台动作按钮间隔
      ],
      automaticallyImplyLeading: false, // 自动推断前导组件
      backgroundColor: Colors.transparent, // 背景色透明
      elevation: 0, // 阴影高度
      toolbarHeight: toolbarHeight, // 工具栏高度
      flexibleSpace: Container(
        // 灵活空间，用于背景渐变
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [...GlobalConstants.defaultSideBarColors],
          ),
        ),
      ),
      bottom: bottom ?? // 底部组件
          PreferredSize(
            preferredSize: Size.fromHeight(actualBottomHeight), // 底部组件首选尺寸
            child: Opacity(
              opacity: 0.7, // 透明度
              child: Container(
                color: Colors.white.withSafeOpacity(0.2), // 背景色
                height:
                    actualBottomHeight > 0 ? actualBottomHeight / 4 : 0, // 高度
              ),
            ),
          ),
    );
  }
}
