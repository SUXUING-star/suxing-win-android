// lib/widgets/common/startup/initialization_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:suxingchahui/providers/initialize/initialization_status.dart';
import 'dart:io'; // For Platform
import 'dart:math'; // For Random
import '../../../utils/font/font_config.dart';

class InitializationScreen extends StatefulWidget {
  final InitializationStatus status;
  final String message;
  final double progress;
  final VoidCallback? onRetry;
  final VoidCallback? onExit;

  const InitializationScreen({
    Key? key,
    required this.status,
    required this.message,
    required this.progress,
    this.onRetry,
    this.onExit,
  }) : super(key: key);

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  // 随机选择GIF文件
  final String _logoGifFile = Random().nextBool()
      ? 'assets/images/cappo.gif'
      : 'assets/images/cappo1.gif';

  @override
  Widget build(BuildContext context) {
    // 检查是否是Android平台
    bool isAndroid = !kIsWeb && Platform.isAndroid;

    // 根据平台确定 logo 和文字大小
    double logoSize = isAndroid ? 120 : 180; // 安卓上 Logo 更小
    double welcomeTextSize = isAndroid ? 12 : 18; // 安卓上欢迎文字更小
    double messageTextSize = isAndroid ? 12 : 18; //安卓消息文字大小

    // 包装在MaterialApp中，确保有Directionality
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
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
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 随机选择的GIF Logo
                    SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Image.asset(
                        _logoGifFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 40),

                    if (widget.status != InitializationStatus.error) ...[
                      // 进度条
                      Container(
                        width: 280,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: LinearProgressIndicator(
                          value: widget.progress,
                          backgroundColor: Colors.blue[100],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 加载文本
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.5),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          widget.message,
                          key: ValueKey<String>(widget.message),
                          style: TextStyle(
                            fontFamily: FontConfig.defaultFontFamily,
                            fontFamilyFallback: FontConfig.fontFallback,
                            color: Colors.blue[700],
                            fontSize: messageTextSize,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ] else
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: widget.onRetry,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '重试',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton(
                                  onPressed: widget.onExit,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red[400],
                                    side: BorderSide(color: Colors.red[400]!),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '退出',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),
                    // 欢迎文本
                    Text(
                      '宿星茶会（跨平台版）',
                      style: TextStyle(
                        fontFamily: FontConfig.defaultFontFamily,
                        fontFamilyFallback: FontConfig.fontFallback,
                        color: Colors.blue[400],
                        fontSize: welcomeTextSize, // 使用平台特定的欢迎文字尺寸
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
