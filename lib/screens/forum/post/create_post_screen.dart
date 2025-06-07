// lib/screens/forum/post/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/post/post_constants.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/widgets/components/form/postform/post_form.dart';
import 'package:suxingchahui/widgets/components/form/postform/field/post_guidelines.dart';

class CreatePostScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final PostService postService;
  final InputStateService inputStateService;
  const CreatePostScreen({
    super.key,
    required this.authProvider,
    required this.postService,
    required this.inputStateService,
  });

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SnackBarNotifierMixin {
  final List<PostTag> _availableTags = PostConstants.availablePostTags;
  bool _isSubmitting = false;
  bool _hasInitializedDependencies = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
  }

  Future<void> _submitPost(PostFormData data) async {
    try {
      setState(() => _isSubmitting = true);
      final postTags = PostTagsUtils.tagsToStringList(data.tags);
      await widget.postService.createPost(data.title, data.content, postTags);
      showSnackBar(message: "编辑成功", type: SnackBarType.success);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(message: '编辑失败: ${e.toString()}', type: SnackBarType.error);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);

    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, currentUserSnapshot) {
        final User? currentUser = currentUserSnapshot.data;
        if (currentUser == null) {
          return const LoginPromptWidget();
        }
        return PostForm(
          title: '发布帖子',
          currentUser: currentUser,
          inputStateService: widget.inputStateService,
          availableTags: _availableTags,
          isSubmitting: _isSubmitting,
          onSubmit: _submitPost,
          submitButtonText: '发布帖子',
          additionalInfo: PostGuidelines(
            guidelines: PostConstants.postGuideRules,
          ),
        );
      },
    );
  }
}
