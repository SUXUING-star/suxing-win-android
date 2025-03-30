// lib/screens/admin/widgets/announcement_management.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../models/announcement/announcement.dart';
import '../../../services/main/announcement/announcement_service.dart';
import '../../../widgets/components/dialogs/announcement/announcement_dialog.dart';
import '../../../widgets/components/form/announcementform/announcement_form.dart';

class AnnouncementManagement extends StatefulWidget {
  const AnnouncementManagement({Key? key}) : super(key: key);

  @override
  State<AnnouncementManagement> createState() => _AnnouncementManagementState();
}

class _AnnouncementManagementState extends State<AnnouncementManagement> {
  final AnnouncementService _announcementService = AnnouncementService();

  bool _isLoading = false;
  List<AnnouncementFull> _announcements = [];
  int _currentPage = 1;
  int _totalPages = 1;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  // 加载公告列表
  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 获取公告列表
      final result = await _announcementService.getAllAnnouncements(_currentPage, 10);

      setState(() {
        if (result['announcements'] != null) {
          _announcements = List<AnnouncementFull>.from(result['announcements']);
        } else {
          _announcements = [];
        }

        if (result['pagination'] != null) {
          _totalPages = result['pagination']['pages'] ?? 1;
        } else {
          _totalPages = 1;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载公告失败: $e';
      });
    }
  }

  // 显示创建/编辑公告对话框
  Future<void> _showAnnouncementForm({AnnouncementFull? existingAnnouncement}) async {
    final announcement = existingAnnouncement ?? AnnouncementFull.createNew();

    final result = await showDialog<AnnouncementFull>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingAnnouncement == null ? '创建新公告' : '编辑公告'),
        content: SingleChildScrollView(
          child: AnnouncementForm(
            announcement: announcement,
            onSubmit: (updatedAnnouncement) {
              NavigationUtils.of(context).pop(updatedAnnouncement);
            },
            onCancel: () => NavigationUtils.of(context).pop(),
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (existingAnnouncement == null) {
          // 创建新公告
          await _announcementService.createAnnouncement(result);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('新公告已创建'), backgroundColor: Colors.green),
            );
          }
        } else {
          // 更新现有公告
          await _announcementService.updateAnnouncement(existingAnnouncement.id, result);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('公告已更新'), backgroundColor: Colors.green),
            );
          }
        }

        // 重新加载公告列表
        await _loadAnnouncements();
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = '保存公告失败: $e';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // 删除公告
  Future<void> _deleteAnnouncement(String id) async {
    // 显示确认对话框
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条公告吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => NavigationUtils.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => NavigationUtils.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _announcementService.deleteAnnouncement(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('公告已删除'), backgroundColor: Colors.green),
        );
      }

      // 重新加载公告列表
      await _loadAnnouncements();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '删除公告失败: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 预览公告
  void _previewAnnouncement(AnnouncementFull announcement) {
    // 将完整公告转换为简化版本以供预览
    final clientAnnouncement = Announcement(
      id: announcement.id,
      title: announcement.title,
      content: announcement.content,
      type: announcement.type,
      imageUrl: announcement.imageUrl,
      actionUrl: announcement.actionUrl,
      actionText: announcement.actionText,
      date: announcement.createdAt,
      priority: announcement.priority,
    );

    showAnnouncementDialog(
      context,
      clientAnnouncement,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnnouncements,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: _announcements.isEmpty
          ? _buildEmptyState()
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAnnouncementForm(),
        tooltip: '创建新公告',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.announcement_outlined, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          const Text('暂无公告', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('创建新公告来向用户发布重要信息', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAnnouncementForm(),
            icon: const Icon(Icons.add),
            label: const Text('创建公告'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAnnouncements,
            child: ListView.builder(
              itemCount: _announcements.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                return _buildAnnouncementCard(_announcements[index]);
              },
            ),
          ),
        ),
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPage > 1
                      ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadAnnouncements();
                  }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_currentPage / $_totalPages'),
                IconButton(
                  onPressed: _currentPage < _totalPages
                      ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadAnnouncements();
                  }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnnouncementCard(AnnouncementFull announcement) {
    final theme = Theme.of(context);
    final bool isActive = announcement.isActive;
    final String type = announcement.type;
    final Color typeColor = _getTypeColor(type);
    final bool isExpired = announcement.endDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isActive && !isExpired
              ? typeColor.withOpacity(0.5)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(_getTypeIcon(type), color: typeColor),
            title: Text(announcement.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '优先级: ${announcement.priority} · ' +
                  '${announcement.startDate.day}/${announcement.startDate.month} - ${announcement.endDate.day}/${announcement.endDate.month}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? (isExpired ? Colors.grey : Colors.green)
                    : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive
                    ? (isExpired ? '已过期' : '活跃')
                    : '未激活',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              announcement.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: '预览',
                  onPressed: () => _previewAnnouncement(announcement),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: '编辑',
                  onPressed: () => _showAnnouncementForm(existingAnnouncement: announcement),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '删除',
                  color: Colors.red,
                  onPressed: () => _deleteAnnouncement(announcement.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'success':
        return Icons.check_circle;
      case 'update':
        return Icons.system_update;
      case 'event':
        return Icons.event;
      default: // 'info'
        return Icons.info;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'event':
        return Colors.purple;
      default: // 'info'
        return Colors.teal;
    }
  }
}