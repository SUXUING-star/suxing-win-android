// lib/widgets/ui/animation/animated_masonry_grid_view.dart

/// 该文件定义了 `_MasonryGridItemAnimator` 组件，用于为瀑布流网格项添加动画。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // 导入瀑布流网格视图库

/// `_MasonryGridItemAnimator` 类：网格项动画组件。
///
/// 这是一个无状态组件，接收动画值并应用于子组件。
class _MasonryGridItemAnimator extends StatelessWidget {
  final Animation<double> animation; // 驱动子组件的动画
  final Widget child; // 要应用动画的子组件

  /// 构造函数。
  ///
  /// [animation]：动画实例。
  /// [child]：子组件。
  const _MasonryGridItemAnimator(
      {required this.animation, required this.child});

  /// 构建瀑布流网格项动画组件。
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

/// `AnimatedMasonryGridView` 类：一个通用的、带交错入场动画的瀑布流网格视图组件。
///
/// 该组件内部管理一个 AnimationController 来驱动所有子项的动画。
class AnimatedMasonryGridView<T> extends StatefulWidget {
  final List<T> items; // 网格显示的数据列表
  final Widget Function(BuildContext context, int index, T item)
      itemBuilder; // 网格项构建器
  final int crossAxisCount; // 交叉轴上的项数
  final double mainAxisSpacing; // 主轴方向的间距
  final double crossAxisSpacing; // 交叉轴方向的间距
  final EdgeInsetsGeometry padding; // 网格的内边距
  final Key? gridKey; // 网格的 Key
  final Duration staggerDuration; // 每个网格项的交错动画延迟
  final Duration animationDuration; // 单个网格项的动画时长

  /// 构造函数。
  ///
  /// [items]：数据列表。
  /// [itemBuilder]：项构建器。
  /// [crossAxisCount]：交叉轴项数。
  /// [mainAxisSpacing]：主轴间距。
  /// [crossAxisSpacing]：交叉轴间距。
  /// [padding]：内边距。
  /// [gridKey]：网格键。
  /// [staggerDuration]：交错时长。
  /// [animationDuration]：动画时长。
  const AnimatedMasonryGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.padding = const EdgeInsets.all(16.0),
    this.gridKey,
    this.staggerDuration = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 450),
  });

  /// 创建状态。
  @override
  State<AnimatedMasonryGridView<T>> createState() =>
      _AnimatedMasonryGridViewState<T>();
}

/// `_AnimatedMasonryGridViewState` 类：`AnimatedMasonryGridView` 的状态管理。
///
/// 管理动画控制器及其生命周期，并根据数据变化更新动画。
class _AnimatedMasonryGridViewState<T> extends State<AnimatedMasonryGridView<T>>
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
  void didUpdateWidget(covariant AnimatedMasonryGridView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      // 数据项数量变化时
      _controller.duration = _calculateTotalDuration(); // 更新总动画时长
      _controller.forward(from: 0.0); // 从头开始播放动画
    }
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

  @override
  void dispose() {
    _controller.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 构建带交错入场动画的瀑布流网格视图。
  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      key: widget.gridKey, // 网格的 Key
      crossAxisCount: widget.crossAxisCount, // 交叉轴项数
      mainAxisSpacing: widget.mainAxisSpacing, // 主轴间距
      crossAxisSpacing: widget.crossAxisSpacing, // 交叉轴间距
      padding: widget.padding, // 内边距
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

        return _MasonryGridItemAnimator(
          animation: animation, // 动画实例
          child:
              widget.itemBuilder(context, index, widget.items[index]), // 构建网格项
        );
      },
    );
  }
}
