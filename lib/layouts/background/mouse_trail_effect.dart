// lib/layouts/background/mouse_trail_effect.dart

/// 该文件定义了 MouseTrailEffect 组件，用于在桌面应用中实现鼠标拖尾粒子效果。
/// MouseTrailEffect 在鼠标移动时生成并显示动态变化的粒子。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架
import 'dart:math' as math; // 数学函数所需
import 'dart:io' show Platform; // 平台检测所需
import 'package:flutter/foundation.dart' show kIsWeb; // Web 平台检测所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展

// --- 常量 ---
const double _kMinOpacity = 0.01; // 粒子最小不透明度
const double _kMinSize = 0.1; // 粒子最小尺寸
const Duration _kParticleUpdateInterval = Duration(milliseconds: 16); // 粒子更新间隔

/// `MouseTrailParticle` 类：鼠标拖尾粒子模型。
///
/// 包含粒子的位置、不透明度、尺寸、角度、速度、颜色和活动状态。
class MouseTrailParticle {
  Offset position; // 粒子位置
  double opacity; // 粒子不透明度
  double size; // 粒子尺寸
  double angle; // 粒子移动角度
  double speed; // 粒子移动速度
  Color color; // 粒子颜色
  bool isActive; // 粒子是否活跃

  /// 构造函数。
  MouseTrailParticle({
    required this.position,
    this.opacity = 1.0,
    this.size = 3.0,
    this.angle = 0.0,
    this.speed = 1.5,
    required this.color,
    this.isActive = false,
  });

  /// 重置粒子状态。
  ///
  /// [newPosition]：新位置。
  /// [newAngle]：新角度。
  /// [newSpeed]：新速度。
  /// [newSize]：新尺寸。
  /// [newOpacity]：新不透明度。
  /// [newColor]：新颜色。
  void reset({
    required Offset newPosition,
    required double newAngle,
    required double newSpeed,
    required double newSize,
    required double newOpacity,
    required Color newColor,
  }) {
    position = newPosition; // 更新位置
    angle = newAngle; // 更新角度
    speed = newSpeed; // 更新速度
    size = newSize; // 更新尺寸
    opacity = newOpacity; // 更新不透明度
    color = newColor; // 更新颜色
    isActive = true; // 设为活跃状态
  }

  /// 更新粒子状态。
  ///
  /// 粒子根据角度和速度移动，不透明度和尺寸逐渐减小。
  /// 当不透明度或尺寸低于阈值时，设为非活跃状态。
  void update() {
    if (!isActive) return; // 非活跃粒子不更新
    position = Offset(
      position.dx + math.cos(angle) * speed, // 更新 X 坐标
      position.dy + math.sin(angle) * speed, // 更新 Y 坐标
    );
    opacity *= 0.94; // 减小不透明度
    size *= 0.97; // 减小尺寸
    if (opacity < _kMinOpacity || size < _kMinSize) {
      // 检查是否低于阈值
      isActive = false; // 设为非活跃状态
    }
  }
}

/// `MouseTrailEffect` 类：鼠标拖尾粒子效果组件。
///
/// 该组件在鼠标移动时生成并显示动态变化的粒子。
class MouseTrailEffect extends StatefulWidget {
  final Color particleColor; // 粒子颜色
  final int maxParticles; // 最大粒子数量

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [particleColor]：粒子颜色，默认为蓝色。
  /// [maxParticles]：最大粒子数量，默认为 20。
  const MouseTrailEffect({
    super.key,
    this.particleColor = Colors.blue,
    this.maxParticles = 20,
  });

  /// 创建 `_MouseTrailEffectState` 状态。
  @override
  State<MouseTrailEffect> createState() => _MouseTrailEffectState();
}

/// `_MouseTrailEffectState` 类：`MouseTrailEffect` 的状态。
///
/// 混入 `SingleTickerProviderStateMixin` 提供动画控制器。
class _MouseTrailEffectState extends State<MouseTrailEffect>
    with SingleTickerProviderStateMixin {
  final List<MouseTrailParticle> _particlePool = []; // 粒子池，存储非活跃粒子
  final List<MouseTrailParticle> _activeParticles = []; // 活跃粒子列表
  Offset? _lastMousePosition; // 上次鼠标位置
  late AnimationController _animationController; // 动画控制器
  final math.Random _random = math.Random(); // 随机数生成器
  bool _isEnabled = true; // 粒子效果是否启用

  /// 初始化状态。
  ///
  /// 根据平台判断是否启用粒子效果。
  /// 初始化粒子池，并配置动画控制器。
  @override
  void initState() {
    super.initState();
    _isEnabled = // 判断是否为桌面平台
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    if (!_isEnabled) return; // 未启用时直接返回

    for (int i = 0; i < widget.maxParticles * 2; i++) {
      // 初始化粒子池
      _particlePool.add(MouseTrailParticle(
        position: Offset.zero,
        color: widget.particleColor,
        isActive: false,
      ));
    }

    _animationController = AnimationController(
      // 创建动画控制器
      vsync: this, // 垂直同步
      duration: _kParticleUpdateInterval, // 动画持续时间
    )..addListener(_updateParticlesAndCheckCleanup); // 添加监听器
  }

  /// 更新粒子状态并检查清理。
  ///
  /// 遍历活跃粒子，更新其状态，并将不活跃粒子移回粒子池。
  /// 如果没有活跃粒子且动画正在进行，则停止动画。
  void _updateParticlesAndCheckCleanup() {
    if (!_isEnabled || !mounted) return; // 未启用或组件未挂载时返回

    for (int i = _activeParticles.length - 1; i >= 0; i--) {
      // 倒序遍历活跃粒子
      final particle = _activeParticles[i]; // 获取粒子
      particle.update(); // 更新粒子状态
      if (!particle.isActive) {
        // 粒子变为不活跃时
        _activeParticles.removeAt(i); // 从活跃列表移除
        _particlePool.add(particle); // 添加回粒子池
      }
    }

    if (_activeParticles.isEmpty && _animationController.isAnimating) {
      // 无活跃粒子且动画正在进行时
      _animationController.stop(); // 停止动画
    }
  }

  /// 在指定位置添加粒子。
  ///
  /// [position]：添加粒子的位置。
  /// 从粒子池中取出粒子，重置其状态并添加到活跃粒子列表。
  void _addParticlesAtPosition(Offset position) {
    if (!_isEnabled) return; // 未启用时返回
    const int particlesToAddPerEvent = 2; // 每次事件添加的粒子数量
    int addedCount = 0; // 已添加的粒子数量

    for (int i = 0;
        i < _particlePool.length && addedCount < particlesToAddPerEvent;
        i++) {
      // 遍历粒子池
      if (!_particlePool[i].isActive) {
        // 找到非活跃粒子
        final particle = _particlePool.removeAt(i); // 从粒子池移除
        final angle = _random.nextDouble() * 2 * math.pi; // 随机角度
        final speed = 0.8 + _random.nextDouble() * 1.2; // 随机速度
        final initialSize = 2.5 + _random.nextDouble() * 2.5; // 随机初始尺寸
        final initialOpacity = 0.6 + _random.nextDouble() * 0.4; // 随机初始不透明度

        HSLColor hslColor =
            HSLColor.fromColor(widget.particleColor); // 从粒子颜色获取 HSL 颜色
        double newHue = (hslColor.hue + _random.nextDouble() * 30.0 - 15.0) %
            360.0; // 随机调整色相
        if (newHue < 0) newHue += 360.0; // 确保色相在 0-360 范围内
        final newParticleColor = hslColor.withHue(newHue).toColor(); // 生成新粒子颜色

        particle.reset(
          // 重置粒子状态
          newPosition: position +
              Offset(_random.nextDouble() * 6 - 3,
                  _random.nextDouble() * 6 - 3), // 随机偏移位置
          newAngle: angle, // 角度
          newSpeed: speed, // 速度
          newSize: initialSize, // 尺寸
          newOpacity: initialOpacity, // 不透明度
          newColor: newParticleColor, // 颜色
        );
        _activeParticles.add(particle); // 添加到活跃粒子列表
        addedCount++; // 增加已添加计数

        if (_activeParticles.length > widget.maxParticles) {
          // 活跃粒子数量超出最大限制
          final oldestParticle = _activeParticles.removeAt(0); // 移除最旧的粒子
          oldestParticle.isActive = false; // 设为不活跃
          _particlePool.add(oldestParticle); // 添加回粒子池
        }
      }
    }

    if (!_animationController.isAnimating && _activeParticles.isNotEmpty) {
      // 动画未进行且有活跃粒子时
      _animationController.repeat(); // 循环播放动画
    }
  }

  /// 处理鼠标移动事件。
  ///
  /// [localPosition]：鼠标在本地坐标系中的位置。
  /// 根据鼠标移动距离添加粒子。
  void _handleMouseMove(Offset localPosition) {
    if (_lastMousePosition != null) {
      // 已有上次鼠标位置
      final distanceMoved =
          (localPosition - _lastMousePosition!).distance; // 计算移动距离
      if (distanceMoved > 0.5) {
        // 移动距离大于阈值
        final int numInterpolationPoints =
            (distanceMoved / 5.0).clamp(1, 4).toInt(); // 计算插值点数量
        for (int i = 0; i < numInterpolationPoints; i++) {
          // 遍历插值点
          final t = (i + 1) / numInterpolationPoints;
          final interpolatedPosition =
              Offset.lerp(_lastMousePosition!, localPosition, t)!; // 计算插值位置
          _addParticlesAtPosition(interpolatedPosition); // 在插值位置添加粒子
        }
        _lastMousePosition = localPosition; // 更新上次鼠标位置
      }
    } else {
      // 无上次鼠标位置
      _addParticlesAtPosition(localPosition); // 在当前位置添加粒子
      _lastMousePosition = localPosition; // 更新上次鼠标位置
    }
  }

  /// 销毁状态。
  ///
  /// 销毁动画控制器。
  @override
  void dispose() {
    _animationController.dispose(); // 销毁动画控制器
    super.dispose();
  }

  /// 构建鼠标拖尾粒子效果 UI。
  ///
  /// [context]：Build 上下文。
  /// 返回一个 `Positioned.fill` 组件，包含 `Listener` 和 `CustomPaint`。
  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) {
      // 未启用时返回空组件
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      // 填充父组件
      child: Listener(
        // 监听鼠标事件
        onPointerHover: (event) =>
            _handleMouseMove(event.localPosition), // 鼠标悬停
        onPointerDown: (event) => _handleMouseMove(event.localPosition), // 鼠标按下
        onPointerMove: (event) => _handleMouseMove(event.localPosition), // 鼠标移动
        behavior: HitTestBehavior.translucent, // 透传点击事件
        child: IgnorePointer(
          // 忽略指针事件
          child: CustomPaint(
            // 自定义绘制
            painter: _MouseTrailPainter(
              // 绘制器
              particles: _activeParticles, // 活跃粒子列表
              animation: _animationController, // 动画控制器
            ),
            size: Size.infinite, // 无限大小
          ),
        ),
      ),
    );
  }
}

/// `_MouseTrailPainter` 类：鼠标拖尾粒子绘制器。
///
/// 继承自 `CustomPainter`，负责绘制活跃粒子。
class _MouseTrailPainter extends CustomPainter {
  final List<MouseTrailParticle> particles; // 粒子列表

  /// 构造函数。
  ///
  /// [particles]：粒子列表。
  /// [animation]：动画监听器。
  _MouseTrailPainter({required this.particles, required Listenable animation})
      : super(repaint: animation); // 监听动画，触发重绘

  /// 绘制粒子。
  ///
  /// [canvas]：画布。
  /// [size]：绘制区域大小。
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint() // 画笔
      ..style = PaintingStyle.fill // 填充样式
      ..strokeCap = StrokeCap.round; // 线帽样式

    for (final particle in particles) {
      // 遍历粒子
      if (particle.isActive) {
        // 活跃粒子
        paint.color = particle.color
            .withSafeOpacity(particle.opacity.clamp(0.0, 1.0)); // 设置颜色和不透明度
        canvas.drawCircle(
          // 绘制圆形
          particle.position, // 位置
          particle.size.clamp(0.0, 15.0), // 尺寸
          paint, // 画笔
        );
      }
    }
  }

  /// 判断是否需要重绘。
  ///
  /// [oldDelegate]：旧的绘制器代理。
  /// 返回 true 表示需要重绘，false 表示不需要。
  @override
  bool shouldRepaint(_MouseTrailPainter oldDelegate) {
    return particles != oldDelegate.particles || // 粒子列表引用不同
        particles.length != oldDelegate.particles.length; // 粒子数量不同
  }
}
