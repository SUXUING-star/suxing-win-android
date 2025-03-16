// lib/screens/admin/widgets/link_management.dart
import 'package:flutter/material.dart';
import '../../../services/main/linktool/link_tool_service.dart';
import '../../../models/linkstools/link.dart';
import '../../../widgets/components/form/linkform/link_form_dialog.dart';

class LinkManagement extends StatefulWidget {
  const LinkManagement({Key? key}) : super(key: key);

  @override
  State<LinkManagement> createState() => _LinkManagementState();
}

class _LinkManagementState extends State<LinkManagement> {
  final LinkToolService _linkToolService = LinkToolService();
  // 添加刷新触发器
  int _refreshTrigger = 0;

  // 刷新数据方法
  void _refreshData() {
    setState(() {
      _refreshTrigger++; // 增加计数器触发 StreamBuilder 重建
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Link>>(
        // 使用刷新触发器作为key，确保数据改变时重建
        key: ValueKey("links_$_refreshTrigger"),
        stream: _linkToolService.getLinks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final links = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _refreshData();
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _showAddLinkDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('添加链接'),
                  ),
                ),
                Expanded(
                  child: links.isEmpty
                      ? Center(child: Text('暂无链接数据'))
                      : ListView.builder(
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final link = links[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.link),
                          title: Text(link.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(link.description),
                              if (link.url.isNotEmpty)
                                Text(
                                  link.url,
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditLinkDialog(link),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmation(link),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddLinkDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const LinkFormDialog(),
    );

    if (result != null) {
      try {
        await _linkToolService.addLink(Link.fromJson(result));
        // 刷新UI
        _refreshData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('链接添加成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败：$e')),
        );
      }
    }
  }

  Future<void> _showEditLinkDialog(Link link) async {
    final result = await showDialog(
      context: context,
      builder: (context) => LinkFormDialog(link: link),
    );

    if (result != null) {
      try {
        await _linkToolService.updateLink(Link.fromJson(result));
        // 刷新UI
        _refreshData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('链接更新成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败：$e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Link link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除链接"${link.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _linkToolService.deleteLink(link.id);
        // 刷新UI
        _refreshData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('链接删除成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }
}