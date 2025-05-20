// lib/screens/forum/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/post/post_constants.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../widgets/components/form/postform/post_form.dart';
import '../../../widgets/components/form/postform/field/post_guidelines.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SnackBarNotifierMixin {
  final List<PostTag> _availableTags = PostConstants.availablePostTags;
  bool _isSubmitting = false;
  bool _hasInitializedDependencies = false;
  late final ForumService _forumService;
  late final AuthProvider _authProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _forumService = context.read<ForumService>();
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _hasInitializedDependencies = true;
    }
  }

  Future<void> _submitPost(PostFormData data) async {
    try {
      setState(() => _isSubmitting = true);
      final postTags = PostTagsUtils.tagsToStringList(data.tags);
      await _forumService.createPost(data.title, data.content, postTags);
      showSnackbar(message: "编辑成功", type: SnackbarType.success);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      showSnackbar(message: '编辑失败: ${e.toString()}', type: SnackbarType.error);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);
    if (_authProvider.currentUserId == null || !_authProvider.isLoggedIn) {
      return const LoginPromptWidget();
    }

    return PostForm(
      title: '发布帖子',
      currentUser: _authProvider.currentUser,
      availableTags: _availableTags,
      isSubmitting: _isSubmitting,
      onSubmit: _submitPost,
      submitButtonText: '发布帖子',
      additionalInfo: PostGuidelines(
        guidelines: PostConstants.postGuideRules,
      ),
    );
  }
}
