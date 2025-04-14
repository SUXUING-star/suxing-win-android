// lib/screens/forum/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../services/main/forum/forum_service.dart';
import '../../../widgets/components/form/postform/post_form.dart';
import '../../../widgets/components/form/postform/field/post_guidelines.dart';
import '../../../widgets/components/form/postform/config/post_taglists.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _forumService = ForumService();
  final List<String> _availableTags = PostTagLists.availableTags;
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
        guidelines: [
          '请确保帖子内容符合社区规范',
          '标题请简明扼要地概括主题',
          '请选择适当的标签以便其他用户查找',
          '发布后可在24小时内编辑内容',
        ],
      ),
    );
  }

  Future<void> _submitPost(PostFormData data) async {
    try {
      setState(() => _isSubmitting = true);
      await _forumService.createPost(data.title, data.content, data.tags);
      AppSnackBar.showSuccess(context, "编辑成功");
      Navigator.pop(context);
    } catch (e) {
      AppSnackBar.showError(context,'编辑失败: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}