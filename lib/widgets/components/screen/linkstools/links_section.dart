// lib/widgets/linkstools/links_section.dart
import 'package:flutter/material.dart';
import '../../../../models/linkstools/link.dart';
import '../../../../services/main/linktool/link_tool_service.dart';
import '../../../form/linkform/link_form_dialog.dart';
import '../../../common/toaster.dart';

class LinksSection extends StatelessWidget {
  final List<Link> links;
  final bool isAdmin;
  final Function() onRefresh;
  final Function(String) onLaunchURL;
  final LinkToolService linkToolService;

  const LinksSection({
    Key? key,
    required this.links,
    required this.isAdmin,
    required this.onRefresh,
    required this.onLaunchURL,
    required this.linkToolService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final link = links[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(int.parse(link.color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.link, color: Colors.white, size: 24),
                  ),
                  title: Text(
                    link.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      link.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.open_in_new, color: Colors.blue),
                        onPressed: () => onLaunchURL(link.url),
                      ),
                      if (isAdmin)
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.grey[600]),
                          onPressed: () => _showEditDialog(context, link),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: links.length,
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Link link) {
    showDialog(
      context: context,
      builder: (context) => LinkFormDialog(link: link),
    ).then((linkData) async {
      if (linkData != null) {
        try {
          await linkToolService.updateLink(Link.fromJson(linkData));
          Toaster.show(context, message: '更新链接成功');
          onRefresh();
        } catch (e) {
          Toaster.show(context, message: '更新链接失败: $e', isError: true);
        }
      }
    });
  }
}
