// lib/widgets/ui/animation/animated_content_grid.dart
import 'package:flutter/material.dart';

/// `_GridItemAnimator` 类：网格项动画组件。
///
/// 这是一个无状态组件，接收动画值并应用于子组件。
class _GridItemAnimator extends StatelessWidget {
  final Animation<double> animation; // 驱动子组件的动画
  final Widget child; // 要应用动画的子组件

  /// 构造函数。
  ///
  /// [animation]：动画实例。
  /// [child]：子组件。
  const _GridItemAnimator({required this.animation, required this.child});

  /// 构建网格项动画组件。
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation, // 监听动画变化
      child: child, // 不随动画重建的子组件
      builder: (context, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation, // 父动画
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut), // 动画区间和曲线
          ),
          child: Transform.translate(
            offset: Offset(
              0,
              (1.0 -
                      CurvedAnimation(
                        parent: animation, // 父动画
                        curve: const Interval(0.0, 1.0,
                            curve: Curves.easeOut), // 动画区间和曲线
                      ).value) *
                  30, // 垂直位移量
            ),
            child: child, // 子组件
          ),
        );
      },
    );
  }
}

/// `AnimatedContentGrid` 类：通用的、带交错入场动画的 GridView 组件。
///
/// 该组件内部管理一个 AnimationController 来驱动所有子项的动画。
class AnimatedContentGrid<T> extends StatefulWidget {
  final List<T> items; // 网格显示的数据列表
  final Widget Function(BuildContext context, int index, T item)
      itemBuilder; // 网格项构建器
  final int crossAxisCount; // 交叉轴上的项数
  final double childAspectRatio; // 子项的宽高比
  final double crossAxisSpacing; // 交叉轴方向的间距
  final double mainAxisSpacing; // 主轴方向的间距
  final EdgeInsetsGeometry padding; // 网格的内边距
  final Key? gridKey; // 网格的 Key
  final bool shrinkWrap; // 网格是否根据内容收缩
  final ScrollPhysics? physics; // 网格的滚动物理
  final Duration staggerDuration; // 每个网格项的交错动画延迟
  final Duration animationDuration; // 单个网格项的动画时长

  /// 构造函数。
  ///
  /// [items]：数据列表。
  /// [itemBuilder]：项构建器。
  /// [crossAxisCount]：交叉轴项数。
  /// [childAspectRatio]：子项宽高比。
  /// [gridKey]：网格键。
  /// [crossAxisSpacing]：交叉轴间距。
  /// [mainAxisSpacing]：主轴间距。
  /// [padding]：内边距。
  /// [shrinkWrap]：是否收缩。
  /// [physics]：滚动物理。
  /// [staggerDuration]：交错时长。
  /// [animationDuration]：动画时长。
  const AnimatedContentGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.crossAxisCount,
    required this.childAspectRatio,
    this.gridKey,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding = const EdgeInsets.all(8.0),
    this.shrinkWrap = false,
    this.physics,
    this.staggerDuration = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 450),
  });

  /// 创建状态。
  @override
  State<AnimatedContentGrid<T>> createState() => _AnimatedContentGridState<T>();
}

/// `_AnimatedContentGridState` 类：`AnimatedContentGrid` 的状态管理。
///
/// 管理动画控制器及其生命周期，并根据数据变化更新动画。
class _AnimatedContentGridState<T> extends State<AnimatedContentGrid<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller; // 动画控制器

  @override
  void initState() {
    super.initState();
    final totalDuration = _calculateTotalDuration(); // 计算总动画时长
    _controller =
        AnimationController(vsync: this, duration: totalDuration); // 初始化动画控制器
    _controller.forward(); // 启动动画
  }

  @override
  void didUpdateWidget(covariant AnimatedContentGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      // 数据项数量变化时
      _controller.duration = _calculateTotalDuration(); // 更新总动画时长
      _controller.forward(from: 0.0); // 从头开始播放动画
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 计算所有网格项的总动画时长。
  ///
  /// 总时长等于单个动画时长加上所有交错延迟的总和。
  Duration _calculateTotalDuration() {
    if (widget.items.isEmpty) {
      // 数据项为空时返回零时长
      return Duration.zero;
    }
    final staggerTotalMilliseconds = widget.staggerDuration.inMilliseconds *
        (widget.items.length - 1); // 计算交错总毫秒
    final totalMilliseconds = widget.animationDuration.inMilliseconds +
        staggerTotalMilliseconds; // 计算总毫秒
    return Duration(milliseconds: totalMilliseconds); // 返回总时长
  }

  /// 构建带交错入场动画的 GridView。
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: widget.gridKey, // 网格的 Key
      shrinkWrap: widget.shrinkWrap, // 是否收缩
      physics: widget.physics, // 滚动物理
      padding: widget.padding, // 内边距
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount, // 交叉轴项数
        childAspectRatio: widget.childAspectRatio, // 子项宽高比
        crossAxisSpacing: widget.crossAxisSpacing, // 交叉轴间距
        mainAxisSpacing: widget.mainAxisSpacing, // 主轴间距
      ),
      itemCount: widget.items.length, // 网格项数量
      itemBuilder: (context, index) {
        final double startTime =
            (widget.staggerDuration.inMilliseconds * index) /
                _controller.duration!.inMilliseconds; // 计算动画开始时间
        final double endTime = startTime +
            (widget.animationDuration.inMilliseconds) /
                _controller.duration!.inMilliseconds; // 计算动画结束时间

        final animation = CurvedAnimation(
          parent: _controller, // 父动画控制器
          curve: Interval(
            startTime.clamp(0.0, 1.0), // 动画开始区间
            endTime.clamp(0.0, 1.0), // 动画结束区间
            curve: Curves.ease, // 动画曲线
          ),
        );

        return _GridItemAnimator(
          animation: animation, // 动画实例
          child:
              widget.itemBuilder(context, index, widget.items[index]), // 构建子项
        );
      },
    );
  }
}
