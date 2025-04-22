import 'package:flutter/material.dart';
import '../../../../models/linkstools/tool.dart';
// --- 引入动画组件 ---
import '../../../ui/animation/fade_in_slide_up_item.dart';
// --- 结束引入 ---

class ToolsSection extends StatelessWidget {
  final List<Tool> tools;
  final bool isAdmin;
  final Function(String) onLaunchURL;

  const ToolsSection({
    super.key,
    required this.tools,
    required this.isAdmin,
    required this.onLaunchURL,
    // this.linkToolService,
  });

  @override
  Widget build(BuildContext context) {
    // 添加 Key 用于动画
    final listKey = ValueKey<int>(tools.hashCode);

    return SliverPadding(
      key: listKey, // 应用 Key
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final tool = tools[index];
            // --- 修改：为每个列表项添加动画 ---
            return FadeInSlideUpItem(
              delay: Duration(milliseconds: 50 * index), // 交错延迟
              duration: Duration(milliseconds: 350),
              child: Padding( // 保留 Padding
                padding: EdgeInsets.only(bottom: 12),
                child: Card( // Card 及其内容保持不变
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16), // 调整内边距
                      leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: Color(int.parse(tool.color.replaceFirst('#', '0xFF'))), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.build, color: Colors.white, size: 24)),
                      title: Text(tool.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      subtitle: Padding(padding: EdgeInsets.only(top: 4), child: Text(tool.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.grey[600]))),
                      children: [
                        if (tool.downloads.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: tool.downloads.map((download) =>
                                Padding(
                                  padding: EdgeInsets.only(bottom: 4, top: 4), // 微调间距
                                  child: ListTile(
                                    dense: true, // 使 ListTile 更紧凑
                                    contentPadding: EdgeInsets.symmetric(horizontal: 0), // 去除 ListTile 默认 Padding
                                    title: Text(download.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                    subtitle: Text(download.description, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                    trailing: IconButton(
                                      icon: Icon(Icons.download, color: Colors.blue),
                                      onPressed: () => onLaunchURL(download.url),
                                      tooltip: '下载 ${download.name}', // 添加 tooltip
                                    ),
                                    // 可以考虑 onTap 直接触发下载？
                                    // onTap: () => onLaunchURL(download.url),
                                  ),
                                ),
                            ).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            // --- 结束修改 ---
          },
          childCount: tools.length,
        ),
      ),
    );
  }
}