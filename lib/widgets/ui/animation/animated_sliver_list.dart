// lib/widgets/ui/animation/animated_sliver_list.dart

/// 该文件定义了 `_SliverListItemAnimator` 组件，用于为 Sliver 列表项添加动画。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件

/// `_SliverListItemAnimator` 类：Sliver 列表项动画组件。
///
/// 这是一个无状态组件，接收动画值并应用于子组件。
class _SliverListItemAnimator extends StatelessWidget {
  final Animation<double> animation; // 驱动子组件的动画
  final Widget child; // 要应用动画的子组件

  /// 构造函数。
  ///
  /// [animation]：动画实例。
  /// [child]：子组件。
  const _SliverListItemAnimator({required this.animation, required this.child});

  /// 构建 Sliver 列表项动画组件。
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

/// `AnimatedSliverList` 类：通用的、带交错入场动画的 SliverList 组件。
///
/// 该组件内部管理一个 AnimationController 来驱动所有子项的动画。
class AnimatedSliverList<T> extends StatefulWidget {
  final List<T> items; // 列表显示的数据列表
  final Widget Function(BuildContext context, int index, T item)
      itemBuilder; // 列表项构建器
  final Duration staggerDuration; // 每个列表项的交错动画延迟
  final Duration animationDuration; // 单个列表项的动画时长

  /// 构造函数。
  ///
  /// [items]：数据列表。
  /// [itemBuilder]：项构建器。
  /// [staggerDuration]：交错时长。
  /// [animationDuration]：动画时长。
  const AnimatedSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.staggerDuration = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 450),
  });

  /// 创建状态。
  @override
  State<AnimatedSliverList<T>> createState() => _AnimatedSliverListState<T>();
}

/// `_AnimatedSliverListState` 类：`AnimatedSliverList` 的状态管理。
///
/// 管理动画控制器及其生命周期，并根据数据变化更新动画。
class _AnimatedSliverListState<T> extends State<AnimatedSliverList<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller; // 动画控制器

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: _calculateTotalDuration()); // 初始化动画控制器
    _controller.forward(); // 启动动画
  }

  @override
  void didUpdateWidget(covariant AnimatedSliverList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      // 列表项数量变化时
      _controller.duration = _calculateTotalDuration(); // 更新总动画时长
      _controller.forward(from: 0.0); // 从头开始播放动画
    }
  }

  /// 计算所有列表项的总动画时长。
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

  @override
  void dispose() {
    _controller.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 构建带交错入场动画的 SliverList。
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
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

          return _SliverListItemAnimator(
            animation: animation, // 动画实例
            child:
                widget.itemBuilder(context, index, widget.items[index]), // 构建子项
          );
        },
        childCount: widget.items.length, // 列表项数量
      ),
    );
  }
}
