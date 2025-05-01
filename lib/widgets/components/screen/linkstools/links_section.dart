import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/url/open_url_button.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../models/linkstools/link.dart';
import '../../../../services/main/linktool/link_tool_service.dart';
import '../../form/linkform/link_form_dialog.dart';
// --- 引入动画组件 ---
import '../../../ui/animation/fade_in_slide_up_item.dart';
// --- 结束引入 ---

class LinksSection extends StatelessWidget {
  final List<Link> links;
  final bool isAdmin;
  final Function() onRefresh;
  final Function(String) onLaunchURL;
  final LinkToolService linkToolService;

  const LinksSection({
    super.key,
    required this.links,
    required this.isAdmin,
    required this.onRefresh,
    required this.onLaunchURL,
    required this.linkToolService,
  });

  @override
  Widget build(BuildContext context) {
    // 添加 Key 用于动画
    final listKey = ValueKey<int>(links.hashCode); // 使用 hashCode 或 length

    return SliverPadding(
      key: listKey, // 应用 Key
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final link = links[index];
            // --- 修改：为每个列表项添加动画 ---
            return FadeInSlideUpItem(
              delay: Duration(milliseconds: 50 * index), // 交错延迟
              duration: Duration(milliseconds: 350),
              child: Padding(
                // 保留 Padding
                padding: EdgeInsets.only(bottom: 12),
                child: Card(
                  // Card 及其内容保持不变
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: Color(int.parse(
                                link.color.replaceFirst('#', '0xFF'))),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.link, color: Colors.white, size: 24)),
                    title: Text(link.title,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    subtitle: Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(link.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OpenUrlButton(
                          url: link.url,
                          webViewTitle: link.title, // 把链接标题传给 WebView
                          color: Colors.teal, // 可以保持颜色
                          tooltip: '打开链接', // 可以改个更明确的 tooltip
                        ),
                        if (isAdmin)
                          IconButton(
                              icon: Icon(Icons.edit, color: Colors.grey[600]),
                              onPressed: () => _showEditDialog(context, link)),
                      ],
                    ),
                  ),
                ),
              ),
            );
            // --- 结束修改 ---
          },
          childCount: links.length,
        ),
      ),
    );
  }

  // _showEditDialog 保持不变
  void _showEditDialog(BuildContext context, Link link) {
    showDialog(
            context: context, builder: (context) => LinkFormDialog(link: link))
        .then((linkData) async {
      if (linkData != null) {
        try {
          await linkToolService.updateLink(Link.fromJson(linkData));
          if (context.mounted) {
            AppSnackBar.showSuccess(context, '更新链接成功'); // 检查 mounted
          }
          onRefresh();
        } catch (e) {
          if (context.mounted) AppSnackBar.showError(context, '更新链接失败: $e');
        }
      }
    });
  }
}
