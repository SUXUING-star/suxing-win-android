// lib/widgets/ui/web/embedded_web_view.dart
import 'dart:async';
import 'dart:io' show Platform;
// 需要用到 jsonDecode

import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';


// --- 导入你的 UI 组件 ---
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';

// --- WebView 平台库 ---
// Android
import 'package:webview_flutter/webview_flutter.dart';
// Windows (使用你提供的版本 API)
import 'package:webview_windows/webview_windows.dart' as windows_wv; // 重命名避免冲突

class EmbeddedWebView extends StatefulWidget {
  final String initialUrl;
  final Function(dynamic controller)? onWebViewCreated;
  final Function(String url)? onPageStarted;
  final Function(String url)? onPageFinished;
  final Function(dynamic error)? onWebResourceError; // 传递平台特定错误

  const EmbeddedWebView({
    super.key,
    required this.initialUrl,
    this.onWebViewCreated,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
  });

  @override
  State<EmbeddedWebView> createState() => _EmbeddedWebViewState();
}

class _EmbeddedWebViewState extends State<EmbeddedWebView> {
  // 控制器
  WebViewController? _androidController;
  final windows_wv.WebviewController _windowsController = windows_wv.WebviewController();

  // 状态
  bool _isInitializing = true;
  bool _initializationError = false;
  String _errorDetails = '';
  final List<StreamSubscription> _windowsSubscriptions = [];
  String _lastWindowsUrl = ''; // <--- 新增：存储最后已知的 Windows URL

  @override
  void initState() {
    super.initState();
    _lastWindowsUrl = widget.initialUrl; // 初始化时设为 initialUrl
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeWebView();
      }
    });
  }

  Future<void> _initializeWebView() async {
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _initializationError = false;
      _errorDetails = '';
    });

    try {
      if (DeviceUtils.isWeb) {
        throw UnsupportedError('Web platform is not supported.');
      } else if (DeviceUtils.isAndroid) {
        await _initializeAndroidWebView();
      } else if (DeviceUtils.isWindows) {
        // --- 修改 Windows 初始化，使用你版本提供的 API ---
        await _initializeWindowsWebView_V0_2_0();
      } else {
        throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported.');
      }
      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationError = true;
          _errorDetails = 'WebView 初始化失败: ${e.toString()}';
        });
        widget.onWebResourceError?.call(e);
      }
    }
  }

  Future<void> _initializeAndroidWebView() async {
    // ... (Android 初始化代码保持不变) ...
    _androidController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            widget.onPageStarted?.call(url);
          },
          onPageFinished: (String url) {
            widget.onPageFinished?.call(url);
          },
          onWebResourceError: (WebResourceError error) {
            widget.onWebResourceError?.call(error);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );
    await _androidController!.loadRequest(Uri.parse(widget.initialUrl));
    if (mounted) widget.onWebViewCreated?.call(_androidController);
  }


  /// --- 使用 V0.2.0 API 的 Windows 初始化 ---
  Future<void> _initializeWindowsWebView_V0_2_0() async {
    // 清理旧订阅
    for (var s in _windowsSubscriptions) { s.cancel(); }
    _windowsSubscriptions.clear();

    // 1. 直接尝试初始化，用 try-catch 捕获环境问题
    try {
      await _windowsController.initialize();
    } catch (e) {
      // 初始化失败，很可能是 WebView2 Runtime 问题
      throw Exception('无法初始化 Windows WebView: $e. 请确保已安装 Microsoft Edge WebView2 Runtime。');
    }

    // 2. 监听需要的 Stream (基于你提供的源码)
    //    监听 URL 变化
    _windowsSubscriptions.add(_windowsController.url.listen((url) { // <--- 这个 Stream 是有的
      if (!mounted) return;
      _lastWindowsUrl = url; // <--- 更新最后已知的 URL
      widget.onPageStarted?.call(url); // URL 变化近似 PageStarted
    }));

    //    监听加载状态变化
    _windowsSubscriptions.add(_windowsController.loadingState.listen((state) { // <--- 这个 Stream 是有的
      if (!mounted) return;
      if (state == windows_wv.LoadingState.navigationCompleted) {
        // 使用我们保存的最后一个 URL
        widget.onPageFinished?.call(_lastWindowsUrl); // <--- 使用 _lastWindowsUrl
      }
      // 这个版本的 LoadingState 没有明确的错误状态
    }));

    //    监听导航错误 (这个 Stream 是有的)
    _windowsSubscriptions.add(_windowsController.onLoadError.listen((status) { // <--- 这个 Stream 是有的
      if (!mounted) return;
      final error = Exception("导航错误: $status"); // 封装成通用 Exception
      widget.onWebResourceError?.call(error);
      // 可以选择在这里更新UI状态显示错误信息
      // setState(() {
      //   _initializationError = true; // 标记有错误，但不一定是初始化错误
      //   _errorDetails = "页面加载导航错误: $status";
      // });
    }));

    // 监听 WebMessage (如果需要与 JS 通信)
    _windowsSubscriptions.add(_windowsController.webMessage.listen((message) {
      // 处理来自 JS 的消息
      // print("Received web message: $message");
    }));

    // --- 其他初始化配置 ---
    await _windowsController.setBackgroundColor(Colors.transparent);
    await _windowsController.setPopupWindowPolicy(windows_wv.WebviewPopupWindowPolicy.deny);

    // 加载初始 URL
    await _windowsController.loadUrl(widget.initialUrl);

    // 初始化完成，传递控制器
    if (mounted) {
      widget.onWebViewCreated?.call(_windowsController);
    }
  }


  @override
  void dispose() {
    if (Platform.isWindows) {
      for (var s in _windowsSubscriptions) {
        s.cancel();
      }
      _windowsSubscriptions.clear();
      // 安全地 dispose，检查 isInitialized
      if (_windowsController.value.isInitialized) {
        try {
          _windowsController.dispose();
        } catch(e) {
          print("Error disposing windows controller: $e");
        }
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- 构建逻辑保持不变，使用你的 UI 组件 ---
    if (_isInitializing) {
      return LoadingWidget.inline(message: '正在初始化 WebView...');
    }

    if (_initializationError) {
      return InlineErrorWidget(
        errorMessage: _errorDetails,
        onRetry: _initializeWebView,
        icon: Icons.error_outline,
        iconColor: Colors.red,
        retryText: '重试初始化',
      );
    }

    try {
      if (DeviceUtils.isWeb) {
        return const EmptyStateWidget(
          message: 'Web 平台当前不支持内嵌 WebView',
          iconData: Icons.web_asset_off,
        );
      } else if (Platform.isWindows) {
        // --- 检查 Windows 控制器状态 (初始化后是否还有效) ---
        if (!_windowsController.value.isInitialized) { // <--- WebviewValue 有 isInitialized
          return EmptyStateWidget(
            message: _errorDetails.isNotEmpty ? _errorDetails : 'Windows WebView 控制器失效，请重试。',
            iconData: Icons.desktop_access_disabled,
            iconColor: Colors.red,
            action: FunctionalTextButton(
              label: '重试初始化',
              onPressed: _initializeWebView,
            ),
          );
        }
        // --- 返回 Windows WebView Widget ---
        return windows_wv.Webview(_windowsController); // <--- 这个 Widget 是有的
      }
      else if (Platform.isAndroid) {
        // ... (Android 构建逻辑不变) ...
        if (_androidController == null) {
          return EmptyStateWidget(
            message: 'Android WebView 未能成功初始化，请重试。',
            iconData: Icons.phonelink_erase,
            action: FunctionalTextButton(
              label: '重试初始化',
              onPressed: _initializeWebView,
            ),
          );
        }
        return WebViewWidget(controller: _androidController!);
      }
      else {
        return EmptyStateWidget(
          message: '平台 ${Platform.operatingSystem} 不支持内嵌 WebView',
          iconData: Icons.device_unknown,
        );
      }
    } catch (e) {
      return InlineErrorWidget(
        errorMessage: "构建 WebView 时发生错误: $e",
        onRetry: _initializeWebView,
        icon: Icons.error,
      );
    }
  }
}