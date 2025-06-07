// lib/widgets/ui/buttons/expandable_fab_menu.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;


const _fabDimension = 56.0; // Standard FAB size

@immutable
class ExpandableFabAction {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip; // 为子按钮添加tooltip
  final Color? backgroundColor; // 子按钮背景色
  final Color? foregroundColor; // 子按钮图标颜色

  const ExpandableFabAction({
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });
}

class ExpandableFabMenu extends StatefulWidget {
  final bool initiallyOpen;
  final double distance; // 子按钮与主按钮的距离
  final List<ExpandableFabAction> children;
  final IconData openIcon;
  final IconData closeIcon;
  final String? openTooltip;
  final String? closeTooltip;
  final Color? toggleButtonBackgroundColor;
  final Color? toggleButtonForegroundColor;
  final Object? toggleButtonHeroTag;
  final Duration animationDuration;
  final bool useModalBarrier; // 是否使用模态背景遮罩
  final Color modalBarrierColor; // 遮罩颜色

  const ExpandableFabMenu({
    Key? key,
    this.initiallyOpen = false,
    this.distance = 90.0, // 默认距离
    required this.children,
    this.openIcon = Icons.add,
    this.closeIcon = Icons.close,
    this.openTooltip = '展开',
    this.closeTooltip = '收起',
    this.toggleButtonBackgroundColor,
    this.toggleButtonForegroundColor,
    this.toggleButtonHeroTag, // HeroTag for the main button
    this.animationDuration = const Duration(milliseconds: 250),
    this.useModalBarrier = true, // 默认使用遮罩
    this.modalBarrierColor = Colors.black38, // 默认遮罩颜色
  }) : super(key: key);

  @override
  _ExpandableFabMenuState createState() => _ExpandableFabMenuState();
}

class _ExpandableFabMenuState extends State<ExpandableFabMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotateAnimation;
  bool _open = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink(); // 用于连接主按钮和Overlay

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: widget.animationDuration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.375).animate(// 旋转135度
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _overlayEntry = _buildOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
        _controller.forward();
      } else {
        _controller.reverse().then<void>((void value) {
          if (_overlayEntry != null && mounted) {
            // 确保组件还挂载
            _overlayEntry!.remove();
            _overlayEntry = null;
          }
        });
      }
    });
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: _fabDimension,
      height: _fabDimension,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          color: widget.toggleButtonBackgroundColor ??
              Theme.of(context).colorScheme.secondary,
          child: InkWell(
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value * math.pi * 2,
                  child: Icon(
                    _open ? widget.closeIcon : widget.openIcon,
                    color: widget.toggleButtonForegroundColor ??
                        Theme.of(context).colorScheme.onSecondary,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  OverlayEntry _buildOverlayEntry() {
    RenderBox renderBox = context.findRenderObject()! as RenderBox;
    // var size = renderBox.size; // 主按钮的尺寸，这里我们用标准 _fabDimension
    // var offset = renderBox.localToGlobal(Offset.zero); // 主按钮的全局位置

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: <Widget>[
            // --- 模态背景遮罩 ---
            if (widget.useModalBarrier)
              GestureDetector(
                onTap: _toggle, // 点击遮罩关闭
                child: AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: Tween<double>(begin: 0.0, end: 1.0)
                          .animate(_expandAnimation)
                          .value,
                      child: Container(
                        color: widget.modalBarrierColor,
                      ),
                    );
                  },
                ),
              ),
            // --- 子按钮 ---
            // 使用 CompositedTransformFollower 将子按钮定位到主按钮附近
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, -widget.distance), // 默认向上偏移
              child: Align(
                alignment: Alignment.bottomCenter, // 以主按钮的底部中心为基点
                child: IgnorePointer(
                  // 通过 _open 控制是否可交互
                  ignoring: !_open,
                  child: Material(
                    // Material for elevation and theming of children
                    color: Colors.transparent, // Overlay is transparent
                    child: _buildExpandingActionButtons(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    // 简单的向上垂直排列，可以修改为扇形
    // 例如，对于扇形展开，每个 child 的 offset 会不同
    final double initialAngle = -math.pi / 2; // 向上为 -90度
    final double sweepAngle = math.pi / (count + 1); // 假设90度扇形展开

    for (var i = 0; i < count; i++) {
      // 简单的垂直向上排列，每个按钮之间加一点点间隔
      final Offset offset;
      if (count == 1) {
        offset =
            Offset(0, -(i + 1) * (_fabDimension + 16.0)); // _fabDimension + 间距
      } else {
        // 扇形排布的简单示例 (向上方90度扇形展开)
        // 如果是垂直排列，则x=0
        // final double angle = initialAngle + (i + 1) * sweepAngle - (sweepAngle * count / 2) + sweepAngle/2 ; // 使其居中
        // 如果想简单向上垂直，可以注释掉下面几行，用上面 count == 1 的逻辑或者更简单的 Column
        final double angle = -math.pi / 2; // 固定向上
        final double itemDistance =
            (i + 1) * (_fabDimension * 0.8 + 16.0); // 子按钮之间的距离，略小于FAB尺寸
        offset = Offset(
          math.cos(angle) * itemDistance, // 如果垂直则为0
          math.sin(angle) * itemDistance, // 向上为负
        );
      }

      children.add(
        _ExpandingActionButton(
          directionInDegrees: 0, // 这个参数可以用来做更复杂的扇形动画，这里简化
          maxDistance: widget.distance, // 这个也不是必须的，因为我们用了固定offset
          progress: _expandAnimation,
          offset: offset, // 应用计算好的偏移
          child: _buildSmallFab(widget.children[i]),
        ),
      );
    }

    return IgnorePointer(
      ignoring: !_open,
      child: Padding(
        // 这个padding可以微调子按钮群组相对于主按钮的整体位置
        padding:
            const EdgeInsets.only(bottom: _fabDimension + 16.0), // 主按钮高度 + 额外间距
        child: Column(
          // 改为Column，更简单地向上排列
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // 子按钮居中对齐
          children: children.reversed.toList(), // 从下往上排列，所以reversed
        ),
      ),
    );
    // 如果用Stack做扇形，大概是这样：
    // return Stack(
    //   alignment: Alignment.center,
    //   clipBehavior: Clip.none, // Important for children to go outside bounds
    //   children: children,
    // );
  }

  Widget _buildSmallFab(ExpandableFabAction action) {
    final theme = Theme.of(context);
    return FloatingActionButton.small(
      // 使用小号 FAB
      heroTag: null, // 子按钮通常不需要 heroTag，除非有特殊需求
      backgroundColor:
          action.backgroundColor ?? theme.colorScheme.secondaryContainer,
      foregroundColor:
          action.foregroundColor ?? theme.colorScheme.onSecondaryContainer,
      onPressed: () {
        action.onPressed?.call();
        _toggle(); // 点击子按钮后关闭菜单
      },
      tooltip: action.tooltip,
      child: action.icon,
      elevation: 4.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用 CompositedTransformTarget 来标记主按钮的位置
    return CompositedTransformTarget(
      link: _layerLink,
      child: _buildTapToCloseFab(),
    );
  }
}

// 子按钮的动画包装器
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
    required this.offset,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;
  final Offset offset; // 直接使用计算好的偏移

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, snapshotChild) {
        // finalOffset 计算可以更复杂，比如扇形展开时每个按钮的最终位置
        // 这里我们直接使用传入的 offset，配合 progress 做动画
        final double progressValue = progress.value;
        // final Offset currentOffset = Offset.lerp(Offset.zero, offset, progressValue)!; // 从中心点移出
        final Offset currentOffset = offset * progressValue; // 或者简单的按比例移动

        return Transform.translate(
          offset: currentOffset,
          child: FadeTransition(
            opacity: progress, // 淡入淡出
            child: ScaleTransition(
              // 缩放动画
              scale: progress,
              child: snapshotChild,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
