import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 导入 url_launcher 包

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  // 技术栈数据
  final List<Map<String, dynamic>> techStacks = const [
    {
      "title": "开发技术",
      "items": [
        {"name": "Flutter", "desc": "用户界面构建"},
        {"name": "Dart", "desc": "编程语言"},
        {"name": "Provider", "desc": "状态管理"}
      ]
    },
    {
      "title": "数据库技术",
      "items": [
        {"name": "Mongodb", "desc": "云数据库及服务"},
        {"name": "Hive", "desc": "静态本地存储"},
      ]
    }
  ];

  // 打开链接的函数
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
              // 关于宿星茶会
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, // 居中对齐
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.code, size: 16),
                            label: const Text('GitHub账号', style: TextStyle(fontSize: 12)),
                            onPressed: () => _handleOpenLink(
                                'https://github.com/SUXUING-star/SUXUING-star.github.io'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.message, size: 16),
                            label: const Text('QQ交流群: 829701655', style: TextStyle(fontSize: 12)),
                            onPressed: () => _handleOpenLink(
                                'https://qm.qq.com/cgi-bin/qm/qr?k=KYP0Gq7Q9x_Yn6xzH1k2qGGIyC36fPcG&jump_from=webapi&authKey=PmG2m4kZYFX3vXiOHBiKJdKoNYvL2iEUAeVJPaONTdxu2EEmkNBK++SISnqrXwSJ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.video_library, size: 16),
                            label: const Text('b站: Paysage_宿星', style: TextStyle(fontSize: 12)),
                            onPressed: () => _handleOpenLink(
                                'https://space.bilibili.com/your_bilibili_id'), // 替换为实际的 B 站链接
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // 技术栈
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
                              physics: const NeverScrollableScrollPhysics(), // 禁止 ListView 滚动
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