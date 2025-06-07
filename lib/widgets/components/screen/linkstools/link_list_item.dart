// lib/widgets/components/screen/linkstools/link_list_item.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/linkstools/site_link.dart';
import 'package:suxingchahui/widgets/ui/buttons/url/open_url_button.dart';

/// 一个独立的、用于显示单个链接项的无状态组件。
class LinkListItem extends StatelessWidget {
  final SiteLink link;
  final bool isAdmin;
  final VoidCallback onEdit;

  const LinkListItem({
    super.key,
    required this.link,
    required this.isAdmin,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: Color(int.parse(link.color.replaceFirst('#', '0xFF'))),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.link, color: Colors.white, size: 24),
          ),
          title: Text(link.title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              link.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OpenUrlButton(
                url: link.url,
                webViewTitle: link.title,
                color: Colors.teal,
                tooltip: '打开链接',
              ),
              if (isAdmin)
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.grey[600]),
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}