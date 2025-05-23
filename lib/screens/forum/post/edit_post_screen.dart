// lib/screens/forum/edit_post_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/post/post_constants.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/form/postform/field/post_guidelines.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import '../../../models/post/post.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../widgets/components/form/postform/post_form.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final ForumService forumService;
  final AuthProvider authProvider;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.forumService,
    required this.authProvider,
  });

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen>
    with SnackBarNotifierMixin {
  final List<PostTag> _availablePostTags = PostConstants.availablePostTags;
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _hasInitializedDependencies = false;
  Post? _post;
  late final ForumService _forumService;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _forumService = widget.forumService;
      _authProvider = widget.authProvider;
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _loadPostData();
    }
  }

  Future<void> _loadPostData() async {
    try {
      setState(() => _isLoading = true);

      final post = await _forumService.getPost(widget.postId);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      showSnackbar(
          message: '加载帖子数据失败: ${e.toString()}', type: SnackbarType.error);
    }
  }

  Future<void> _submitEdit(PostFormData data) async {
    try {
      setState(() => _isSubmitting = true);
      final postTags = PostTagsUtils.tagsToStringList(data.tags);
      await _forumService.updatePost(
          _post!, data.title, data.content, postTags);
      showSnackbar(message: "编辑成功", type: SnackbarType.success);
      if (!mounted) return;
      NavigationUtils.pop(context, true);
    } catch (e) {
      showSnackbar(message: '编辑失败: ${e.toString()}', type: SnackbarType.error);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);
    if (_isLoading) {
      return LoadingWidget.fullScreen(message: "正在加载数据");
    }

    if (_post == null) {
      // 保持这个检查
      return const CustomErrorWidget(title: '无法加载帖子数据');
    }

    // 安全地处理 postIdInfo
    String displayPostId = "无效ID"; // 默认值
    if (_post!.id.isNotEmpty) {
      // 增加非空和非空字符串检查
      displayPostId = _post!.id.length >= 8
          ? '${_post!.id.substring(0, 8)}...'
          : _post!.id; // 如果 ID 不足8位，显示完整 ID
    }

    // 安全地处理 updatetimeInfo (虽然不太可能出错，但也加上)
    String displayUpdateTime = "未知时间";
    try {
      // 使用 try-catch 更保险，因为 toString() 和 substring() 都可能意外出错
      displayUpdateTime = _post!.updateTime.toString().length >= 16
          ? _post!.updateTime.toString().substring(0, 16)
          : _post!.updateTime.toString();
    } catch (e) {
      //print("Error formatting updateTime: $e");
      // 保留默认值 "未知时间"
    }

    return StreamBuilder<User?>(
      stream: _authProvider.currentUserStream,
      initialData: _authProvider.currentUser,
      builder: (context, currentUserSnapshot) {
        final User? currentUser = currentUserSnapshot.data;
        final String? currentUserId = currentUser?.id;
        final bool isAdmin = currentUser?.isAdmin ?? false;
        if (currentUser == null) {
          return const LoginPromptWidget();
        }
        final canEdit = isAdmin ? true : currentUserId == _post?.authorId;
        if (!canEdit) {
          return CustomErrorWidget(
            errorMessage: "你没有权限编辑",
            title: "错误",
            retryText: "返回上一页",
            onRetry: () => NavigationUtils.pop(context),
          );
        }

        return PostForm(
          title: '编辑帖子',
          currentUser: _authProvider.currentUser,
          initialTitle: _post!.title,
          initialContent: _post!.content,
          initialTags: List.from(_post!.tags),
          availableTags: _availablePostTags,
          isSubmitting: _isSubmitting,
          onSubmit: _submitEdit,
          submitButtonText: '保存修改',
          postIdInfo: displayPostId,
          updatetimeInfo: displayUpdateTime,
          additionalInfo: PostGuidelines(
            guidelines: PostConstants.postGuideRules,
          ),
        );
      },
    );
  }
}
