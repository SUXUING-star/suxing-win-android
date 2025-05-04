// lib/screens/forum/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/post/post_constants.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../widgets/components/form/postform/post_form.dart';
import '../../../widgets/components/form/postform/field/post_guidelines.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final List<PostTag> _availableTags = PostConstants.availablePostTags;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return PostForm(
      title: '发布帖子',
      availableTags: _availableTags,
      isSubmitting: _isSubmitting,
      onSubmit: _submitPost,
      submitButtonText: '发布帖子',
      additionalInfo: PostGuidelines(
        guidelines: PostConstants.postGuideRules,
      ),
    );
  }

  Future<void> _submitPost(PostFormData data) async {
    try {
      setState(() => _isSubmitting = true);
      final postTags = PostTagsUtils.tagsToStringList(data.tags);
      final forumService = context.read<ForumService>();
      await forumService.createPost(data.title, data.content, postTags);
      AppSnackBar.showSuccess(context, "编辑成功");
      Navigator.pop(context);
    } catch (e) {
      AppSnackBar.showError(context, '编辑失败: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
