// lib/widgets/ui/utils/network_error_widget.dart

/// 定义了 [NetworkErrorWidget]，一个使用浮动卡片和动画高效展示网络错误的组件。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/services/main/network/network_manager.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

/// 网络错误监听器。
///
/// 该 Widget 使用 [Stack] 将子内容与一个条件性显示的错误横幅分层。
/// [StreamBuilder] 和 [AnimatedSwitcher] 结合，仅在网络状态变化时，
/// 以平滑的动画效果显示或隐藏一个自定义的浮动错误卡片，确保主内容 [child] 绝不重建。
class NetworkErrorWidget extends StatelessWidget {
  /// 网络管理器实例。
  final NetworkManager networkManager;

  /// 创建一个 [NetworkErrorWidget] 实例。
  const NetworkErrorWidget({
    super.key,
    required this.networkManager,
  });

  @override
  Widget build(BuildContext context) {
    return
        // --- Layer 2: 动画切换的错误横幅 ---
        StreamBuilder<bool>(
      stream: networkManager.connectionStatusStream,
      initialData: networkManager.isConnected,
      builder: (context, snapshot) {
        final bool isConnected = snapshot.data!;

        // 使用 AnimatedSwitcher 来实现平滑的出现和消失动画
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> animation) {
            // 定义从上向下滑入的动画效果
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.0, -1.5), // 从屏幕外顶部开始
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ));
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          // 根据网络状态切换子 Widget
          child: isConnected
              ? const SizedBox.shrink(key: Key('connected_placeholder'))
              : _buildFloatingErrorBanner(context), // 构建自定义的浮动横幅
        );
      },
    );
  }

  /// 构建一个自定义的、浮动的、非侵入式的错误横幅。
  Widget _buildFloatingErrorBanner(BuildContext context) {
    // 使用 Key 来帮助 AnimatedSwitcher 识别 Widget
    return Align(
      key: const Key('disconnected_banner'),
      alignment: Alignment.topCenter,
      // 使用 SafeArea 确保横幅不会与系统UI（如状态栏）重叠
      child: SafeArea(
        child: Container(
          // 横向边距，使其不接触屏幕边缘
          margin: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red[700]?.withSafeOpacity(0.95),
            borderRadius: BorderRadius.circular(12.0), // 圆角
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // 内容决定宽度
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Flexible(
                child: AppText(
                  '网络连接已断开',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              // 分隔符
              Container(
                height: 16,
                width: 1,
                color: Colors.white.withSafeOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              GestureDetector(
                onTap: networkManager.reconnect,
                child: const AppText(
                  '重试',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
