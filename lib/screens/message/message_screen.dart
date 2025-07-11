// lib/screens/message/message_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/message/message_extension.dart';
import 'package:suxingchahui/models/message/message_navigation_Info.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 需要导航工具
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';
import 'package:suxingchahui/services/main/message/message_service.dart';
import 'package:suxingchahui/models/message/message.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/components/screen/message/message_detail.dart';
import 'package:suxingchahui/widgets/components/screen/message/message_list.dart';

/// 消息中心屏幕
class MessageScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final MessageService messageService;
  final WindowStateProvider windowStateProvider;

  const MessageScreen({
    super.key,
    required this.authProvider,
    required this.messageService,
    required this.windowStateProvider,
  });

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  bool _isLoading = false; // 是否正在加载数据
  bool _allMessagesRead = false; // 是否所有消息都已读

  // 存储按类型分组的消息列表
  Map<String, List<Message>> _groupedMessages = {};
  // 存储排序后的消息类型 key
  List<String> _sortedTypeKeys = [];

  // 控制桌面端右侧详情面板的显示
  bool _showMessageDetails = false;
  // 当前在详情面板中显示的消息
  Message? _selectedMessage;
  String? _currentUserId;
  bool _hasInitializedDependencies = false;

  // 存储 ExpansionTile 的展开状态 (key: typeKey, value: isExpanded)
  final Map<String, bool> _expansionState = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = false;
    }
    if (_hasInitializedDependencies) {
      _currentUserId = widget.authProvider.currentUserId;
      _loadGroupedMessages(); // 初始化时加载消息
    }
  }

  @override
  void dispose() {
    super.dispose();
    _currentUserId = null;
  }

  @override
  void didUpdateWidget(covariant MessageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUserId != widget.authProvider.currentUserId) {
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId;
        });
      }
    }
  }

  /// 加载并处理分组消息
  Future<void> _loadGroupedMessages() async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    if (!mounted) return; // 如果页面已销毁，则不执行
    setState(() {
      _isLoading = true;
    }); // 开始加载，显示加载指示器
    try {
      // 调用服务获取分组消息
      final groupedMessages =
          await widget.messageService.getGroupedMessagesOnce();
      if (!mounted) return; // 获取数据后再次检查页面是否还在

      // 对每个分组内部的消息按时间倒序排序 (最新的在前)
      groupedMessages.forEach((key, messages) {
        messages.sort((a, b) => b.displayTime.compareTo(a.displayTime));
      });

      // 对消息类型进行排序 (这里按类型的显示名称排序)
      final sortedKeys = groupedMessages.keys.toList()
        ..sort((a, b) {
          // 按显示名称的字母顺序排序
          return a.compareTo(b);
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      }); // 加载失败也要结束加载状态
      AppSnackBar.showError('加载消息失败: ${e.toString()}');
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
      await widget.messageService.markAllAsRead();
      // 成功后重新加载数据以确保同步
      await _loadGroupedMessages();

      AppSnackBar.showSuccess('已将所有消息标记为已读');
    } catch (e) {
      if (mounted) {
        await _loadGroupedMessages();
        AppSnackBar.showError('标记已读操作失败，请重试: ${e.toString()}');
      }
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
              message.copyWith(isRead: true, readTime: () => DateTime.now());
          // 更新 groupedMessages 中的对象
          _groupedMessages[targetKey]![targetIndex] = updatedMessage;
          messageForUi = updatedMessage; // 后续使用更新后的对象
          needsStateUpdate = true; // 标记需要更新 UI

          // 如果详情面板显示的是这条消息，也同步更新
          if (_selectedMessage?.id == message.id) {
            _selectedMessage = updatedMessage;
          }

          // 异步调用 API 在后端标记已读 (不需要 await，避免阻塞 UI)
          widget.messageService.markAsRead(message.id).then((_) {
            // 可以在这里再次检查全局已读状态，确保精确
            if (mounted) _checkAllMessagesReadStatus();
          }).catchError((e, stackTrace) {
            // 远程标记失败的处理
            // 简单处理：可以提示用户，或者让下次刷新来同步状态
            // 注意：不建议在这里回滚本地状态，可能导致 UI 闪烁
            if (mounted) {}
          });
        } else {
          await widget.messageService.markAsRead(message.id); // 尝试直接调用
          _loadGroupedMessages(); // 作为后备，重新加载列表
        }
      } catch (e) {
        //print("处理标记已读时本地发生错误: $e\n$stackTrace");
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
    final navigationInfo = message.navigationInfo;

    if (navigationInfo != null) {
      // 如果有导航信息，则执行导航
      //print('导航到路由: ${navigationInfo.routeName}, 参数: ${navigationInfo.arguments}');
      NavigationUtils.pushNamed(
        context,
        navigationInfo.routeName, // 使用模型提供的路由名称
        arguments: navigationInfo.arguments, // 使用模型提供的参数
      ).catchError((e, stackTrace) {
        AppSnackBar.showError('无法打开目标页面，请稍后重试。');
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
    CustomInfoDialog.show(
      context: context,
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
          await widget.messageService.deleteMessage(message.id);
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
          AppSnackBar.showSuccess('消息已删除');
        } catch (e) {
          //print("删除消息失败: ID=${message.id}, Error: $e\n$stackTrace");
          if (!mounted) return; // 异步操作后再次检查

          // 2. 显示错误提示
          AppSnackBar.showError('删除失败: ${e.toString()}');
        }
      },
    );
  }

  /// 构建主内容区域 (包含可折叠的消息分组列表)
  /// 构建主内容区域 (包含可折叠的消息分组列表或空状态)
  Widget _buildMessageContent() {
    // 加载状态
    if (_isLoading && _groupedMessages.isEmpty) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    return RefreshIndicator(
        onRefresh: _loadGroupedMessages,
        child: _groupedMessages.isEmpty && !_isLoading
            ? _buildEmptyContent()
            // 情况二：数据不为空，显示消息列表
            : _buildMainContent());
  }

  Widget _buildEmptyContent() {
    return const FadeInSlideUpItem(
      // 使用 FadeInSlideUpItem 包裹
      child: EmptyStateWidget(
        message: '暂无任何消息',
        iconData: Icons.mark_as_unread_outlined,
      ),
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
        final oneMessage = messagesForType[0];
        final textLabel = oneMessage.textLabel;
        final unreadCount = _getUnreadCountForType(typeKey);

        // --- 提取 ExpansionTile 的 children 构建逻辑 ---
        List<Widget> buildExpansionChildren() {
          if (messagesForType.isEmpty) {
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
          }
        }

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
                  child: Text(textLabel,
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
    if (!widget.authProvider.isLoggedIn) {
      return const SizedBox.shrink();
    } else {
      return IconButton(
        icon: Icon(Icons.refresh),
        tooltip: '刷新',
        onPressed: _loadGroupedMessages, // 点击时重新加载数据
      );
    }
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
  Widget _buildDesktopLayout(
    double screenWidth,
  ) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '消息中心',
        actions: [if (!_allMessagesRead) _iconRead(), _iconRefresh()],
      ),
      body: _buildDesktopBody(screenWidth),
    );
  }

  Widget _buildDesktopBody(
    double screenWidth,
  ) {
    final sidePanelWidth =
        DeviceUtils.getSidePanelWidthInScreenWidth(screenWidth);
    return StreamBuilder<bool>(
      stream: widget.authProvider.isLoggedInStream,
      initialData: widget.authProvider.isLoggedIn,
      builder: (context, authSnapshot) {
        final bool isLoggedIn =
            authSnapshot.data ?? widget.authProvider.isLoggedIn;
        if (!isLoggedIn) {
          return const LoginPromptWidget();
        }
        return Row(
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
                            color: Colors.black.withSafeOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(-2, 0),
                          ),
                        ],
                      ),
                      // Ensure the MessageDetail widget itself can handle height correctly
                      child: _buildRightPanel(),
                    )
                  // Use SizedBox.shrink() for the 'empty' state
                  : const SizedBox.shrink(key: ValueKey<String>('empty_panel')),
            ),
          ],
        );
      },
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
      body: StreamBuilder<bool>(
          stream: widget.authProvider.isLoggedInStream,
          initialData: widget.authProvider.isLoggedIn,
          builder: (context, authSnapshot) {
            final bool isLoggedIn =
                authSnapshot.data ?? widget.authProvider.isLoggedIn;
            if (!isLoggedIn) {
              return const LoginPromptWidget();
            }
            return _buildMessageContent();
          }),
    );
  }

  /// 构建整体页面结构 (区分移动端和桌面端)
  @override
  Widget build(BuildContext context) {
    // 根据设备类型选择不同的布局
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = DeviceUtils.isDesktopInThisWidth(screenWidth);
        return isDesktop
            ? _buildDesktopLayout(screenWidth)
            : _buildMobileLayout();
      },
    );
  }
}
