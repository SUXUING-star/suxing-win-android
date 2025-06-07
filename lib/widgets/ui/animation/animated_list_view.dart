import 'package:flutter/material.dart'; // 导入 Flutter UI 组件

/// `_ListItemAnimator` 类：列表项动画组件。
///
/// 这是一个无状态组件，接收动画值并应用于子组件。
class _ListItemAnimator extends StatelessWidget {
  final Animation<double> animation; // 驱动子组件的动画
  final Widget child; // 要应用动画的子组件

  /// 构造函数。
  ///
  /// [animation]：动画实例。
  /// [child]：子组件。
  const _ListItemAnimator({required this.animation, required this.child});

  /// 构建列表项动画组件。
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

/// `AnimatedListView` 类：通用的、自带交错入场动画的 ListView 组件。
///
/// 该组件内部管理一个 AnimationController 来驱动所有子项的动画。
class AnimatedListView<T> extends StatefulWidget {
  final List<T> items; // 列表显示的数据列表
  final Widget Function(BuildContext context, int index, T item)
      itemBuilder; // 列表项构建器
  final EdgeInsetsGeometry padding; // 列表的内边距
  final ScrollPhysics? physics; // 列表的滚动物理
  final Key? listKey; // 列表的 Key
  final bool shrinkWrap; // 列表是否根据内容收缩
  final Duration staggerDuration; // 每个列表项的交错动画延迟
  final Duration animationDuration; // 单个列表项的动画时长

  /// 构造函数。
  ///
  /// [items]：数据列表。
  /// [itemBuilder]：项构建器。
  /// [padding]：内边距。
  /// [physics]：滚动物理。
  /// [listKey]：列表键。
  /// [shrinkWrap]：是否收缩。
  /// [staggerDuration]：交错时长。
  /// [animationDuration]：动画时长。
  const AnimatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(8.0),
    this.physics,
    this.listKey,
    this.shrinkWrap = false,
    this.staggerDuration = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 450),
  });

  /// 创建状态。
  @override
  State<AnimatedListView<T>> createState() => _AnimatedListViewState<T>();
}

/// `_AnimatedListViewState` 类：`AnimatedListView` 的状态管理。
///
/// 管理动画控制器及其生命周期，并根据数据变化更新动画。
class _AnimatedListViewState<T> extends State<AnimatedListView<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller; // 动画控制器

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration, // 动画持续时间
    );
    _controller.forward(); // 启动动画
  }

  @override
  void didUpdateWidget(covariant AnimatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      // 列表项数量变化时
      _controller.forward(from: 0.0); // 从头开始播放动画
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 构建带交错入场动画的 ListView。
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: widget.listKey, // 列表的 Key
      shrinkWrap: widget.shrinkWrap, // 是否收缩
      padding: widget.padding, // 内边距
      physics: widget.physics, // 滚动物理
      itemCount: widget.items.length, // 列表项数量
      itemBuilder: (context, index) {
        final double startTime =
            (widget.staggerDuration.inMilliseconds * index) /
                _controller.duration!.inMilliseconds; // 计算动画开始时间
        final double endTime = startTime +
            (widget.animationDuration.inMilliseconds / 2) /
                _controller.duration!.inMilliseconds; // 计算动画结束时间

        final animation = CurvedAnimation(
          parent: _controller, // 父动画控制器
          curve: Interval(
            startTime.clamp(0.0, 1.0), // 动画开始区间
            endTime.clamp(0.0, 1.0), // 动画结束区间
            curve: Curves.ease, // 动画曲线
          ),
        );

        return _ListItemAnimator(
          animation: animation, // 动画实例
          child:
              widget.itemBuilder(context, index, widget.items[index]), // 构建子项
        );
      },
    );
  }
}
