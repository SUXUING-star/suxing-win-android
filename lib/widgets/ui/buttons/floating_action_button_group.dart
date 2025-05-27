// lib/widgets/ui/buttons/floating_action_button_group.dart
import 'package:flutter/material.dart';
import 'dart:async'; // 用于 Timer
import 'dart:math' as math;
import 'generic_fab.dart';

class FloatingActionButtonGroup extends StatefulWidget {
  final List<Widget> children;
  final double spacing;
  final MainAxisAlignment alignment;
  final MainAxisSize mainAxisSize;
  final IconData expandIcon;
  final IconData collapseIcon;
  final Color? toggleButtonBackgroundColor;
  final Color? toggleButtonForegroundColor;
  final Object? toggleButtonHeroTag;
  final bool initiallyExpanded;
  final Duration animationDuration;
  final Duration autoExpandDelay; // 新增：悬停展开延迟
  final bool expandOnHover; // 新增：是否悬停展开
  final bool collapseOnExit; // 新增：是否悬停离开后收起
  final bool collapseOnTapChild; // 新增：点击子项后是否收起

  const FloatingActionButtonGroup({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.alignment = MainAxisAlignment.end,
    this.mainAxisSize = MainAxisSize.min,
    this.expandIcon = Icons.menu, // 改成更通用的菜单图标
    this.collapseIcon = Icons.close, // 改成关闭图标
    this.toggleButtonBackgroundColor,
    this.toggleButtonForegroundColor,
    this.toggleButtonHeroTag = const _DefaultHeroTag('toggle_fab_group_v2'),
    this.initiallyExpanded = false,
    this.animationDuration = const Duration(milliseconds: 250),
    this.autoExpandDelay = const Duration(milliseconds: 150), // 默认150ms延迟
    this.expandOnHover = true, // 默认开启悬停展开
    this.collapseOnExit = true, // 默认开启离开收起
    this.collapseOnTapChild = true, // 默认点击子项后收起
  });

  @override
  State<FloatingActionButtonGroup> createState() =>
      _FloatingActionButtonGroupState();
}

class _DefaultHeroTag {
  final String description;
  const _DefaultHeroTag(this.description);
  @override
  String toString() => 'Default HeroTag: $description';
}

class _FloatingActionButtonGroupState extends State<FloatingActionButtonGroup>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;

  Timer? _hoverExpandTimer;
  Timer? _hoverCollapseTimer; // 可选，如果离开也想延迟

  bool _isHovering = false; // 跟踪鼠标是否在整个组上

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rotateAnimation =
        Tween<double>(begin: 0.0, end: 0.375) // 旋转135度 (Menu -> Close)
            .animate(CurvedAnimation(
                parent: _animationController, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _hoverExpandTimer?.cancel();
    _hoverCollapseTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _setExpanded(bool expand) {
    if (!mounted || _isExpanded == expand) return; // 防止重复设置或已卸载
    setState(() {
      _isExpanded = expand;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _manualToggleExpand() {
    // 点击主按钮仍然可以切换状态，除非完全由hover控制
    _hoverExpandTimer?.cancel();
    _hoverCollapseTimer?.cancel();
    _setExpanded(!_isExpanded);
  }

  void _handlePointerEnter(PointerEvent details) {
    if (!widget.expandOnHover || _isExpanded) return;
    _isHovering = true;
    _hoverCollapseTimer?.cancel(); // 如果之前有离开的计时器，取消它
    _hoverExpandTimer?.cancel(); // 取消可能存在的旧的展开计时器
    _hoverExpandTimer = Timer(widget.autoExpandDelay, () {
      if (_isHovering && mounted) {
        // 确保鼠标仍悬停且组件挂载
        _setExpanded(true);
      }
    });
  }

  void _handlePointerExit(PointerEvent details) {
    if (!widget.collapseOnExit || !_isExpanded) return;
    _isHovering = false;
    _hoverExpandTimer?.cancel(); // 如果鼠标移开时还没来得及展开，取消展开
    // 可以选择立即收起或也加一个短暂延迟
    // 为了快速响应，这里选择立即尝试收起（如果已展开）
    // _hoverCollapseTimer = Timer(Duration(milliseconds: 50), () { // 示例：离开也延迟
    if (!_isHovering && mounted) {
      // 确保鼠标确实已离开
      _setExpanded(false);
    }
    // });
  }

  Widget _wrapChild(Widget child) {
    if (!widget.collapseOnTapChild) return child;

    // 如果子项是 Button 类或有 onPressed，尝试包裹 GestureDetector
    // 这是一个简化处理，更健壮的方式是让子项自己调用一个关闭回调
    if (child is ElevatedButton ||
        child is TextButton ||
        child is OutlinedButton ||
        child is IconButton ||
        child is FloatingActionButton ||
        child is GenericFloatingActionButton) {
      // 尝试获取 onPressed 回调
      VoidCallback? originalOnPressed;
      if (child is ElevatedButton) {
        originalOnPressed = child.onPressed;
      } else if (child is TextButton) {
        originalOnPressed = child.onPressed;
      } else if (child is OutlinedButton) {
        originalOnPressed = child.onPressed;
      } else if (child is IconButton) {
        originalOnPressed = child.onPressed;
      } else if (child is FloatingActionButton) {
        originalOnPressed = child.onPressed;
      } else if (child is GenericFloatingActionButton) {
        originalOnPressed = child.onPressed;
      }

      return GestureDetector(
        onTap: () {
          originalOnPressed?.call(); // 执行原始的 onTap
          if (widget.collapseOnTapChild && _isExpanded) {
            _hoverExpandTimer?.cancel();
            _hoverCollapseTimer?.cancel();
            _setExpanded(false); // 点击子项后收起
          }
        },
        child: AbsorbPointer(absorbing: false, child: child), // 确保原始按钮的点击事件仍能穿透
      );
    }
    // 对于其他类型的子组件，或者没有 onPressed 的，简单返回
    // 或者更复杂地，可以提供一个回调给子组件，让它们在被点击时通知父组件收起
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        widget.toggleButtonBackgroundColor ?? theme.colorScheme.secondary;
    final fgColor =
        widget.toggleButtonForegroundColor ?? theme.colorScheme.onSecondary;

    final validChildren = widget.children.toList();

    // 整个组件的 MouseRegion，用于悬停展开/收起
    return MouseRegion(
      onEnter: _handlePointerEnter,
      onExit: _handlePointerExit,
      child: Column(
        mainAxisAlignment: widget.alignment,
        mainAxisSize: widget.mainAxisSize,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ----- 子按钮部分 (带动画) -----
          AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                if (_animationController.value == 0 && !_isExpanded) {
                  return const SizedBox.shrink();
                }
                return FadeTransition(
                    opacity: _opacityAnimation,
                    child: IgnorePointer(
                        ignoring: !_isExpanded &&
                            _animationController.status !=
                                AnimationStatus.forward,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: widget.spacing),
                          child: Column(
                            mainAxisAlignment: widget.alignment,
                            mainAxisSize: widget.mainAxisSize,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: validChildren
                                .expand((subChild) => [
                                      _wrapChild(subChild), // 包裹子项以处理点击后收起
                                      if (subChild != validChildren.last)
                                        SizedBox(height: widget.spacing),
                                    ])
                                .toList(),
                          ),
                        )));
              }),

          // ----- 主切换按钮 -----
          // 主按钮也响应点击事件
          GenericFloatingActionButton(
            onPressed: _manualToggleExpand, // 点击主按钮依然可以切换
            tooltip: _isExpanded ? '收起' : '展开',
            heroTag: widget.toggleButtonHeroTag,
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            child: AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value * math.pi * 2,
                  child: Icon(
                      _isExpanded ? widget.collapseIcon : widget.expandIcon),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
