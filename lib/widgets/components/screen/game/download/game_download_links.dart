// lib/widgets/components/screen/game/game_download_links.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../../common/toaster/toaster.dart';
import '../../../../../models/game/game.dart';
import '../../../../../providers/auth/auth_provider.dart';

class GameDownloadLinks extends StatelessWidget {
  final List<DownloadLink> downloadLinks;

  const GameDownloadLinks({
    Key? key,
    required this.downloadLinks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user is logged in
    if (!authProvider.isLoggedIn) {
      return _buildLoginRequiredMessage(context);
    }

    return Column(
      children: downloadLinks.map((link) => Card(
        child: ListTile(
          title: Text(link.title),
          subtitle: Text(link.description),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              IconButton(
                icon: Icon(Icons.launch),
                tooltip: '在外部浏览器中打开',
                onPressed: () => _launchURL(context, link.url),
              ),
              IconButton(
                icon: Icon(Icons.copy),
                tooltip: '复制链接',
                onPressed: () => _copyToClipboard(context, link.url),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  // Widget to show when user is not logged in
  Widget _buildLoginRequiredMessage(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '下载链接需要登录后查看',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '请登录您的账户以查看并下载游戏资源',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateToLogin(context),
              child: const Text('登录'),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to login page
  void _navigateToLogin(BuildContext context) {
    // You'll need to adapt this to your routing system
    // This is an example assuming you have a named route for login
    Navigator.of(context).pushNamed('/login');
  }


  Future<void> _launchURL(BuildContext context, String? url) async {
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      Toaster.show(context, message: '无法打开外部链接', isError: true);
    }
  }

  void _copyToClipboard(BuildContext context, String? text) {
    if (text != null) {
      Clipboard.setData(ClipboardData(text: text));
      Toaster.show(context, message: '链接已复制到剪贴板');
    } else {
      Toaster.show(context, message: '复制失败，链接为空', isError: true);
    }
  }
}