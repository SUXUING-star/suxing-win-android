// lib/widgets/ui/buttons/floating_action_button_group.dart

/// 该文件定义了 FloatingActionButtonGroup 组件，一个通用的悬浮动作按钮组。
/// 该组件管理一组悬浮动作按钮的展开、收起和动画。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'dart:async'; // 导入 Timer
import 'dart:math' as math; // 导入数学函数
import 'generic_fab.dart'; // 导入通用悬浮动作按钮

/// `FloatingActionButtonGroup` 类：一个通用的悬浮动作按钮组组件。
///
/// 该组件管理其子按钮的展开和收起状态，支持手动切换和悬停触发。
class FloatingActionButtonGroup extends StatefulWidget {
  final List<Widget> children; // 按钮组的子按钮列表
  final double spacing; // 子按钮之间的间距
  final MainAxisAlignment alignment; // 按钮组的主轴对齐方式
  final MainAxisSize mainAxisSize; // 按钮组的主轴尺寸
  final IconData expandIcon; // 展开状态的主按钮图标
  final IconData collapseIcon; // 收起状态的主按钮图标
  final Color? toggleButtonBackgroundColor; // 切换按钮背景色
  final Color? toggleButtonForegroundColor; // 切换按钮前景色
  final Object? toggleButtonHeroTag; // 切换按钮的 Hero 动画标签
  final bool initiallyExpanded; // 初始是否展开
  final Duration animationDuration; // 展开/收起动画时长
  final Duration autoExpandDelay; // 悬停展开延迟
  final bool expandOnHover; // 是否支持悬停展开
  final bool collapseOnExit; // 是否支持悬停离开后收起
  final bool collapseOnTapChild; // 点击子项后是否收起

  /// 构造函数。
  ///
  /// [children]：子按钮列表。
  /// [spacing]：间距。
  /// [alignment]：对齐方式。
  /// [mainAxisSize]：主轴尺寸。
  /// [expandIcon]：展开图标。
  /// [collapseIcon]：收起图标。
  /// [toggleButtonBackgroundColor]：切换按钮背景色。
  /// [toggleButtonForegroundColor]：切换按钮前景色。
  /// [toggleButtonHeroTag]：切换按钮 Hero 标签。
  /// [initiallyExpanded]：初始展开状态。
  /// [animationDuration]：动画时长。
  /// [autoExpandDelay]：自动展开延迟。
  /// [expandOnHover]：是否悬停展开。
  /// [collapseOnExit]：是否离开收起。
  /// [collapseOnTapChild]：点击子项后是否收起。
  const FloatingActionButtonGroup({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.alignment = MainAxisAlignment.end,
    this.mainAxisSize = MainAxisSize.min,
    this.expandIcon = Icons.menu,
    this.collapseIcon = Icons.close,
    this.toggleButtonBackgroundColor,
    this.toggleButtonForegroundColor,
    this.toggleButtonHeroTag = const _DefaultHeroTag('toggle_fab_group_v2'),
    this.initiallyExpanded = false,
    this.animationDuration = const Duration(milliseconds: 250),
    this.autoExpandDelay = const Duration(milliseconds: 150),
    this.expandOnHover = true,
    this.collapseOnExit = true,
    this.collapseOnTapChild = true,
  });

  /// 创建状态。
  @override
  State<FloatingActionButtonGroup> createState() =>
      _FloatingActionButtonGroupState();
}

/// `_DefaultHeroTag` 类：默认 Hero 标签。
///
/// 提供一个描述字符串作为 Hero 标签。
class _DefaultHeroTag {
  final String description; // 标签描述
  /// 构造函数。
  const _DefaultHeroTag(this.description);

  /// 返回标签的字符串表示。
  @override
  String toString() => '默认 HeroTag: $description';
}

/// `_FloatingActionButtonGroupState` 类：`FloatingActionButtonGroup` 的状态管理。
///
/// 管理按钮组的展开状态、动画和悬停交互。
class _FloatingActionButtonGroupState extends State<FloatingActionButtonGroup>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded; // 当前展开状态
  late AnimationController _animationController; // 动画控制器
  late Animation<double> _rotateAnimation; // 旋转动画
  late Animation<double> _opacityAnimation; // 透明度动画

  Timer? _hoverExpandTimer; // 悬停展开计时器
  Timer? _hoverCollapseTimer; // 悬停收起计时器

  bool _isHovering = false; // 鼠标是否悬停在整个按钮组上

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded; // 初始化展开状态

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.375) // 旋转 135 度
        .animate(CurvedAnimation(
            parent: _animationController, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (_isExpanded) {
      _animationController.value = 1.0; // 如果初始展开，设置动画值
    }
  }

  @override
  void dispose() {
    _hoverExpandTimer?.cancel(); // 取消悬停展开计时器
    _hoverCollapseTimer?.cancel(); // 取消悬停收起计时器
    _animationController.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 设置按钮组的展开状态。
  ///
  /// [expand]：新的展开状态。
  void _setExpanded(bool expand) {
    if (!mounted || _isExpanded == expand) return; // 防止重复设置或组件未挂载
    setState(() {
      _isExpanded = expand; // 更新展开状态
      if (_isExpanded) {
        _animationController.forward(); // 启动展开动画
      } else {
        _animationController.reverse(); // 启动收起动画
      }
    });
  }

  /// 手动切换展开状态。
  void _manualToggleExpand() {
    _hoverExpandTimer?.cancel(); // 取消悬停展开计时器
    _hoverCollapseTimer?.cancel(); // 取消悬停收起计时器
    _setExpanded(!_isExpanded); // 切换展开状态
  }

  /// 处理鼠标进入事件。
  ///
  /// [details]：指针事件详情。
  void _handlePointerEnter(PointerEvent details) {
    if (!widget.expandOnHover || _isExpanded) return; // 不支持悬停展开或已展开时返回
    _isHovering = true; // 设置悬停状态
    _hoverCollapseTimer?.cancel(); // 取消悬停收起计时器
    _hoverExpandTimer?.cancel(); // 取消悬停展开计时器
    _hoverExpandTimer = Timer(widget.autoExpandDelay, () {
      if (_isHovering && mounted) {
        // 鼠标仍悬停且组件挂载时展开
        _setExpanded(true); // 展开按钮组
      }
    });
  }

  /// 处理鼠标离开事件。
  ///
  /// [details]：指针事件详情。
  void _handlePointerExit(PointerEvent details) {
    if (!widget.collapseOnExit || !_isExpanded) return; // 不支持离开收起或未展开时返回
    _isHovering = false; // 取消悬停状态
    _hoverExpandTimer?.cancel(); // 取消悬停展开计时器
    if (!_isHovering && mounted) {
      // 鼠标已离开且组件挂载时收起
      _setExpanded(false); // 收起按钮组
    }
  }

  /// 包裹子按钮以处理点击后收起逻辑。
  ///
  /// [child]：子按钮组件。
  /// 返回包裹后的子按钮组件。
  Widget _wrapChild(Widget child) {
    if (!widget.collapseOnTapChild) return child; // 不支持点击子项后收起时直接返回

    VoidCallback? originalOnPressed; // 原始点击回调
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
        originalOnPressed?.call(); // 执行原始点击回调
        if (widget.collapseOnTapChild && _isExpanded) {
          // 点击子项后收起
          _hoverExpandTimer?.cancel(); // 取消悬停展开计时器
          _hoverCollapseTimer?.cancel(); // 取消悬停收起计时器
          _setExpanded(false); // 收起按钮组
        }
      },
      child: AbsorbPointer(absorbing: false, child: child), // 确保原始按钮的点击事件穿透
    );
  }

  /// 构建悬浮动作按钮组组件。
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 当前主题
    final bgColor = widget.toggleButtonBackgroundColor ??
        theme.colorScheme.secondary; // 切换按钮背景色
    final fgColor = widget.toggleButtonForegroundColor ??
        theme.colorScheme.onSecondary; // 切换按钮前景色

    final validChildren = widget.children.toList(); // 有效的子按钮列表

    return MouseRegion(
      // 鼠标区域，用于悬停事件
      onEnter: _handlePointerEnter, // 鼠标进入回调
      onExit: _handlePointerExit, // 鼠标离开回调
      child: Column(
        mainAxisAlignment: widget.alignment, // 主轴对齐方式
        mainAxisSize: widget.mainAxisSize, // 主轴尺寸
        crossAxisAlignment: CrossAxisAlignment.end, // 交叉轴末尾对齐
        children: [
          AnimatedBuilder(
              animation: _animationController, // 动画控制器
              builder: (context, child) {
                if (_animationController.value == 0 && !_isExpanded) {
                  return const SizedBox.shrink(); // 动画值为 0 且未展开时隐藏
                }
                return FadeTransition(
                    // 淡入淡出动画
                    opacity: _opacityAnimation, // 透明度动画
                    child: IgnorePointer(
                        // 忽略指针事件
                        ignoring: !_isExpanded &&
                            _animationController.status !=
                                AnimationStatus.forward, // 动画播放时允许交互
                        child: Padding(
                          padding:
                              EdgeInsets.only(bottom: widget.spacing), // 底部填充
                          child: Column(
                            mainAxisAlignment: widget.alignment, // 主轴对齐方式
                            mainAxisSize: widget.mainAxisSize, // 主轴尺寸
                            crossAxisAlignment:
                                CrossAxisAlignment.end, // 交叉轴末尾对齐
                            children: validChildren
                                .expand((subChild) => [
                                      _wrapChild(subChild), // 包裹子项
                                      if (subChild != validChildren.last)
                                        SizedBox(
                                            height: widget.spacing), // 子项间距
                                    ])
                                .toList(),
                          ),
                        )));
              }),
          GenericFloatingActionButton(
            // 主切换按钮
            onPressed: _manualToggleExpand, // 点击回调
            tooltip: _isExpanded ? '收起' : '展开', // 提示文本
            heroTag: widget.toggleButtonHeroTag, // Hero 标签
            backgroundColor: bgColor, // 背景色
            foregroundColor: fgColor, // 前景色
            child: AnimatedBuilder(
              animation: _rotateAnimation, // 旋转动画
              builder: (context, child) {
                return Transform.rotate(
                  // 旋转变换
                  angle: _rotateAnimation.value * math.pi * 2, // 旋转角度
                  child: Icon(_isExpanded
                      ? widget.collapseIcon
                      : widget.expandIcon), // 图标
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
