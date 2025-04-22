// lib/widgets/browser/in_app_browser_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import '../../ui/toaster/toaster.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppBrowserPage extends StatefulWidget {
  final String url;
  final String title;

  const InAppBrowserPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<InAppBrowserPage> createState() => _InAppBrowserPageState();
}

class _InAppBrowserPageState extends State<InAppBrowserPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            Toaster.show(context, message: '页面加载错误: ${error.description}', isError: true);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () => _copyCurrentUrl(),
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () => _openInExternalBrowser(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }

  void _copyCurrentUrl() async {
    final url = await _controller.currentUrl();
    if (url != null) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        Toaster.show(context, message: '链接已复制到剪贴板');
      }
    }
  }

  void _openInExternalBrowser() async {
    final url = await _controller.currentUrl();
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          Toaster.show(context, message: '无法在外部浏览器中打开链接', isError: true);
        }
      }
    }
  }
}