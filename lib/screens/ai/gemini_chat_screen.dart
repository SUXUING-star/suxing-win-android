// lib/screens/ai/gemini_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/main/ai/gemini_service.dart';
import 'dart:async';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isComplete;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isComplete = true,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({Key? key}) : super(key: key);

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  // 正在流式接收的消息文本
  String _currentStreamMessage = '';
  // 流订阅控制
  StreamSubscription<String>? _streamSubscription;
  // 是否正在接收流消息
  bool _isReceivingStream = false;

  @override
  void initState() {
    super.initState();
    // 添加欢迎消息
    _messages.add(
      ChatMessage(
        text: '你好！我是AI助手，有什么我可以帮助你的吗？',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _cancelStreamSubscription();
    super.dispose();
  }

  // 取消流订阅
  void _cancelStreamSubscription() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  // 发送消息
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 先添加用户消息
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messageController.clear();
    });

    // 滚动到底部
    _scrollToBottom();

    // 获取服务
    final geminiService = Provider.of<GeminiService>(context, listen: false);

    // 创建一个空的AI回复占位符
    setState(() {
      _currentStreamMessage = '';
      _isReceivingStream = true;
      _messages.add(
        ChatMessage(
          text: _currentStreamMessage,
          isUser: false,
          isComplete: false,
        ),
      );
    });

    // 请求流式响应
    final stream = geminiService.generateContentStream(prompt: text);

    // 订阅流
    _streamSubscription = stream.listen(
          (chunk) {
        // 更新当前流消息
        setState(() {
          _currentStreamMessage += chunk;
          // 更新最后一条消息
          _messages.last = ChatMessage(
            text: _currentStreamMessage,
            isUser: false,
            isComplete: false,
          );
        });
        _scrollToBottom();
      },
      onDone: () {
        // 流结束，标记消息为完成
        setState(() {
          _isReceivingStream = false;
          if (_messages.isNotEmpty) {
            _messages.last = ChatMessage(
              text: _currentStreamMessage,
              isUser: false,
              isComplete: true,
            );
          }
        });
        _streamSubscription = null;
      },
      onError: (error) {
        // 处理错误
        setState(() {
          _isReceivingStream = false;
          _messages.add(
            ChatMessage(
              text: '出错了: $error',
              isUser: false,
              isComplete: true,
            ),
          );
        });
        _streamSubscription = null;
        _scrollToBottom();
      },
    );
  }

  // 停止生成
  void _stopGeneration() {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    geminiService.cancelRequest();
    _cancelStreamSubscription();

    // 标记当前消息为完成状态
    setState(() {
      _isReceivingStream = false;
      if (_messages.isNotEmpty && !_messages.last.isComplete) {
        _messages.last = ChatMessage(
          text: _currentStreamMessage + ' [已停止生成]',
          isUser: false,
          isComplete: true,
        );
      }
    });
  }

  // 滚动到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 助手'),
        elevation: 1,
        actions: [
          if (_isReceivingStream)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: '停止生成',
              onPressed: _stopGeneration,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空聊天',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('清空聊天记录'),
                  content: const Text('确定要清空所有聊天记录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _messages.clear();
                          _messages.add(
                            ChatMessage(
                              text: '你好！我是AI助手，有什么我可以帮助你的吗？',
                              isUser: false,
                            ),
                          );
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, theme);
              },
            ),
          ),

          // 输入区域
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Consumer<GeminiService>(
              builder: (context, geminiService, child) {
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: geminiService.error != null
                              ? '连接错误，请重试'
                              : '输入消息...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                        ),
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_isReceivingStream && !geminiService.isLoading,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    _buildSendButton(geminiService),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 构建发送按钮
  Widget _buildSendButton(GeminiService geminiService) {
    if (_isReceivingStream || geminiService.isLoading) {
      return IconButton(
        icon: const CircularProgressIndicator(),
        onPressed: _stopGeneration,
        tooltip: '停止生成',
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.send),
        onPressed: geminiService.error != null
            ? () {
          // 如果有错误，尝试清除错误并重新初始化
          geminiService.clearError();
          geminiService.initialize();
        }
            : _sendMessage,
        color: Theme.of(context).primaryColor,
      );
    }
  }

  // 构建消息气泡
  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser, theme),

          const SizedBox(width: 8.0),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.primaryColor
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(18.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (!message.isComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isUser ? Colors.white70 : theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '思考中...',
                            style: TextStyle(
                              fontSize: 12,
                              color: isUser
                                  ? Colors.white70
                                  : theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8.0),

          if (isUser) _buildAvatar(isUser, theme),
        ],
      ),
    );
  }

  // 构建头像
  Widget _buildAvatar(bool isUser, ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser
          ? theme.primaryColor.withOpacity(0.2)
          : theme.primaryColor.withOpacity(0.1),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: isUser
            ? theme.primaryColor
            : theme.primaryColor,
      ),
    );
  }
}