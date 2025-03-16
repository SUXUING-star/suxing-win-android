// lib/screens/admin/widgets/ip_management.dart

import 'package:flutter/material.dart';
import '../../../services/main/denfence/defence_service.dart';

class IPManagement extends StatefulWidget {
  const IPManagement({Key? key}) : super(key: key);

  @override
  State<IPManagement> createState() => _IPManagementState();
}

class _IPManagementState extends State<IPManagement> with SingleTickerProviderStateMixin {
  final DefenceService _defenceService = DefenceService();
  late TabController _tabController;
  bool _isLoading = false;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _blacklistIpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _blacklistIpController.dispose();
    super.dispose();
  }

  Future<void> _removeFromBlacklist(String ip) async {
    setState(() => _isLoading = true);
    try {
      await _defenceService.removeFromBlacklist(ip);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已从黑名单移除: $ip')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToBlacklist(String ip) async {
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的IP地址')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _defenceService.addToBlacklist(ip);
      _blacklistIpController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加到黑名单: $ip')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToWhitelist(String ip) async {
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的IP地址')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _defenceService.addToWhitelist(ip);
      _ipController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加到白名单: $ip')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWhitelist(String ip) async {
    setState(() => _isLoading = true);
    try {
      await _defenceService.removeFromWhitelist(ip);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已从白名单移除: $ip')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '黑名单', icon: Icon(Icons.block)),
            Tab(text: '白名单', icon: Icon(Icons.check_circle)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBlacklistTab(),
              _buildWhitelistTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlacklistTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _blacklistIpController,
                  decoration: const InputDecoration(
                    labelText: '添加IP到黑名单',
                    hintText: '输入IP地址',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _addToBlacklist(_blacklistIpController.text.trim()),
                child: const Text('拉黑'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _defenceService.getBlacklist(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('加载失败: ${snapshot.error}'));
              }

              final ips = snapshot.data ?? [];
              if (ips.isEmpty) {
                return const Center(child: Text('黑名单为空'));
              }

              return ListView.builder(
                itemCount: ips.length,
                itemBuilder: (context, index) {
                  final ip = ips[index];
                  final createdAt = DateTime.parse(ip['created_at']).toLocal();
                  final expiresAt = DateTime.parse(ip['expires_at']).toLocal();
                  final isExpired = expiresAt.isBefore(DateTime.now());

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.block, color: Colors.red),
                      title: Text(ip['ip']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('添加时间: ${createdAt.toString().split('.')[0]}'),
                          Text(
                            '过期时间: ${expiresAt.toString().split('.')[0]}',
                            style: TextStyle(
                              color: isExpired ? Colors.grey : Colors.red,
                            ),
                          ),
                          Text(
                            isExpired ? '已过期' : '有效',
                            style: TextStyle(
                              color: isExpired ? Colors.grey : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _isLoading ? null : () => _removeFromBlacklist(ip['ip']),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWhitelistTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: '添加IP到白名单',
                    hintText: '输入IP地址',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _addToWhitelist(_ipController.text.trim()),
                child: const Text('添加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _defenceService.getWhitelist(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('加载失败: ${snapshot.error}'));
              }

              final ips = snapshot.data ?? [];
              if (ips.isEmpty) {
                return const Center(child: Text('白名单为空'));
              }

              return ListView.builder(
                itemCount: ips.length,
                itemBuilder: (context, index) {
                  final ip = ips[index];
                  final createdAt = DateTime.parse(ip['created_at']).toLocal();
                  final expiresAt = DateTime.parse(ip['expires_at']).toLocal();
                  final isExpired = expiresAt.isBefore(DateTime.now());

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(ip['ip']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('添加时间: ${createdAt.toString().split('.')[0]}'),
                          Text(
                            '过期时间: ${expiresAt.toString().split('.')[0]}',
                            style: TextStyle(
                              color: isExpired ? Colors.grey : Colors.green,
                            ),
                          ),
                          Text(
                            isExpired ? '已过期' : '有效',
                            style: TextStyle(
                              color: isExpired ? Colors.grey : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _isLoading ? null : () => _removeFromWhitelist(ip['ip']),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}