// lib/screens/message/message_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/screens/profile/open_profile_screen.dart';
import '../../services/main/message/message_service.dart';
import '../../models/message/message.dart';
import '../../models/message/message_type.dart';
import '../../utils/device/device_utils.dart';
import '../../widgets/common/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/message/message_detail.dart';
import '../../widgets/components/screen/message/message_tabs.dart';
import '../../widgets/components/screen/message/message_desktop_layout.dart';
import '../game/detail/game_detail_screen.dart';
import '../forum/post/post_detail_screen.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> with SingleTickerProviderStateMixin {
  final MessageService _messageService = MessageService();
  bool _isLoading = true;
  bool _allMessagesRead = false;

  // 分组消息存储
  Map<String, List<Message>> _groupedMessages = {};

  // Tab控制器
  late TabController _tabController;

  // Tab标签
  late List<String> _tabLabels;

  // 桌面布局控制
  bool _showMessageDetails = false;
  Message? _selectedMessage;

  @override
  void initState() {
    super.initState();

    // 初始化Tab标签
    _tabLabels = [
      '全部',
      '帖子回复',
      '评论回复',
      '关注通知',  // 新增
    ];

    // 初始化TabController
    _tabController = TabController(
        length: _tabLabels.length,
        vsync: this
    );

    _loadGroupedMessages();
  }

  @override
  void dispose() {
    // 确保页面关闭时取消订阅流和释放TabController
    _messageService.disposeMessageStream();
    _tabController.dispose();
    super.dispose();
  }

  // 加载分组消息
  Future<void> _loadGroupedMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取最新分组消息
      final groupedMessages = await _messageService.getGroupedMessagesOnce();

      setState(() {
        _groupedMessages = groupedMessages;

        // 检查是否所有消息都已读
        bool allRead = true;
        groupedMessages.forEach((key, messages) {
          for (var message in messages) {
            if (!message.isRead) {
              allRead = false;
              break;
            }
          }
        });

        _allMessagesRead = allRead;
        _isLoading = false;
      });
    } catch (e) {
      print('加载分组消息失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 标记所有消息为已读
  Future<void> _markAllAsRead() async {
    try {
      await _messageService.markAllAsRead();

      // 重新加载消息列表
      await _loadGroupedMessages();

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已将所有消息标记为已读'))
      );
    } catch (e) {
      print('标记所有消息为已读失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'))
      );
    }
  }

  void _handleMessageTap(Message message) async {
    print('消息类型: ${message.type}, gameId: ${message.gameId}, postId: ${message.postId}');

    // 在桌面端，只显示详情面板
    if (DeviceUtils.isDesktop) {
      setState(() {
        _selectedMessage = message;
        _showMessageDetails = true;
      });

      // 标记为已读
      if (!message.isRead) {
        await _messageService.markAsRead(message.id);
        // 重新加载消息以更新状态
        _loadGroupedMessages();
      }
      return;
    }

    // 移动端行为：跳转到相应页面
    // 先标记为已读
    if (!message.isRead) {
      await _messageService.markAsRead(message.id);
      // 重新加载消息以更新状态
      _loadGroupedMessages();
    }

    _navigateToMessageTarget(message);
  }

  void _navigateToMessageTarget(Message message) {
    // 修改类型判断逻辑，兼容不同格式的类型值
    // 对于评论回复类型
    bool isCommentReply = message.type.toLowerCase().contains("comment") ||
        message.type == MessageType.commentReply.toString();

    // 对于帖子回复类型
    bool isPostReply = message.type.toLowerCase().contains("post") ||
        message.type == MessageType.postReply.toString();

    // 对于关注通知类型
    bool isFollowNotification = message.type.toLowerCase().contains("follow") ||
        message.type == MessageType.followNotification.toString();

    // 根据消息类型跳转到相应页面
    if (isCommentReply && message.gameId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameDetailScreen(gameId: message.gameId!),
        ),
      );
    } else if (isPostReply && message.postId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(postId: message.postId!),
        ),
      );
    } else if (isFollowNotification && message.senderId.isNotEmpty) {
      // 关注通知跳转到用户个人页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OpenProfileScreen(userId: message.senderId),
        ),
      );
    }
  }

  // 显示删除确认对话框
  void _showDeleteDialog(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除消息'),
        content: Text('确定要删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await _messageService.deleteMessage(message.id);
              Navigator.pop(context);

              // 如果当前选中的消息被删除，关闭详情面板
              if (_selectedMessage?.id == message.id) {
                setState(() {
                  _selectedMessage = null;
                  _showMessageDetails = false;
                });
              }

              // 重新加载消息
              _loadGroupedMessages();
            },
            child: Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果是桌面环境，使用DesktopLayout
    if (DeviceUtils.isDesktop) {
      return _buildDesktopLayout();
    }

    // 移动端使用普通布局
    return _buildMobileLayout();
  }

  // 桌面布局
  Widget _buildDesktopLayout() {
    return MessageDesktopLayout(
      title: '消息中心',
      actions: [
        // 只在有未读消息时显示"全部标为已读"按钮
        if (!_allMessagesRead)
          IconButton(
            icon: Icon(Icons.done_all),
            tooltip: '全部标为已读',
            onPressed: _markAllAsRead,
          ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        indicatorColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : MessageTabs(
        groupedMessages: _groupedMessages,
        tabController: _tabController,
        tabLabels: _tabLabels,
        messageService: _messageService,
        onMessageTap: _handleMessageTap,
        selectedMessage: _selectedMessage,
        onRefresh: _loadGroupedMessages,
        isCompact: false,
      ),
      // 右侧面板：消息详情
      rightPanel: _showMessageDetails && _selectedMessage != null
          ? MessageDetail(
        message: _selectedMessage!,
        onClose: () {
          setState(() {
            _showMessageDetails = false;
            _selectedMessage = null;
          });
        },
        onDelete: () => _showDeleteDialog(_selectedMessage!),
        onViewDetail: _navigateToMessageTarget,
      )
          : null,
      rightPanelVisible: _showMessageDetails && _selectedMessage != null,
    );
  }

  // 移动端布局
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: CustomAppBar(
        title: '消息中心',
        actions: [
          // 只在有未读消息时显示"全部标为已读"按钮
          if (!_allMessagesRead)
            IconButton(
              icon: Icon(Icons.done_all),
              tooltip: '全部标为已读',
              onPressed: _markAllAsRead,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
          indicatorColor: Colors.white,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : MessageTabs(
        groupedMessages: _groupedMessages,
        tabController: _tabController,
        tabLabels: _tabLabels,
        messageService: _messageService,
        onMessageTap: _handleMessageTap,
        selectedMessage: _selectedMessage,
        onRefresh: _loadGroupedMessages,
        isCompact: false,
      ),
    );
  }
}