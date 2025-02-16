// lib/screens/admin/widgets/link_management.dart
import 'package:flutter/material.dart';
import '../../../services/link_tool_service.dart';
import '../../../models/link.dart';
import '../../../widgets/form/linkform/link_form_dialog.dart';

class LinkManagement extends StatefulWidget {
  const LinkManagement({Key? key}) : super(key: key);

  @override
  State<LinkManagement> createState() => _LinkManagementState();
}

class _LinkManagementState extends State<LinkManagement> {
  final LinkToolService _linkToolService = LinkToolService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Link>>(
        stream: _linkToolService.getLinks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final links = snapshot.data!;

          return Column(
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
                child: ListView.builder(
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
                        subtitle: Text(link.description),
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