// lib/widgets/ui/tabs/custom_segmented_control_tab_bar.dart
import 'package:flutter/material.dart';

class CustomSegmentedControlTabBar extends StatefulWidget {
  final TabController controller;
  final List<String> tabTitles;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor; // 整个控件的背景色
  final Color selectedTabColor; // 选中标签的背景色
  final Color unselectedTabColor; // 未选中标签的背景色 (通常可以透明)
  final TextStyle selectedTextStyle;
  final TextStyle unselectedTextStyle;
  final EdgeInsetsGeometry tabPadding; // 单个标签的内边距
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? margin; // 整个控件的外边距

  const CustomSegmentedControlTabBar({
    super.key,
    required this.controller,
    required this.tabTitles,
    this.onTap,
    this.backgroundColor,
    required this.selectedTabColor,
    this.unselectedTabColor = Colors.transparent, // 默认未选中时透明
    required this.selectedTextStyle,
    required this.unselectedTextStyle,
    this.tabPadding = const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  });

  @override
  State<CustomSegmentedControlTabBar> createState() => _CustomSegmentedControlTabBarState();
}

class _CustomSegmentedControlTabBarState extends State<CustomSegmentedControlTabBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.controller.index;
    widget.controller.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTabSelection);
    super.dispose();
  }

  void _handleTabSelection() {
    // 确保只在索引实际改变时更新状态，避免不必要的重建
    if (mounted && (widget.controller.indexIsChanging || _currentIndex != widget.controller.index)) {
      setState(() {
        _currentIndex = widget.controller.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      padding: const EdgeInsets.all(3.0), // 给外部容器一点padding，使得内部选中项的圆角背景更好看
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6), // 较浅的背景色
        borderRadius: widget.borderRadius,
      ),
      child: Row(
        children: List.generate(widget.tabTitles.length, (index) {
          final bool isSelected = _currentIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_currentIndex != index) {
                  widget.controller.animateTo(index);
                  widget.onTap?.call(index);
                  // 主动更新 _currentIndex，因为 controller 的 listener 可能会有延迟
                  // 或者在 animateTo 完成后才触发。
                  // setState(() {
                  //  _currentIndex = index;
                  // });
                  // 注释掉上面是因为 controller.addListener 应该会处理
                }
              },
              child: Container(
                padding: widget.tabPadding,
                decoration: BoxDecoration(
                  color: isSelected ? widget.selectedTabColor : widget.unselectedTabColor,
                  borderRadius: widget.borderRadius, // 内部选中项的圆角
                ),
                child: Center(
                  child: Text(
                    widget.tabTitles[index],
                    style: isSelected ? widget.selectedTextStyle : widget.unselectedTextStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}