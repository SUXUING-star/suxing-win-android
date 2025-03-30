// lib/widgets/ui/inputs/post_reply_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../models/post/post.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../utils/font/font_config.dart';
import '../../../utils/device/device_utils.dart';
import '../buttons/login_prompt.dart';

class PostReplyInput extends StatefulWidget {
  final Post? post;
  final TextEditingController? controller;
  final Function(BuildContext)? onSubmitReply;
  final String hintText;
  final String submitButtonText;
  final bool isSubmitting;
  final int maxLines;
  final bool isDesktopLayout;
  final VoidCallback? onLoginRequired;
  final Widget? loginPrompt;

  const PostReplyInput({
    Key? key,
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
  }) : super(key: key);

  @override
  State<PostReplyInput> createState() => _PostReplyInputState();
}

class _PostReplyInputState extends State<PostReplyInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleSubmit(BuildContext context) {
    if (widget.onSubmitReply != null) {
      widget.onSubmitReply!(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // 如果用户未登录，显示登录提示
        if (!auth.isLoggedIn) {
          if (widget.loginPrompt != null) {
            return widget.loginPrompt!;
          }

          return _buildLoginPrompt(context);
        }

        // 如果帖子已锁定，显示锁定提示
        if (widget.post?.status == PostStatus.locked) {
          return _buildLockedPrompt();
        }

        // 根据布局类型显示不同的输入框
        return widget.isDesktopLayout
            ? _buildDesktopInput(context)
            : _buildMobileInput(context);
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
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
                onLoginPressed: widget.onLoginRequired ?? () => NavigationUtils.pushNamed(context, '/login'),
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
          onLoginPressed: widget.onLoginRequired ?? () => NavigationUtils.pushNamed(context, '/login'),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          opacity: 1.0,
          borderRadius: BorderRadius.zero,
        ),
      );
    }
  }

  Widget _buildLockedPrompt() {
    if (widget.isDesktopLayout) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '帖子已锁定',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('该帖子已被锁定，无法回复'),
            ],
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[200],
        child: const Text('该帖子已被锁定，无法回复'),
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
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: widget.maxLines,
              minLines: 3,
              enabled: !widget.isSubmitting,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: widget.isSubmitting
                  ? Container(
                margin: const EdgeInsets.only(right: 16),
                width: 24,
                height: 24,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
                  : ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: Text(
                  widget.submitButtonText,
                  style: TextStyle(
                    fontFamily: FontConfig.defaultFontFamily,
                    fontFamilyFallback: FontConfig.fontFallback,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _handleSubmit(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileInput(BuildContext context) {
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
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                  ),
                  maxLines: 4,
                  minLines: 1,
                  enabled: !widget.isSubmitting,
                ),
              ),
              SizedBox(width: 8),
              widget.isSubmitting
                  ? Container(
                margin: const EdgeInsets.only(left: 8),
                width: 24,
                height: 24,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
                  : IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmit(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}