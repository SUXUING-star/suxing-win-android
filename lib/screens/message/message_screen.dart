import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 需要导航工具
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../services/main/message/message_service.dart';
import '../../models/message/message.dart';
import '../../models/message/message_type.dart'; // 需要 MessageTypeInfo
import '../../utils/device/device_utils.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/message/message_detail.dart';
import '../../widgets/components/screen/message/message_list.dart';

/// 消息中心屏幕
class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final MessageService _messageService = MessageService();
  bool _isLoading = true; // 是否正在加载数据
  bool _allMessagesRead = false; // 是否所有消息都已读

  // 存储按类型分组的消息列表
  Map<String, List<Message>> _groupedMessages = {};
  // 存储排序后的消息类型 key
  List<String> _sortedTypeKeys = [];

  // 控制桌面端右侧详情面板的显示
  bool _showMessageDetails = false;
  // 当前在详情面板中显示的消息
  Message? _selectedMessage;

  // 存储 ExpansionTile 的展开状态 (key: typeKey, value: isExpanded)
  final Map<String, bool> _expansionState = {};

  @override
  void initState() {
    super.initState();
    _loadGroupedMessages(); // 初始化时加载消息
  }

  @override
  void dispose() {
    _messageService.dispose(); // 清理消息流监听器
    super.dispose();
  }

  /// 加载并处理分组消息
  Future<void> _loadGroupedMessages() async {
    if (!mounted) return; // 如果页面已销毁，则不执行
    setState(() {
      _isLoading = true;
    }); // 开始加载，显示加载指示器

    try {
      // 调用服务获取分组消息
      final groupedMessages = await _messageService.getGroupedMessagesOnce();
      if (!mounted) return; // 获取数据后再次检查页面是否还在

      // 对每个分组内部的消息按时间倒序排序 (最新的在前)
      groupedMessages.forEach((key, messages) {
        messages.sort((a, b) => b.displayTime.compareTo(a.displayTime));
      });

      // 对消息类型进行排序 (这里按类型的显示名称排序)
      final sortedKeys = groupedMessages.keys.toList()
        ..sort((a, b) {
          // 使用 MessageTypeInfo.fromString 将 key 转换为枚举
          MessageType typeA = MessageTypeInfo.fromString(a);
          MessageType typeB = MessageTypeInfo.fromString(b);
          // 按显示名称的字母顺序排序
          return typeA.displayName.compareTo(typeB.displayName);
        });

      // 初始化或保留 ExpansionTile 的展开状态
      for (var key in sortedKeys) {
        if (!_expansionState.containsKey(key)) {
          // 只初始化一次
          // 默认展开第一个分组，或者包含未读消息的分组
          bool shouldExpand = (sortedKeys.first == key) ||
              (groupedMessages[key]?.any((m) => !m.isRead) ?? false);
          _expansionState[key] = shouldExpand;
        }
      }

      // 更新状态
      setState(() {
        _groupedMessages = groupedMessages;
        _sortedTypeKeys = sortedKeys;
        _checkAllMessagesReadStatus(); // 检查全局已读状态
        _isLoading = false; // 加载完成
      });
    } catch (e, stackTrace) {
      print('加载分组消息失败: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      }); // 加载失败也要结束加载状态
      // 显示错误提示
      AppSnackBar.showError(context, '加载消息失败: $e');
    }
  }

  /// 检查是否所有消息都已读，并更新 _allMessagesRead 状态
  void _checkAllMessagesReadStatus() {
    bool allRead = true;
    // 使用 for...in 循环遍历 keys，允许内部 break
    for (var key in _groupedMessages.keys) {
      // 使用 for...in 循环遍历 messages，允许内部 break
      for (var message in _groupedMessages[key]!) {
        if (!message.isRead) {
          allRead = false;
          break; // 找到一个未读，内层循环结束
        }
      }
      if (!allRead) {
        break; // 找到一个未读，外层循环也结束
      }
    }

    // 仅当状态变化时才调用 setState，避免不必要的重绘
    if (mounted && _allMessagesRead != allRead) {
      setState(() {
        _allMessagesRead = allRead;
      });
    }
  }

  /// 获取指定类型下的未读消息数量
  int _getUnreadCountForType(String typeKey) {
    return _groupedMessages[typeKey]?.where((m) => !m.isRead).length ?? 0;
  }

  /// 标记所有消息为已读
  Future<void> _markAllAsRead() async {
    if (_allMessagesRead || !mounted) return; // 如果已全部已读或页面已销毁，则不操作
    try {
      await _messageService.markAllAsRead(); // 调用 API
      // 成功后重新加载数据以确保同步
      await _loadGroupedMessages();
      if (mounted) {
        AppSnackBar.showSuccess(context, '已将所有消息标记为已读');
      }
    } catch (e, stackTrace) {
      print('标记所有消息为已读失败: $e\n$stackTrace');
      if (mounted) {
        // 标记失败时，也建议重新加载以获取真实状态
        await _loadGroupedMessages();
        AppSnackBar.showError(context, '标记已读操作失败，请重试: $e');
      }
    } finally {
      // 可选：结束加载状态
      // if (mounted) setState(() { /* 结束加载状态 */ });
    }
  }

  /// 处理消息列表项被点击的事件
  void _handleMessageTap(Message message) async {
    if (!mounted) return;
    bool needsStateUpdate = false; // 是否需要更新 UI (例如移除未读标记)
    Message messageForUi = message; // 用于后续操作的消息对象 (可能被更新)

    // 步骤 1: 如果消息未读，标记为已读 (本地乐观更新 + 远程 API调用)
    if (!message.isRead) {
      try {
        // 在 groupedMessages 中找到这条消息并更新它
        String? targetKey;
        int? targetIndex;
        for (var key in _groupedMessages.keys) {
          final list = _groupedMessages[key]!;
          final index = list.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            targetKey = key;
            targetIndex = index;
            break;
          }
        }

        if (targetKey != null && targetIndex != null) {
          // 使用 copyWith 创建新对象，标记为已读
          final updatedMessage =
              message.copyWith(isRead: true, readTime: DateTime.now());
          // 更新 groupedMessages 中的对象
          _groupedMessages[targetKey]![targetIndex] = updatedMessage;
          messageForUi = updatedMessage; // 后续使用更新后的对象
          needsStateUpdate = true; // 标记需要更新 UI
          print('本地标记已读成功: ID=${message.id}');

          // 如果详情面板显示的是这条消息，也同步更新
          if (_selectedMessage?.id == message.id) {
            _selectedMessage = updatedMessage;
          }

          // 异步调用 API 在后端标记已读 (不需要 await，避免阻塞 UI)
          _messageService.markAsRead(message.id).then((_) {
            // 可以在这里再次检查全局已读状态，确保精确
            if (mounted) _checkAllMessagesReadStatus();
          }).catchError((e, stackTrace) {
            // 远程标记失败的处理
            // 简单处理：可以提示用户，或者让下次刷新来同步状态
            // 注意：不建议在这里回滚本地状态，可能导致 UI 闪烁
            if (mounted) {}
          });
        } else {
          // 如果在列表中找不到消息（理论上不应发生），记录警告并尝试直接调用 API
          print("警告: 未在 _groupedMessages 中找到要标记已读的消息 ID: ${message.id}");
          await _messageService.markAsRead(message.id); // 尝试直接调用
          _loadGroupedMessages(); // 作为后备，重新加载列表
        }
      } catch (e, stackTrace) {
        print("处理标记已读时本地发生错误: $e\n$stackTrace");
        // 本地处理错误（例如 copyWith 失败？）
      }
    }

    // 步骤 2: 如果状态有更新，则刷新 UI
    if (needsStateUpdate && mounted) {
      setState(() {}); // 重绘列表项，移除未读标记等
      _checkAllMessagesReadStatus(); // 重新检查全局已读状态
    }

    // 步骤 3: 根据平台执行操作 (显示详情或导航)
    if (DeviceUtils.isDesktop) {
      // 桌面端：更新右侧详情面板
      setState(() {
        _selectedMessage = messageForUi; // 显示（可能已更新的）消息详情
        _showMessageDetails = true;
      });
    } else {
      // 移动端：直接尝试导航到关联页面
      _performNavigation(messageForUi);
    }
  }

  /// 执行导航到消息关联页面的操作
  void _performNavigation(Message message) {
    if (!mounted) return;
    // 从消息模型获取导航所需信息
    final navigationInfo = message.navigationDetails;

    if (navigationInfo != null) {
      // 如果有导航信息，则执行导航
      //print('导航到路由: ${navigationInfo.routeName}, 参数: ${navigationInfo.arguments}');
      NavigationUtils.pushNamed(
        context,
        navigationInfo.routeName, // 使用模型提供的路由名称
        arguments: navigationInfo.arguments, // 使用模型提供的参数
      ).catchError((e, stackTrace) {
        // 处理导航过程中可能发生的错误 (例如路由不存在或参数错误)
        //print("导航失败: Route=${navigationInfo.routeName}, Args=${navigationInfo.arguments}, Error: $e\n$stackTrace");
        if (mounted) {
          // 可以显示一个通用的错误提示页面或 SnackBar
          // NavigationUtils.push(context, MaterialPageRoute(builder: (_) => RouteErrorScreen.genericError(onAction: () => Navigator.pop(context))));
          AppSnackBar.showError(context, '无法打开目标页面，请稍后重试。');
        }
      });
    } else {
      // 如果没有导航信息，提示用户
      //print("消息 (ID: ${message.id}, Type: ${message.messageType.name}) 没有可导航的目标。");
      if (!DeviceUtils.isDesktop && mounted) {
        _showUnsupportedNavigationDialog(); // 移动端显示弹窗提示
      }
      // 桌面端，如果详情面板没打开，确保打开它
      else if (DeviceUtils.isDesktop && mounted && !_showMessageDetails) {
        setState(() {
          _selectedMessage = message;
          _showMessageDetails = true;
        });
      }
    }
  }

  /// 显示不支持导航的提示对话框 (移动端)
  void _showUnsupportedNavigationDialog() {
    CustomInfoDialog(
      title: '提示',
      message: '此消息没有可查看的关联页面。',
      onClose: () => Navigator.of(context).pop(),
      closeButtonText: "好的",
    );
  }

  /// 显示删除确认对话框
  void _showDeleteDialog(Message message) {
    if (!mounted) return;

    // 使用 CustomConfirmDialog.show 静态方法来显示对话框
    CustomConfirmDialog.show(
      context: context,
      title: '确认删除', // 对话框标题
      message: '确定要删除这条消息吗？此操作无法撤销。', // 对话框消息
      confirmButtonText: '删除', // 确认按钮文本
      confirmButtonColor: Colors.red, // 确认按钮颜色 (红色表示危险操作)
      iconData: Icons.delete_outline, // 使用删除相关的图标
      iconColor: Colors.red, // 图标颜色与按钮匹配

      // --- 关键：提供 onConfirm 回调 ---
      // 这个回调是一个异步函数，执行实际的删除操作
      onConfirm: () async {
        // CustomConfirmDialog 会在执行此回调时显示加载指示器
        if (!mounted) return; // 再次检查 mounted 状态，以防万一

        try {
          // 调用服务执行删除操作
          await _messageService.deleteMessage(message.id);
          if (!mounted) return; // 异步操作后再次检查

          // --- 删除成功 ---
          // 1. 关闭对话框 (重要：在异步操作成功后手动关闭)
          //    因为 CustomConfirmDialog 将关闭责任交给了 onConfirm
          Navigator.of(context).pop();

          // 2. 如果删除的是当前详情页显示的消息，关闭详情面板 (桌面端)
          if (_selectedMessage?.id == message.id) {
            setState(() {
              _selectedMessage = null;
              _showMessageDetails = false;
            });
          }

          // 3. 重新加载消息列表以反映删除
          await _loadGroupedMessages();

          // 4. 显示成功提示 (检查 mounted)
          if (mounted) {
            AppSnackBar.showSuccess(context, '消息已删除');
          }
        } catch (e, stackTrace) {
          print("删除消息失败: ID=${message.id}, Error: $e\n$stackTrace");
          if (!mounted) return; // 异步操作后再次检查

          // 2. 显示错误提示
          AppSnackBar.showError(context, '删除失败: $e');
        }
        // 注意：不需要在这里管理加载状态 (如 _isLoading)，CustomConfirmDialog 内部处理
      },
    );
  }

  /// 构建主内容区域 (包含可折叠的消息分组列表)
  /// 构建主内容区域 (包含可折叠的消息分组列表或空状态)
  Widget _buildMessageContent() {
    // 加载状态
    if (_isLoading && _groupedMessages.isEmpty) {
      return LoadingWidget.fullScreen(message: "正在加载消息");
    }

    return RefreshIndicator(
        onRefresh: _loadGroupedMessages,
        child: _groupedMessages.isEmpty && !_isLoading
            ? _buildEmptyContent()
            // 情况二：数据不为空，显示消息列表
            : _buildMainContent());
  }

  Widget _buildEmptyContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            alignment: Alignment.center,
            // *** 修改这里：为空状态添加动画 ***
            child: FadeInSlideUpItem(
              // 使用 FadeInSlideUpItem 包裹
              child: EmptyStateWidget(
                message: '暂无任何消息',
                iconData: Icons.mark_as_unread_outlined,
              ),
            ),
            // *** 结束修改 ***
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    // 添加 Key，帮助动画识别列表变化
    final listKey = ValueKey<int>(_sortedTypeKeys.length);

    return ListView.builder(
      key: listKey, // 应用 Key
      itemCount: _sortedTypeKeys.length,
      itemBuilder: (context, index) {
        final typeKey = _sortedTypeKeys[index];
        final messagesForType = _groupedMessages[typeKey] ?? [];
        final messageType = MessageTypeInfo.fromString(typeKey);
        final typeDisplayName = messageType.displayName;
        final unreadCount = _getUnreadCountForType(typeKey);

        // --- 提取 ExpansionTile 的 children 构建逻辑 ---
        List<Widget> buildExpansionChildren() {
          if (messagesForType.isEmpty) {
            // 空状态也加个简单动画
            return [
              Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20.0),
                  // *** 修改这里：空消息提示添加动画 ***
                  child: FadeInItem(
                    // 使用 FadeInItem
                    child: EmptyStateWidget(
                        message: '此类消息暂无内容',
                        iconData: Icons.messenger_outline_outlined,
                        iconColor: Colors.grey),
                  )
                  // *** 结束修改 ***
                  )
            ];
          } else {
            // *** 修改这里：为 MessageList 添加动画 ***
            // 注意：这里是整体动画，非列表项逐个动画
            return [
              FadeInSlideUpItem(
                // 使用 FadeInSlideUpItem 包裹 MessageList
                // 可以根据需要调整 duration 和 delay
                // delay: Duration(milliseconds: 100), // 展开后轻微延迟出现
                duration: Duration(milliseconds: 300),
                child: MessageList(
                  messages: messagesForType,
                  onMessageTap: _handleMessageTap,
                  selectedMessage: _selectedMessage,
                  isCompact: DeviceUtils.isDesktop,
                ),
              )
            ];
            // *** 结束修改 ***
          }
        }
        // --- 结束提取 ---

        return ExpansionTile(
          key: PageStorageKey(typeKey), // 保持 Key 用于保存状态
          initiallyExpanded: _expansionState[typeKey] ?? false,
          onExpansionChanged: (isExpanded) {
            if (mounted) {
              setState(() {
                _expansionState[typeKey] = isExpanded;
              });
            }
          },
          // --- ExpansionTile 标题和样式保持不变 ---
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(typeDisplayName,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis)),
              if (unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('$unreadCount',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          childrenPadding: EdgeInsets.zero,
          tilePadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          backgroundColor: Colors.grey[50],
          collapsedBackgroundColor: Colors.white,
          iconColor: Theme.of(context).primaryColor,
          collapsedIconColor: Colors.grey[600],
          // --- 使用提取的 children 构建逻辑 ---
          children: buildExpansionChildren(),
        );
      },
      padding: EdgeInsets.only(bottom: 16.0),
    );
  }

  Widget _iconRead() {
    return IconButton(
      icon: Icon(Icons.done_all),
      tooltip: '全部标为已读',
      onPressed: _markAllAsRead,
    );
  }

  Widget _iconRefresh() {
    return IconButton(
      icon: Icon(Icons.refresh),
      tooltip: '刷新',
      onPressed: _loadGroupedMessages, // 点击时重新加载数据
    );
  }

  Widget? _buildRightPanel() {
    return _showMessageDetails && _selectedMessage != null
        ? MessageDetail(
            message: _selectedMessage!, // 传递选中的消息
            // 关闭详情面板的回调
            onClose: () {
              if (mounted) {
                setState(() {
                  _showMessageDetails = false;
                  _selectedMessage = null; // 清除选中状态
                });
              }
            },
            // 删除按钮的回调
            onDelete: () => _showDeleteDialog(_selectedMessage!),
            // "查看关联" 按钮的回调
            onViewDetail: (message) {
              _performNavigation(message); // 在详情面板点击时也执行导航
            },
          )
        : null; // 如果没有选中消息，则右侧面板为 null
  }

  /// 构建桌面端布局
  Widget _buildDesktopLayout() {
    final sidePanelWidth = DeviceUtils.getSidePanelWidth(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: '消息中心',
        actions: [if (!_allMessagesRead) _iconRead(), _iconRefresh()],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content (左侧列表)
          Expanded(
            child: _buildMessageContent(),
          ),

          // AnimatedSwitcher for the right panel
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _showMessageDetails && _selectedMessage != null
                ? Container(
              // Key is important for AnimatedSwitcher to detect changes
              key: ValueKey<String>(_selectedMessage!.id),
              width: sidePanelWidth,
              // --- 修改开始: 移除无限高度 ---
              // height: double.infinity, // REMOVE THIS LINE
              // --- 修改结束 ---
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(-2, 0),
                  ),
                ],
              ),
              // Ensure the MessageDetail widget itself can handle height correctly
              child: _buildRightPanel(),
            )
            // Use SizedBox.shrink() for the 'empty' state
                : SizedBox.shrink(key: ValueKey<String>('empty_panel')),
          ),
        ],
      ),
    );
  }

  /// 构建移动端布局
  Widget _buildMobileLayout() {
    return Scaffold(
      // 使用自定义 AppBar
      appBar: CustomAppBar(
        title: '消息中心',
        actions: [
          // AppBar 上的操作按钮
          if (!_allMessagesRead) _iconRead(),
          // 添加刷新按钮
          _iconRefresh()
        ],
        // 移动端不需要 bottom TabBar 了
      ),
      // 主体内容
      body: _buildMessageContent(),
    );
  }

  /// 构建整体页面结构 (区分移动端和桌面端)
  @override
  Widget build(BuildContext context) {
    // 根据设备类型选择不同的布局
    if (DeviceUtils.isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }
}
