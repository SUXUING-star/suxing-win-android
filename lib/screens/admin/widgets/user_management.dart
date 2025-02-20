// lib/screens/admin/widgets/user_management.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../services/user_service.dart';
import '../../../services/ban/user_ban_service.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({Key? key}) : super(key: key);

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final UserService _userService = UserService();
  final UserBanService _banService = UserBanService();
  bool _loading = false;

  Future<bool> _checkBanStatus(String userId) async {
    final ban = await _banService.checkUserBan(userId);
    return ban != null;
  }

  Future<void> _showBanDialog(BuildContext context, Map<String, dynamic> user) async {
    final TextEditingController reasonController = TextEditingController();
    DateTime? endTime;
    bool isPermanent = true;

    // 在这里获取根级别的 context
    final rootContext = context;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('封禁用户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('确定要封禁用户 ${user['username']} 吗？'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: '封禁原因',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  CheckboxListTile(
                    title: Text('永久封禁'),
                    value: isPermanent,
                    onChanged: (value) {
                      setState(() {
                        isPermanent = value!;
                        if (!isPermanent && endTime == null) {
                          endTime = DateTime.now().add(Duration(days: 7));
                        }
                      });
                    },
                  ),
                  if (!isPermanent)
                    ListTile(
                      title: Text('解封时间'),
                      subtitle: Text(endTime?.toString().split('.')[0] ?? ''),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endTime ?? DateTime.now().add(Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );

                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                                endTime ?? DateTime.now().add(Duration(days: 7))
                            ),
                          );

                          if (time != null) {
                            setState(() {
                              endTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(content: Text('请输入封禁原因')),
                );
                return;
              }

              try {
                final authProvider = Provider.of<AuthProvider>(rootContext, listen: false);
                await _banService.banUser(
                  userId: user['_id'],
                  reason: reasonController.text,
                  endTime: isPermanent ? null : endTime,
                  bannedBy: authProvider.currentUser!.id,
                );

                Navigator.pop(dialogContext);
                if(mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text('用户已被封禁')),
                  );
                }
              } catch (e) {
                if(mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text('封禁失败：$e')),
                  );
                }
              }
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUnbanDialog(BuildContext context, Map<String, dynamic> user) async {
    final rootContext = context;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('解除封禁'),
        content: Text('确定要解除用户 ${user['username']} 的封禁吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _banService.unbanUser(user['_id'].toString());
                Navigator.pop(dialogContext);
                if(mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text('已解除封禁')),
                  );
                }
              } catch (e) {
                if(mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text('操作失败：$e')),
                  );
                }
              }
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isSuperAdmin) {
      return const Center(
        child: Text('只有超级管理员可以访问用户管理'),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('错误: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isAdmin = user['isAdmin'] as bool? ?? false;

            if (user['_id'] == authProvider.currentUser?.id) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<bool>(
              future: _checkBanStatus(user['_id']),
              builder: (context, banSnapshot) {
                final isBanned = banSnapshot.data ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user['username'] ?? '未知用户'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email'] ?? ''),
                        if (isBanned)
                          Text(
                            '已封禁',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isAdmin ? '管理员' : '普通用户'),
                        const SizedBox(width: 8),
                        Switch(
                          value: isAdmin,
                          onChanged: _loading ? null : (bool value) async {
                            setState(() => _loading = true);
                            try {
                              await _userService.updateUserAdminStatus(
                                user['_id'].toString(),
                                value,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '已${value ? '设置' : '取消'}管理员权限',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('操作失败：$e')),
                              );
                            } finally {
                              setState(() => _loading = false);
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isBanned ? Icons.lock_open : Icons.block,
                            color: isBanned ? Colors.orange : Colors.red,
                          ),
                          onPressed: () {
                            if (isBanned) {
                              _showUnbanDialog(context, user);
                            } else {
                              _showBanDialog(context, user);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}