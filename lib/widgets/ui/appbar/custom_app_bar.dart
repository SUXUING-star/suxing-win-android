// lib/widgets/ui/appbar/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'dart:io' show Platform;
import '../../../utils/device/device_utils.dart'; // 确认这个路径是正确的

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  // --- 可调参数 ---
  // 你可以在这里调整桌面端的 AppBar 高度比例 (比如 0.75 就是原高度的 75%)
  static const double _desktopToolbarHeightFactor = 0.75;
  // 你可以在这里调整桌面端的底部线条高度
  static const double _desktopBottomHeight = 2.0;
  // 你可以在这里调整桌面端的标题字体大小 (如果你的逻辑会在桌面显示标题的话)
  static const double _desktopFontSize = 14.0;
  // ----------------

  // --- Android 横屏的可调参数 ---
  static const double _androidLandscapeToolbarHeightFactor = 0.8;
  static const double _androidLandscapeBottomHeight = 2.0;
  static const double _androidLandscapeFontSize = 14.0;
  // --------------------------

  // --- 默认参数 ---
  static const double _defaultBottomHeight = 4.0;
  static const double _defaultFontSize = 16.0;
  // ---------------

  // 统一的appbar的样式
  //
  static const List<Color> appBarColors = [
    Color(0x000000FF),
    //  不要改我这个牛逼的配色
    // 0xFFFFFFFF和xFF000000都不对
    Color(0xFFD8FFEF),
    Color(0x000000FF),
  ];

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize {
    // *** 主要修改点 1: 判断平台并计算基础高度 ***
    final bool isDesktop = DeviceUtils.isDesktop;

    // 避免在桌面端时也满足 Android 横屏条件
    final bool isAndroidLandscape = !isDesktop &&
        Platform.isAndroid &&
        WidgetsBinding.instance.window.physicalSize.width >
            WidgetsBinding.instance.window.physicalSize.height;

    double baseHeight; // AppBar 主要区域的高度 (不含 bottom)

    if (isDesktop) {
      // 如果是桌面端，使用缩小的比例
      baseHeight = kToolbarHeight * _desktopToolbarHeightFactor;
    } else if (isAndroidLandscape) {
      // 保留原有的 Android 横屏逻辑
      baseHeight = kToolbarHeight * _androidLandscapeToolbarHeightFactor;
    } else {
      // 其他情况（如手机竖屏）使用默认高度
      baseHeight = kToolbarHeight;
    }

    // --- 计算底部高度 ---
    // 如果外部传入了自定义 bottom，则使用其高度；
    // 否则，根据平台计算我们默认的底部线条高度
    final double bottomHeight = bottom?.preferredSize.height ??
        _calculateDefaultBottomHeight(isDesktop, isAndroidLandscape);

    // 最终 preferredSize 是基础高度 + 底部高度
    return Size.fromHeight(baseHeight + bottomHeight);
  }

  // 辅助方法：计算默认底部线条的高度
  double _calculateDefaultBottomHeight(
      bool isDesktop, bool isAndroidLandscape) {
    if (isDesktop) {
      return _desktopBottomHeight;
    } else if (isAndroidLandscape) {
      return _androidLandscapeBottomHeight;
    } else {
      return _defaultBottomHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool hasNoActions = actions == null || actions!.isEmpty;
    final bool isAndroidLandscape = !isDesktop &&
        Platform.isAndroid &&
        MediaQuery.of(context).orientation == Orientation.landscape;

    // *** 修改点 2: 根据平台调整字体大小 ***
    final double fontSize = isDesktop
        ? _desktopFontSize
        : (isAndroidLandscape ? _androidLandscapeFontSize : _defaultFontSize);



    // *** 修改点 3: 计算 AppBar 实际的 toolbarHeight (不包含 bottom 的高度) ***
    // 需要从 preferredSize 的总高度里减去 bottom 部分的高度
    final double actualBottomHeight = bottom?.preferredSize.height ??
        _calculateDefaultBottomHeight(isDesktop, isAndroidLandscape);
    final double toolbarHeight =
        preferredSize.height - actualBottomHeight; // 这就是 AppBar 主要区域应有的高度

    // --- 为桌面平台的 actions 添加右边距，避免与 WindowsControls 重叠 (保留原逻辑) ---
    final double desktopActionsPadding =
        isDesktop ? 140 : 0.0; // 这个值你可能需要根据实际情况微调
    final canBack = NavigationUtils.canPop(context);

    // 这个判断的意思是appbar不承担任何actions和leading时
    // 在桌面端不显示否则就是摆设

    if (leading == null && isDesktop && hasNoActions) return SizedBox.shrink();

    return AppBar(
      title: AppText(
        // 原逻辑：桌面端不显示标题
        !isDesktop ? title : '',
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: fontSize, // 使用根据平台调整后的字体大小
      ),
      // 我自己封装
      leading: canBack && !isDesktop && leading == null
          ? IconButton(
              onPressed: () => NavigationUtils.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: Colors.black,
              ),
              hoverColor: Colors.white,
              tooltip: "返回上一页",
            )
          : leading,
      actions: [
        if (actions != null) ...actions!,

        // 在桌面平台添加间隔，保留原逻辑
        if (isDesktop) SizedBox(width: desktopActionsPadding),
      ],
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent, // 背景由 flexibleSpace 提供
      elevation: 0,
      // *** 修改点 4: 设置计算好的 toolbarHeight ***
      toolbarHeight: toolbarHeight, // 明确设置 AppBar 的工具栏高度
      flexibleSpace: Container(
        // 背景渐变保持不变
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              ...appBarColors
            ],
          ),
        ),
      ),
      // *** 修改点 5: 处理 bottom 部分 ***
      // 如果外部传入了 bottom，就用它
      // 否则，创建我们默认的底部线条，并使用计算好的高度
      bottom: bottom ??
          PreferredSize(
            // 使用计算得到的底部高度
            preferredSize: Size.fromHeight(actualBottomHeight),
            child: Opacity(
              opacity: 0.7,
              child: Container(
                color: Colors.white.withOpacity(0.2),
                // 让白色细线的高度也适应变化，比如总是底部总高度的 1/4
                height: actualBottomHeight > 0 ? actualBottomHeight / 4 : 0,
              ),
            ),
          ),
    );
  }
}
