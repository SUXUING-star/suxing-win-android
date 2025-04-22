// lib/widgets/ui/inputs/post_reply_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import '../../../models/post/post.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../utils/font/font_config.dart';
import '../buttons/login_prompt.dart';
import 'text_input_field.dart'; // <--- 导入咱们牛逼的组件

class PostReplyInput extends StatefulWidget {
  final Post? post;
  final TextEditingController? controller;
  // !!! 注意：因为 TextInputField 的 onSubmitted 不带 context，
  // !!! 我们必须保留外部按钮来调用这个带 context 的回调 !!!
  final Function(BuildContext context, String text)? onSubmitReply; // 修改签名，传递文本
  final String hintText;
  final String submitButtonText;
  final bool isSubmitting;
  final int maxLines;
  final bool isDesktopLayout;
  final VoidCallback? onLoginRequired;
  final Widget? loginPrompt;

  const PostReplyInput({
    super.key,
    this.post,
    this.controller,
    this.onSubmitReply,
    this.hintText = '写下你的回复...',
    this.submitButtonText = '发送回复',
    this.isSubmitting = false,
    this.maxLines = 4,
    this.isDesktopLayout = false,
    this.onLoginRequired,
    this.loginPrompt,
  });

  @override
  State<PostReplyInput> createState() => _PostReplyInputState();
}

class _PostReplyInputState extends State<PostReplyInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode; // 添加 FocusNode
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _isInternalController = widget.controller == null;
    _focusNode = FocusNode(); // 内部创建 FocusNode
    _isInternalFocusNode = true;
  }

  @override
  void dispose() {
    if (_isInternalFocusNode) {
      _focusNode.dispose(); // 释放内部创建的 FocusNode
    }
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  // 修改 _handleSubmit 以便传递文本
  void _handleSubmit(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSubmitting || widget.onSubmitReply == null)
      return;
    _focusNode.unfocus(); // unfocus
    widget.onSubmitReply!(context, text); // 调用回调，传入 context 和 text
    // 清空逻辑可以放在这里
    // _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // --- 登录逻辑保持不变 ---
        if (!auth.isLoggedIn) {
          if (widget.loginPrompt != null) {
            return widget.loginPrompt!;
          }
          return _buildLoginPrompt(context); // _buildLoginPrompt 方法保持不变
        }

        // --- 根据布局类型显示不同的输入框 ---
        return widget.isDesktopLayout
            ? _buildDesktopInput(context)
            : _buildMobileInput(context);
      },
    );
  }

  // --- _buildLoginPrompt 保持不变 ---
  Widget _buildLoginPrompt(BuildContext context) {
    // ... (原代码不变) ...
    if (widget.isDesktopLayout) {
      return Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '参与讨论',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              LoginPrompt(
                message: '登录后参与讨论',
                buttonText: '登录',
                onLoginPressed: widget.onLoginRequired ??
                    () => NavigationUtils.pushNamed(context, '/login'),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                opacity: 1.0,
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        child: LoginPrompt(
          message: '登录后参与讨论',
          buttonText: '登录',
          onLoginPressed: widget.onLoginRequired ??
              () => NavigationUtils.pushNamed(context, '/login'),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          opacity: 1.0,
          borderRadius: BorderRadius.zero,
        ),
      );
    }
  }

  Widget _buildDesktopInput(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '写下你的回复',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // --- 使用 TextInputField ---
            TextInputField(
              controller: _controller,
              focusNode: _focusNode,
              hintText: widget.hintText,
              maxLines: widget.maxLines,
              enabled: !widget.isSubmitting,
              // 调整 contentPadding 和 decoration 以匹配 Card 风格
              contentPadding: const EdgeInsets.all(16),
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  // 确保与 focusedBorder 匹配
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                      color: Theme.of(context).primaryColor), // 保持焦点颜色
                ),
              ),
              // !!! 关键：不显示按钮，不需要padding，不处理回车 !!!
              showSubmitButton: false,
              padding: EdgeInsets.zero,
              handleEnterKey: false,
            ),
            const SizedBox(height: 16),
            // --- 按钮逻辑保持不变 ---
            Align(
              alignment: Alignment.centerRight,
              child: widget.isSubmitting
                  ? Container(
                      margin: const EdgeInsets.only(right: 16), // 调整边距使加载圈在按钮位置
                      width: 36, // 按钮大概宽度
                      height: 36, // 按钮大概高度
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : FunctionalButton(
                      icon: Icons.send,
                      // 确保禁用状态下不可点击
                      onPressed: widget.isSubmitting
                          ? () => {}
                          : () => _handleSubmit(context), // 调用这里的 handleSubmit
                      label: "发送回复",
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileInput(BuildContext context) {
    // SafeArea 和 外层 Container/Padding 保持不变
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, // 保持底部对齐
            children: [
              // --- 使用 TextInputField ---
              Expanded(
                child: TextInputField(
                  controller: _controller,
                  focusNode: _focusNode,
                  hintText: widget.hintText,
                  // Mobile 端 maxLines 可能小一点，比如 4 或 5
                  maxLines: 4, // 可以根据需要调整
                  enabled: !widget.isSubmitting,
                  // Mobile 端通常用无边框样式
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10), // 微调垂直内边距
                  ),
                  // !!! 关键：不显示按钮，不需要padding，不处理回车 !!!
                  showSubmitButton: false,
                  padding: EdgeInsets.zero,
                  handleEnterKey: false,
                ),
              ),
              SizedBox(width: 8),
              // --- 按钮逻辑保持不变 ---
              widget.isSubmitting
                  ? Container(
                      // 为了和 IconButton 对齐，可以给个固定大小
                      width: 48, // IconButton 默认点击区域大小
                      height: 48,
                      padding: const EdgeInsets.all(12), // 让加载圈小一点居中
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FunctionalButton(
                      icon: Icons.send,
                      // 确保禁用状态下不可点击
                      onPressed: widget.isSubmitting
                          ? () => {}
                          : () => _handleSubmit(context), // 调用这里的 handleSubmit
                      label: "发送回复",
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
