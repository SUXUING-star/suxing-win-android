// lib/widgets/loading/loading_screen.dart
import 'package:flutter/material.dart';
import 'normal_loading_overlay.dart';

class LoadingScreen extends StatelessWidget {
  final bool isLoading;
  final String? message;

  const LoadingScreen({
    Key? key,
    required this.isLoading,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 简化后的加载逻辑：只根据 isLoading 状态决定是否显示加载动画
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return NormalLoadingOverlay(message: message);
  }
}