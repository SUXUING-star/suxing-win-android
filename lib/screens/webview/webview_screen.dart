// lib/screens/common/webview_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
// --- 导入你的 UI 组件 ---
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import 'package:suxingchahui/widgets/ui/webview/embedded_web_view.dart';

// --- 导入 WebView 控制器类型 ---
import 'package:webview_flutter/webview_flutter.dart' as android_wv;
import 'package:webview_windows/webview_windows.dart' as windows_wv; // 使用你提供的版本

class WebViewScreen extends StatefulWidget {
  final String url;
  final String? title;

  const WebViewScreen({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with SnackBarNotifierMixin {
  dynamic _controller;
  bool _isLoadingPage = true;
  String _currentAppBarTitle = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  StreamSubscription? _historySubscription; // <--- 用于监听 Windows 历史变化

  @override
  void initState() {
    super.initState();
    _currentAppBarTitle = widget.title ?? '加载中...';
    _isLoadingPage = true;
  }

  @override
  void dispose() {
    _historySubscription?.cancel(); // <--- 取消监听
    super.dispose();
  }

  void _handleWebViewCreated(dynamic controller) {
    if (!mounted) return;
    setState(() {
      _controller = controller;
    });
    // --- 监听 Windows 历史变化 Stream ---
    if (controller is windows_wv.WebviewController) {
      _historySubscription?.cancel(); // 先取消旧的
      _historySubscription = controller.historyChanged.listen((history) {
        // <--- 这个 Stream 是有的
        if (mounted) {
          // 状态变化时更新按钮状态
          setState(() {
            _canGoBack = history.canGoBack;
            _canGoForward = history.canGoForward;
          });
        }
      });
    }
    // 初始检查导航状态
    _updateNavigationState();
    _fetchPageTitle();
  }

  void _handlePageStarted(String url) {
    if (!mounted) return;
    setState(() {
      _isLoadingPage = true;
      if (widget.title == null) _currentAppBarTitle = '加载中...';
    });
    // 页面开始加载时，也应该更新导航状态（可能从无法导航变为可以）
    _updateNavigationState();
  }

  void _handlePageFinished(String url) {
    if (!mounted) return;
    setState(() {
      _isLoadingPage = false;
    });
    _updateNavigationState();
    _fetchPageTitle();
  }

  void _handleWebResourceError(dynamic error) {
    if (!mounted) return;
    setState(() => _isLoadingPage = false);

    String errorMsg = "页面加载时遇到问题";
    if (error is android_wv.WebResourceError) {
      // Android 错误处理 (保持不变)
      if (error.errorCode == -2) {
        // net::ERR_NAME_NOT_RESOLVED
        errorMsg = "无法访问此网站，请检查网络连接或网址";
      } else {
        errorMsg += ': ${error.description} (代码: ${error.errorCode})';
      }
    } else if (error is windows_wv.WebErrorStatus) {
      // <--- 处理 Windows 导航错误
      // --- 使用你提供的正确的枚举常量名 ---
      switch (error) {
        case windows_wv.WebErrorStatus.WebErrorStatusCannotConnect: // <-- 改正
          errorMsg = "无法连接到服务器";
          break;
        case windows_wv
              .WebErrorStatus.WebErrorStatusHostNameNotResolved: // <-- 改正
          errorMsg = "无法解析主机名（网址错误或网络连接问题）";
          break;
        case windows_wv.WebErrorStatus.WebErrorStatusTimeout: // <-- 增加超时处理
          errorMsg = "连接超时，请检查网络或稍后重试";
          break;
        case windows_wv
              .WebErrorStatus.WebErrorStatusServerUnreachable: // <-- 增加服务器无法访问
          errorMsg = "服务器无法访问，请稍后重试";
          break;
        case windows_wv.WebErrorStatus.WebErrorStatusConnectionReset:
        case windows_wv.WebErrorStatus.WebErrorStatusConnectionAborted:
        case windows_wv.WebErrorStatus.WebErrorStatusDisconnected:
          errorMsg = "网络连接已断开";
          break;
        // 可以根据需要添加更多 case 来处理证书错误等
        case windows_wv
              .WebErrorStatus.WebErrorStatusCertificateCommonNameIsIncorrect:
        case windows_wv.WebErrorStatus.WebErrorStatusCertificateExpired:
        case windows_wv
              .WebErrorStatus.WebErrorStatusClientCertificateContainsErrors:
        case windows_wv.WebErrorStatus.WebErrorStatusCertificateRevoked:
        case windows_wv.WebErrorStatus.WebErrorStatusCertificateIsInvalid:
          errorMsg = "证书错误，连接不安全";
          break;
        default: // 其他未知 Windows 错误
          errorMsg = "页面导航发生未知错误: $error";
          break;
      }
    } else if (error is Exception) {
      // 处理其他 Exception 类型的错误
      errorMsg += ': ${error.toString()}';
    } else {
      // 处理其他未知类型的错误
      errorMsg += ': ${error.toString()}';
    }

    AppSnackBar.showError(context, errorMsg,
        duration: const Duration(seconds: 5));
    _updateNavigationState();
    // if (mounted) setState(() { _currentAppBarTitle = widget.title ?? "页面错误"; });
  }

  Future<void> _updateNavigationState() async {
    if (_controller == null || !mounted) return;

    bool currentCanGoBack = false;
    bool currentCanGoForward = false;

    try {
      if (_controller is android_wv.WebViewController) {
        currentCanGoBack = await _controller.canGoBack();
        currentCanGoForward = await _controller.canGoForward();
      } else if (_controller is windows_wv.WebviewController &&
          _controller.value.isInitialized) {
        // Windows 直接调用 canGoBack/Forward 方法仍然存在，但状态更新依赖 historyChanged Stream
        // 这里可以主动调用一次获取初始状态，后续依赖 Stream 更新
        currentCanGoBack = await _controller.canGoBack();
        currentCanGoForward = await _controller.canGoForward();
        // 注意：即使调用了，状态更新也可能稍有延迟，Stream 是最终一致的保障
      }
    } catch (e) {
      print("检查导航状态时出错: $e");
      return;
    }

    if (mounted &&
        (_canGoBack != currentCanGoBack ||
            _canGoForward != currentCanGoForward)) {
      setState(() {
        _canGoBack = currentCanGoBack;
        _canGoForward = currentCanGoForward;
      });
    }
  }

  Future<void> _fetchPageTitle() async {
    if (_controller == null || !mounted) return;

    String? pageTitle;
    try {
      if (_controller is android_wv.WebViewController) {
        pageTitle = await _controller.getTitle();
      } else if (_controller is windows_wv.WebviewController &&
          _controller.value.isInitialized) {
        // Windows 使用 executeScript 获取标题 (这个方法在你提供的版本中是有的)
        final result = await _controller.executeScript('document.title;');
        // executeScript 返回的是 JSON 编码的字符串，需要解码
        if (result != null) {
          try {
            // result 本身已经是解码后的值，不需要 jsonDecode 了
            // （根据你提供的源码，executeScript 内部似乎已经 decode 了？）
            // 直接用 result，它可能是 null 或 string
            pageTitle = result?.toString();
          } catch (e) {
            print("Error decoding title from JS: $e, raw result: $result");
          }
        }
      }
    } catch (e) {
      print("获取页面标题时出错: $e");
    }

    if (mounted) {
      String finalTitle = pageTitle ?? widget.title ?? '浏览页面';
      if (finalTitle.isEmpty) finalTitle = '浏览页面';
      if (_currentAppBarTitle != finalTitle) {
        setState(() => _currentAppBarTitle = finalTitle);
      }
    }
  }

  Future<void> _goBack() async {
    if (_controller != null && _canGoBack) {
      try {
        await _controller.goBack(); // Android 和 Windows 都有 goBack
        // 状态更新现在依赖 historyChanged stream (Windows) 或 NavigationDelegate (Android)
      } catch (e) {
        showSnackbar(message: "无法后退: $e", type: SnackbarType.error);
      }
    }
  }

  Future<void> _goForward() async {
    if (_controller != null && _canGoForward) {
      try {
        await _controller.goForward(); // Android 和 Windows 都有 goForward
      } catch (e) {
        showSnackbar(message: "无法前进: $e", type: SnackbarType.error);
      }
    }
  }

  Future<void> _reload() async {
    if (_controller != null) {
      try {
        await _controller.reload(); // Android 和 Windows 都有 reload
      } catch (e) {
        showSnackbar(message: "无法刷新: $e", type: SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showTitleInDesktop: true,
        title: _currentAppBarTitle,
        actions: _controller == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  tooltip: '后退',
                  onPressed: _canGoBack ? _goBack : null,
                  color: _canGoBack
                      ? Colors.white
                      : Colors.white.withSafeOpacity(0.5),
                ),
                // --- Windows 和 Android 都有 goForward 方法，按钮可以一直显示 ---
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  tooltip: '前进',
                  onPressed: _canGoForward ? _goForward : null,
                  color: _canGoForward
                      ? Colors.white
                      : Colors.white.withSafeOpacity(0.5),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: !_isLoadingPage ? _reload : null,
                  color: !_isLoadingPage
                      ? Colors.white
                      : Colors.white.withSafeOpacity(0.5),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            EmbeddedWebView(
              key: ValueKey(widget.url),
              initialUrl: widget.url,
              onWebViewCreated: _handleWebViewCreated,
              onPageStarted: _handlePageStarted,
              onPageFinished: _handlePageFinished,
              onWebResourceError: _handleWebResourceError,
            ),
            if (_isLoadingPage && _controller != null)
              LoadingWidget.fullScreen(
                message: '页面加载中...',
                opacity: 0.3,
              ),
          ],
        ),
      ),
    );
  }
}
