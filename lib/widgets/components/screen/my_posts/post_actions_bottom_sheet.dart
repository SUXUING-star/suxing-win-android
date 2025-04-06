// lib/widgets/my_posts/post_actions_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../models/post/post.dart';
import '../../../../routes/app_routes.dart';
import '../../../../screens/profile/myposts/blocs/my_posts_bloc.dart';
import '../../../../screens/profile/myposts/blocs/my_posts_event.dart';


class PostActionsBottomSheet extends StatelessWidget {
  final Post post;

  const PostActionsBottomSheet({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('编辑'),
            onTap: () {
              NavigationUtils.pop(context); // 关闭 BottomSheet
              NavigationUtils.pushNamed(
                context,
                AppRoutes.editPost,
                arguments: post,
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('删除', style: TextStyle(color: Colors.red)),
            onTap: () {
              // 先关闭 BottomSheet
              NavigationUtils.pop(context);
              // 然后显示自定义确认对话框
              _showDeleteConfirmDialog(context, post); // <-- 2. 修改点：传递 post 对象
            },
          ),
        ],
      ),
    );
  }

  // 3. 修改方法签名，接收 Post 对象
  void _showDeleteConfirmDialog(BuildContext context, Post postToDelete) {
    CustomConfirmDialog.show(
      context: context,
      title: '删除帖子',
      // 标题
      message: '确定要删除这个帖子吗？此操作不可恢复。',
      // 消息
      confirmButtonText: '删除',
      // 确认按钮文字
      confirmButtonColor: Colors.red,
      // 确认按钮颜色（匹配危险操作）
      iconData: Icons.warning_amber_rounded,
      // 使用警告图标
      iconColor: Colors.orange,
      // 核心逻辑：确认回调
      onConfirm: () async {
        try {
          context.read<MyPostsBloc>().add(DeletePostEvent(postToDelete.id));
          AppSnackBar.showSuccess(context, '帖子已删除');
        } catch (e) {
          print("删除帖子时发生错误: $e");
          AppSnackBar.showError(context, '删除失败: $e');
        }
        // 不需要在这里手动调用 NavigationUtils.pop(context);
      },
    );
  }
}