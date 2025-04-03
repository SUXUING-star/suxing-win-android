// lib/screens/admin/widgets/user_management.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 假设你的导航工具在这里
import '../../../providers/auth/auth_provider.dart';
import '../../../services/main/user/user_service.dart';
import '../../../services/main/user/user_ban_service.dart';
import 'package:intl/intl.dart'; // 用于日期格式化

class UserManagement extends StatefulWidget {
  const UserManagement({Key? key}) : super(key: key);

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final UserService _userService = UserService();
  final UserBanService _banService = UserBanService();
  bool _loading = false;
  int _refreshCounter = 0;

  // 刷新用户列表
  void _refreshUserList() {
    setState(() {
      _refreshCounter++;
    });
  }

  // --- 对话框函数 (_showBanDialog, _showUnbanDialog) 保持不变 ---
  // (请确保它们内部也使用 user['id'] 作为用户ID)
  Future<void> _showBanDialog(BuildContext context, Map<String, dynamic> user) async {
    final TextEditingController reasonController = TextEditingController();
    DateTime? endTime;
    bool isPermanent = true;
    final rootContext = context;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('封禁用户'),
        content: SingleChildScrollView(
          child: Column(
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
                builder: (context, setStateDialog) => Column(
                  children: [
                    CheckboxListTile(
                      title: Text('永久封禁'),
                      value: isPermanent,
                      onChanged: (value) {
                        setStateDialog(() {
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
                        subtitle: Text(endTime != null
                            ? DateFormat('yyyy-MM-dd HH:mm').format(endTime!) // 使用格式化
                            : '请选择'),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          final now = DateTime.now();
                          // 确保 initialDate 不早于 firstDate
                          final initialPickDate = (endTime ?? now.add(Duration(days: 7))).isBefore(now)
                              ? now
                              : (endTime ?? now.add(Duration(days: 7)));

                          final date = await showDatePicker(
                            context: context,
                            initialDate: initialPickDate,
                            firstDate: now,
                            lastDate: now.add(Duration(days: 365 * 10)), // 允许更长
                          );

                          if (date != null) {
                            final initialPickTime = TimeOfDay.fromDateTime(endTime ?? now.add(Duration(days: 7)));
                            final time = await showTimePicker(
                              context: context,
                              initialTime: initialPickTime,
                            );

                            if (time != null) {
                              setStateDialog(() {
                                endTime = DateTime(
                                  date.year, date.month, date.day,
                                  time.hour, time.minute,
                                );
                                // 确保选择的时间不早于当前时间
                                if (endTime!.isBefore(DateTime.now())) {
                                  endTime = DateTime.now().add(Duration(minutes: 5)); // 或给个最小默认值
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('解封时间不能早于当前时间'))
                                  );
                                }
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
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationUtils.pop(dialogContext),
            child: Text('取消'),
          ),
          ElevatedButton(
            // 只有在不 loading 时才响应
            onPressed: _loading ? null : () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(content: Text('请输入封禁原因')),
                );
                return;
              }
              // 确保选择了时间（如果不是永久）
              if (!isPermanent && endTime == null) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(content: Text('请选择解封时间')),
                );
                return;
              }
              // 确保时间有效
              if (!isPermanent && endTime != null && endTime!.isBefore(DateTime.now())) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(content: Text('解封时间不能早于当前时间')),
                );
                return;
              }

              setState(() => _loading = true);
              try {
                final authProvider = Provider.of<AuthProvider>(rootContext, listen: false);
                await _banService.banUser(
                  userId: user['id'].toString(), // <--- 使用 'id'
                  reason: reasonController.text.trim(),
                  endTime: isPermanent ? null : endTime,
                  bannedBy: authProvider.currentUser!.id,
                );
                NavigationUtils.pop(dialogContext);
                if (mounted) {
                  _refreshUserList();
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text('用户 ${user['username']} 已被封禁')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text('封禁失败：$e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _loading = false);
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
            onPressed: () => NavigationUtils.pop(dialogContext),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: _loading ? null : () async {
              setState(() => _loading = true);
              try {
                await _banService.unbanUser(user['id'].toString()); // <--- 使用 'id'
                NavigationUtils.pop(dialogContext);
                if(mounted) {
                  _refreshUserList();
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text('已解除用户 ${user['username']} 的封禁')),
                  );
                }
              } catch (e) {
                if(mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text('操作失败：$e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _loading = false);
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false); // 获取一次即可

    // 权限检查
    if (!authProvider.isSuperAdmin) {
      return const Center(
        child: Text('只有超级管理员可以访问用户管理'),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_refreshCounter),
      future: _userService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('加载用户列表失败: ${snapshot.error}\n请尝试下拉刷新。'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('没有用户数据'));
        }

        final users = snapshot.data!;
        final currentUserId = authProvider.currentUser?.id; // 获取当前用户ID

        return RefreshIndicator(
          onRefresh: () async => _refreshUserList(),
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userId = user['id']?.toString(); // 获取用户ID字符串

              // --- 核心改动：不显示当前登录用户 ---
              if (userId == null || userId == currentUserId) {
                return const SizedBox.shrink(); // 如果是自己或者ID无效，则不显示
              }

              // --- 解析状态 ---
              final isAdmin = user['isAdmin'] as bool? ?? false;
              final banInfo = user['banInfo']; // banInfo 是 map 或者 null
              final isBanned = banInfo != null;
              String banReason = banInfo?['reason'] ?? '无';
              String banStatusText = '已封禁';
              if (isBanned) {
                if (banInfo!['isPermanent'] == true) { // 显式检查布尔值
                  banStatusText += ' (永久)';
                } else if (banInfo['endTime'] != null) {
                  try {
                    // 尝试解析时间并格式化
                    final endTime = DateTime.parse(banInfo['endTime']);
                    banStatusText += ' (至: ${DateFormat('yyyy-MM-dd').format(endTime)})';
                  } catch (e) {
                    banStatusText += ' (时间格式错误)'; // 添加解析错误提示
                  }
                }
              }


              // --- 重写 UI 组件 ---
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(


                  // 2. 标题 (用户名)
                  title: Text(
                    user['username'] ?? '未知用户',
                    style: TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 3. 副标题 (邮箱和封禁状态)
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0), // 和标题间距
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // 紧凑布局
                      children: [
                        // 邮箱
                        Text(
                          user['email'] ?? '无邮箱',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // 封禁状态 (如果被封禁)
                        if (isBanned)
                          Tooltip( // 使用 Tooltip 显示完整原因
                            message: '原因: $banReason',
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                banStatusText,
                                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                                maxLines: 1, // 限制只显示一行状态
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 4. 尾部操作区域 (管理员开关 + 封禁/解封按钮)
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // 让 Row 宽度自适应内容
                    children: [
                      // 管理员开关 (加点文字提示)
                      Text(isAdmin ? '管理员' : '用户', style: TextStyle(fontSize: 10)),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
                        children: [

                          SizedBox(
                            height: 20, // 给 Switch 固定一点高度，避免跳动
                            child: Switch(
                              value: isAdmin,
                              onChanged: _loading ? null : (bool value) async {
                                setState(() => _loading = true);
                                try {
                                  await _userService.updateUserAdminStatus(userId, value); // 使用 userId
                                  _refreshUserList(); // 刷新整个列表
                                  if(mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('用户 ${user['username']} 已${value ? '设置' : '取消'}管理员'), duration: Duration(seconds: 1)),
                                    );
                                  }
                                } catch (e) {
                                  if(mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('操作失败: $e')),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _loading = false);
                                }
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 减小点击区域
                            ),
                          ),
                        ],
                      ),
                      // 封禁/解封按钮
                      IconButton(
                        icon: Icon(
                          isBanned ? Icons.lock_open : Icons.block,
                          color: isBanned ? Colors.orange.shade700 : Colors.red.shade700,
                          size: 20, // 稍微小一点的图标
                        ),
                        tooltip: isBanned ? '解除封禁' : '封禁用户',
                        onPressed: _loading ? null : () {
                          if (isBanned) {
                            _showUnbanDialog(context, user);
                          } else {
                            _showBanDialog(context, user);
                          }
                        },
                      ),
                    ],
                  ),
                  // 根据是否有封禁信息调整 ListTile 高度
                  isThreeLine: isBanned,
                  dense: true, // 尝试使用更紧凑的布局
                  contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0), // 调整内边距
                ),
              );
            },
          ),
        );
      },
    );
  }
}