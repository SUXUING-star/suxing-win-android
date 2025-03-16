import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> techStacks = const [
    {
      "title": "客户端开发",
      "items": [
        {"name": "Dart", "desc": "ui层&交互层"},
        {"name": "Golang" , "desc": "业务处理层"},
        {"name": "Nodejs" , "desc": "Redis代理层"},
      ]
    },
    {
      "title": "底层开发",
      "items": [
        {"name": "C++" , "desc": "Windows构建底层"},
        {"name": "Kotlin", "desc": "Android构建底层"}
      ]
    }
  ];

  Future<void> _handleOpenLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于宿星茶会'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '关于宿星茶会',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        '一个专注于分享和交流Galgame的平台，为玩家提供游戏下载、评论和交流的空间。',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 16.0),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Wrap(
                            spacing: 8, // 水平间距
                            runSpacing: 8, // 垂直间距
                            alignment: WrapAlignment.center,
                            children: [
                              SizedBox(
                                width: constraints.maxWidth > 600 ? null : (constraints.maxWidth - 16) / 3,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.code, size: 16),
                                  label: const Text('GitHub',
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _handleOpenLink(
                                      'https://github.com/SUXUING-star/SUXUING-star.github.io'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: constraints.maxWidth > 600 ? null : (constraints.maxWidth - 16) / 3,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.message, size: 16),
                                  label: const Text('QQ群',
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _handleOpenLink(
                                      'https://qm.qq.com/cgi-bin/qm/qr?k=KYP0Gq7Q9x_Yn6xzH1k2qGGIyC36fPcG&jump_from=webapi&authKey=PmG2m4kZYFX3vXiOHBiKJdKoNYvL2iEUAeVJPaONTdxu2EEmkNBK++SISnqrXwSJ'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: constraints.maxWidth > 600 ? null : (constraints.maxWidth - 16) / 3,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.video_library, size: 16),
                                  label: const Text('bilibili',
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _handleOpenLink(
                                      'https://space.bilibili.com/32892805?spm_id_from=333.1007.0.0'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // 技术栈部分保持不变
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '技术栈',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16.0),
                      ...techStacks.map((section) {
                        final int index = techStacks.indexOf(section);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section['title'],
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8.0),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: (section['items'] as List).length,
                              itemBuilder: (context, i) {
                                final item = (section['items'] as List)[i];
                                return ListTile(
                                  leading: const Icon(Icons.code),
                                  title: Text(item['name']),
                                  subtitle: Text(item['desc']),
                                );
                              },
                            ),
                            if (index < techStacks.length - 1)
                              const Divider(height: 32.0),
                          ],
                        );
                      }).toList(),
                    ],
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