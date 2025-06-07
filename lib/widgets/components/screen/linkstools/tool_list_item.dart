// lib/widgets/components/screen/linkstools/tool_list_item.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/linkstools/tool.dart';
import 'package:suxingchahui/widgets/ui/buttons/url/open_url_button.dart';

/// 一个独立的、用于显示单个工具项的无状态组件。
class ToolListItem extends StatelessWidget {
  final Tool tool;

  const ToolListItem({
    super.key,
    required this.tool,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: Color(int.parse(tool.color.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.build, color: Colors.white, size: 24),
            ),
            title: Text(tool.name,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(tool.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ),
            children: [
              if (tool.downloads.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tool.downloads
                      .map(
                        (download) => Padding(
                      padding: const EdgeInsets.only(bottom: 4, top: 4),
                      child: ListTile(
                        dense: true,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 0),
                        title: Text(download.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(download.description,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600])),
                        trailing: OpenUrlButton(
                          url: download.url,
                          // 这里用下载图标，覆盖 OpenUrlButton 默认的 open_with
                          icon: Icons.download,
                          color: Colors.blue,
                          tooltip: '下载 ${download.name}',
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}