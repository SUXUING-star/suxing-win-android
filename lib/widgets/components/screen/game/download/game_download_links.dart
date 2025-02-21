// lib/widgets/game/game_download_links.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/toaster.dart';
import '../../../../../models/game/game.dart';

class GameDownloadLinks extends StatelessWidget {
  final List<DownloadLink> downloadLinks;

  const GameDownloadLinks({
    Key? key,
    required this.downloadLinks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: downloadLinks.map((link) => Card(
        child: ListTile(
          title: Text(link.title),
          subtitle: Text(link.description),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.open_in_browser),
                onPressed: () => _launchURL(context, link.url),
              ),
              IconButton(
                icon: Icon(Icons.copy),
                onPressed: () => _copyToClipboard(context, link.url),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Future<void> _launchURL(BuildContext context, String? url) async {
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Toaster.show(context, message: '无法打开链接', isError: true);
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