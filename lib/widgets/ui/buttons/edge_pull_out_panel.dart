// lib/widgets/ui/buttons/edge_pull_out_panel.dart
import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

class EdgePullOutPanel extends StatefulWidget {
  final List<Widget> children;
  final Color panelColor;
  final Color handleColor;
  final IconData handleIconOpened;
  final IconData handleIconClosed;
  final double handleWidth;
  final double handleVisibleHeight;
  final double panelContentWidth;
  final Duration animationDuration;
  final Curve animationCurve;
  final double topOffset;
  final double itemSpacing;
  final bool initiallyOpen;
  final BorderRadiusGeometry? panelBorderRadius; // 允许外部传入 BorderRadiusGeometry
  final List<BoxShadow>? panelBoxShadow;

  const EdgePullOutPanel({
    super.key,
    required this.children,
    this.panelColor = const Color(0xFF303030),
    this.handleColor = Colors.teal,
    this.handleIconOpened = Icons.chevron_right,
    this.handleIconClosed = Icons.chevron_left,
    this.handleWidth = 32.0,
    this.handleVisibleHeight = 56.0,
    this.panelContentWidth = 220.0,
    this.animationDuration = const Duration(milliseconds: 280),
    this.animationCurve = Curves.easeInOutCubic,
    this.topOffset = 100.0,
    this.itemSpacing = 10.0,
    this.initiallyOpen = false,
    this.panelBorderRadius,
    this.panelBoxShadow,
  });

  @override
  _EdgePullOutPanelState createState() => _EdgePullOutPanelState();
}

class _EdgePullOutPanelState extends State<EdgePullOutPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late bool _isPanelOpen;

  @override
  void initState() {
    super.initState();
    _isPanelOpen = widget.initiallyOpen;
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: _isPanelOpen ? 1.0 : 0.0,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() {
      _isPanelOpen = !_isPanelOpen;
      if (_isPanelOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // 默认的整个面板（把手+内容区组合体）的外部圆角，主要是左侧
    final BorderRadiusGeometry effectivePanelBorderRadius =
        widget.panelBorderRadius ??
            BorderRadius.only(
              topLeft:
                  Radius.circular(widget.handleWidth / 2.5), // 根据把手宽度调整圆角大小
              bottomLeft: Radius.circular(widget.handleWidth / 2.5),
            );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double currentRightOffset = lerpDouble(
          -widget.panelContentWidth,
          0.0,
          _animationController.value,
        )!;

        return Positioned(
          top: widget.topOffset,
          right: currentRightOffset,
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            // Material 的 borderRadius 应用于整体阴影和裁剪
            borderRadius: effectivePanelBorderRadius,
            child: Container(
              // 内部 Container 负责背景和可能的细化圆角，其阴影由 Material 提供
              decoration: BoxDecoration(
                // 阴影由外层 Material 处理，这里不需要再设置，除非想要覆盖
                // boxShadow: widget.panelBoxShadow ?? defaultBoxShadow,
                borderRadius: effectivePanelBorderRadius, // 保持和 Material 一致
              ),
              // 使用 ClipRRect 来确保子组件（把手和内容面板）严格遵守圆角
              child: ClipRRect(
                borderRadius: effectivePanelBorderRadius,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // --- 把手 (Handle) ---
                    GestureDetector(
                      onTap: _togglePanel,
                      child: Container(
                        width: widget.handleWidth,
                        height: widget.handleVisibleHeight,
                        // 把手的颜色和可能的独立圆角（如果它不完全共享外部圆角）
                        // 在这里，它应该只负责自己的颜色，圆角由 ClipRRect 控制
                        decoration: BoxDecoration(
                          color: widget.handleColor,
                          // 把手左侧的圆角由外部 ClipRRect 保证
                          // 如果把手高度大于面板内容高度，或者需要特殊处理，这里可以再细化
                        ),
                        child: IconTheme(
                          data: IconThemeData(
                            color: theme.iconTheme.color ?? Colors.white,
                            size: widget.handleWidth * 0.6,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: widget.animationDuration * 0.6,
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                    scale: animation, child: child);
                              },
                              child: Icon(
                                _isPanelOpen
                                    ? widget.handleIconOpened
                                    : widget.handleIconClosed,
                                key: ValueKey<bool>(_isPanelOpen),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // --- 内容区 (Panel Content) ---
                    Container(
                      width: widget.panelContentWidth,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height -
                            widget.topOffset -
                            20,
                      ),
                      // 内容区的背景色，圆角由外部 ClipRRect 控制
                      color: widget.panelColor,
                      child: SingleChildScrollView(
                        physics: _isPanelOpen &&
                                _animationController.status ==
                                    AnimationStatus.completed
                            ? const ClampingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.itemSpacing * 1.5,
                          vertical: widget.itemSpacing,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children:
                              widget.children.asMap().entries.map((entry) {
                            int idx = entry.key;
                            Widget child = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: (idx == widget.children.length - 1)
                                      ? 0
                                      : widget.itemSpacing),
                              child: child,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
