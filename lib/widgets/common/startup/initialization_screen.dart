// lib/widgets/common/startup/initialization_screen.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/layouts/desktop/desktop_frame_layout.dart';
import 'package:suxingchahui/providers/initialize/initialization_status.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';
import 'package:suxingchahui/utils/device/device_utils.dart'; // 引入 DeviceUtils
import 'package:suxingchahui/windows/ui/windows_controls.dart'; // 引入 WindowsControls
import 'package:suxingchahui/wrapper/platform_wrapper.dart'; // 引入用于高度常量
import 'package:window_manager/window_manager.dart'; // 引入 window_manager
import 'dart:math'; // For Random

class InitializationScreen extends StatefulWidget {
  final InitializationStatus status;
  final String message;
  final double progress;
  final VoidCallback? onRetry;
  final VoidCallback? onExit;

  const InitializationScreen({
    super.key,
    required this.status,
    required this.message,
    required this.progress,
    this.onRetry,
    this.onExit,
  });

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  // 随机选择GIF文件
  final String _logoGifFile = Random().nextBool()
      ? 'assets/images/cappo.gif'
      : 'assets/images/cappo1.gif';

  Widget _buildWindowsControlsSection() {

    return Positioned(
      // 顶层放置一个 Positioned Widget 作为标题栏区域
      top: 0, // 紧贴顶部
      left: 0, // 紧贴左边
      right: 0, // 紧贴右边
      height: PlatformWrapper.kDesktopTitleBarHeight, // 使用常量定义的高度
      child: Material(
        // 使用 Material Widget 可以设置背景色（这里是透明）
        color: Colors.white,
        // 标题栏内部使用 Row 排列
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    GlobalConstants.appIcon,
                    height: 24.0,
                    width: 24.0,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(width: 8.0),
                  AppText(
                    GlobalConstants.appName, // 使用传入或默认标题
                    color: Colors.black,
                    fontSize: 13,
                    maxLines: 1,
                    type: AppTextType.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 左侧大部分区域是可拖拽区域
            Expanded(
              child: DragToMoveArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        ...DesktopFrameLayout.desktopBarColor
                      ], // 使用传入或默认渐变
                    ),
                  ),
                ), // 拖拽区域本身不需要显示内容
              ),
            ),
            // 右侧是窗口控制按钮 (最小化, 最大化/还原, 关闭)
            WindowsControls(
              iconColor: Colors.grey[700], // 图标颜色，确保可见
              hoverColor: Colors.black.withSafeOpacity(0.1), // 鼠标悬停背景色
              closeHoverColor: Colors.red.withSafeOpacity(0.8), // 关闭按钮悬停背景色
            ),
          ],
        ),
      ),
    );
  }

  // --- 构建核心内容 Widget ---
  Widget _buildCoreContent() {
    final bool isDesktop = DeviceUtils.isDesktop;
    double logoSize = isDesktop ? 180 : 120;
    double welcomeTextSize = isDesktop ? 18 : 12;
    double messageTextSize = isDesktop ? 18 : 12;

    return Scaffold(
      // 根据平台调整大小
      // backgroundColor: Colors.transparent, // 如果背景渐变需要透明
      body: Container(
        // 背景渐变
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.blue[100]!,
            ],
          ),
        ),
        // SafeArea 保护内容区域
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              // 主要垂直布局
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- 桌面端顶部留白 ---
                  if (isDesktop)
                    const SizedBox(
                        height: PlatformWrapper.kDesktopTitleBarHeight +
                            10), // 标题栏高度 + 间距

                  // --- Logo ---
                  SizedBox(
                    width: logoSize,
                    height: logoSize,
                    child: Image.asset(
                      _logoGifFile,
                      fit: BoxFit.contain, // 保持比例
                    ),
                  ),
                  const SizedBox(height: 40), // Logo 和下方内容的间距

                  // --- 根据状态显示进度条或错误信息 ---
                  if (widget.status != InitializationStatus.error) ...[
                    // --- 进度条容器 ---
                    Container(
                      width: 280, // 固定宽度
                      height: 4, // 固定高度
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2), // 圆角
                      ),
                      // 线性进度条
                      child: LinearProgressIndicator(
                        value: widget.progress, // 进度值
                        backgroundColor: Colors.blue[100], // 背景色
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[700]!), // 进度条颜色
                        borderRadius: BorderRadius.circular(2), // 圆角
                      ),
                    ),
                    const SizedBox(height: 20), // 进度条和消息文本的间距

                    // --- 加载消息文本 (带动画) ---
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300), // 动画时长
                      // 定义过渡动画
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          // 淡入淡出
                          opacity: animation,
                          child: SlideTransition(
                            // 从下方滑入
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.5), // 从下方 0.5 单位处开始
                              end: Offset.zero, // 结束位置在原位
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      // 文本内容，使用 ValueKey 确保动画在文本变化时触发
                      child: AppText(
                        widget.message,
                        key: ValueKey<String>(widget.message),
                        type: AppTextType.title, // 使用预设文本类型
                        color: Colors.blue[400], // 文本颜色
                        fontSize: messageTextSize, // 文本大小
                      ),
                    ),
                  ] else ...[
                    // 如果状态是错误
                    // --- 错误信息显示容器 ---
                    Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 24), // 水平外边距
                      padding: const EdgeInsets.all(24), // 内边距
                      decoration: BoxDecoration(
                        color: Colors.white, // 白色背景
                        borderRadius: BorderRadius.circular(16), // 圆角
                        boxShadow: [
                          // 添加阴影
                          BoxShadow(
                            color: Colors.black.withSafeOpacity(0.1), // 阴影颜色
                            blurRadius: 16, // 模糊半径
                            offset: const Offset(0, 4), // 阴影偏移
                          ),
                        ],
                      ),
                      // 错误信息垂直布局
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 高度自适应内容
                        children: [
                          // 错误图标
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16), // 图标和文本间距
                          // 错误消息文本
                          AppText(
                            widget.message,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 16,
                              height: 1.5, // 行高
                            ),
                            textAlign: TextAlign.center, // 居中对齐
                          ),
                          const SizedBox(height: 24), // 文本和按钮间距
                          // 重试和退出按钮水平排列
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center, // 按钮居中
                            children: [
                              // 重试按钮
                              ElevatedButton(
                                onPressed: widget.onRetry, // 绑定重试回调
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700], // 背景色
                                  foregroundColor: Colors.white, // 前景色 (文字颜色)
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12, // 内边距
                                  ),
                                  shape: RoundedRectangleBorder(
                                    // 圆角形状
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                // 按钮文字
                                child: const AppText(
                                  '重试',
                                  type: AppTextType.button, // 使用预设按钮文本类型
                                  color: Colors.white, // 明确颜色
                                ),
                              ),
                              const SizedBox(width: 16), // 按钮间距
                              // 退出按钮
                              OutlinedButton(
                                onPressed: widget.onExit, // 绑定退出回调
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[400], // 前景色
                                  side: BorderSide(
                                      color: Colors.red[400]!), // 边框颜色
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12, // 内边距
                                  ),
                                  shape: RoundedRectangleBorder(
                                    // 圆角形状
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                // 按钮文字
                                child: const AppText(
                                  '退出',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40), // 与下方欢迎文本的间距
                  // --- 欢迎文本 ---
                  AppText(
                    '宿星茶会（跨平台版）',
                    color: Colors.blue[400], // 文本颜色
                    fontSize: welcomeTextSize, // 文本大小
                    fontWeight: FontWeight.bold, // 粗体
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;

    return MaterialApp(
      debugShowCheckedModeBanner: false, // 不显示右上角的 Debug 标签
      home: isDesktop // 判断是否是桌面平台
          ? Stack(
              // 桌面端使用 Stack 来叠加窗口控件
              children: [
                // 底层是上面构建的核心内容
                _buildCoreContent(),
                _buildWindowsControlsSection(),
              ],
            )
          : _buildCoreContent(), // 非桌面平台直接返回核心内容，不需要 Stack 和控件
    );
  }
}
