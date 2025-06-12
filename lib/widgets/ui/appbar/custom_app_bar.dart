// lib/widgets/ui/appbar/custom_app_bar.dart

/// 该文件定义了 CustomAppBar 组件，一个自定义的应用顶部栏。
/// **全新设计**：在桌面端，它不再渲染为完整的 AppBar，而是作为一个“内容条”Widget，
/// 以便嵌入到已有的窗口控制栏中，彻底解决“双下巴”问题。
/// 在移动端，它仍然是一个标准的 AppBar。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_icon_button.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool showTitleInDesktop;
  final Color? desktopBackgroundColor; // 允许在桌面端自定义背景色，或者设为透明

  const CustomAppBar({
    super.key,
    required this.title,
    this.showTitleInDesktop = false,
    this.actions,
    this.leading,
    this.bottom,
    this.desktopBackgroundColor, // 桌面端背景色，默认透明
  });

  @override
  Size get preferredSize {
    // 只有在移动端，这个 preferredSize 才有作为 AppBar 的意义
    // 桌面端我们把它当普通 Widget 用，但为了接口一致性，还是计算一下
    final bool isDesktop = DeviceUtils.isDesktop;
    bool isAndroidLandscape = false;
    if (!isDesktop && Platform.isAndroid) {
      final view = ui.PlatformDispatcher.instance.implicitView;
      if (view != null) {
        isAndroidLandscape = view.physicalSize.width > view.physicalSize.height;
      }
    }

    double baseHeight;
    if (isDesktop) {
      baseHeight =
          kToolbarHeight * GlobalConstants.appBarDesktopToolbarHeightFactor;
    } else if (isAndroidLandscape) {
      baseHeight = kToolbarHeight *
          GlobalConstants.appBarAndroidLandscapeToolbarHeightFactor;
    } else {
      baseHeight = kToolbarHeight;
    }

    final double bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(baseHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    // 核心判断：是桌面就给“内容条”，是手机就给完整 AppBar
    if (DeviceUtils.isDesktopScreen(context)) {
      return _buildDesktopContentBar(context);
    } else {
      return _buildMobileAppBar(context);
    }
  }

  /// **桌面端专用：只构建内容，不带 AppBar 的壳子**
  /// 这就是一个普通的 Widget，你可以把它塞到任何地方。
  Widget _buildDesktopContentBar(BuildContext context) {
    // 如果在桌面端完全不需要显示（比如某些页面），可以直接返回空盒子
    if (leading == null && actions == null && !showTitleInDesktop) {
      return const SizedBox.shrink();
    }

    return Container(
      height: preferredSize.height,
      color: desktopBackgroundColor, // 你可以从外部控制背景，如果为null就是透明的
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        // 把 leading, title, actions 水平排列
        children: [
          if (leading != null) leading!,
          if (showTitleInDesktop)
            Expanded(
              child: AppText(
                title,
                // 这里颜色可以自定义，或者从主题获取，先写死个白色
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: GlobalConstants.appBarDesktopFontSize,
              ),
            ),
          // 如果标题不占满，加一个 Spacer 把 actions 推到最右边
          if (!showTitleInDesktop) const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  /// **移动端专用：构建一个完整的、标准的 AppBar**
  Widget _buildMobileAppBar(BuildContext context) {
    final bool isActualAndroidLandscape =
        !DeviceUtils.isDesktopScreen(context) &&
            Platform.isAndroid &&
            MediaQuery.of(context).orientation == Orientation.landscape;

    final double fontSize = isActualAndroidLandscape
        ? GlobalConstants.appBarAndroidLandscapeFontSize
        : GlobalConstants.defaultAppBarFontSize;

    final double actualBottomHeight = bottom?.preferredSize.height ?? 0;
    final double toolbarHeight = preferredSize.height - actualBottomHeight;
    final canBack = NavigationUtils.canPop(context);

    return AppBar(
      title: AppText(
        title,
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: fontSize,
      ),
      leading:
          canBack && !DeviceUtils.isDesktopScreen(context) && leading == null
              ? FunctionalIconButton(
                  onPressed: () => NavigationUtils.pop(context),
                  icon: Icons.arrow_back,
                  iconColor: Colors.black,
                  hoverColor: Colors.white,
                  tooltip: "返回上一页",
                )
              : leading,
      actions: actions,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: toolbarHeight,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [...GlobalConstants.defaultAppBarColors],
          ),
        ),
      ),
      bottom: bottom,
    );
  }
}
