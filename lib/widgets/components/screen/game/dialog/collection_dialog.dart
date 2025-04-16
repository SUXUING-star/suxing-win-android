import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/game/game_collection.dart';
import '../../../../../widgets/components/form/collection/collection_form.dart';

class CollectionDialog extends StatelessWidget {
  final String gameId;
  final String gameName;
  final String? currentStatus;
  final String? currentNotes;
  final String? currentReview; // Add this field
  final double? currentRating;

  const CollectionDialog({
    Key? key,
    required this.gameId,
    required this.gameName,
    this.currentStatus,
    this.currentNotes,
    this.currentReview, // Add this parameter
    this.currentRating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEditing = currentStatus != null && currentStatus!.isNotEmpty;
    final title = isEditing ? '编辑收藏' : '添加收藏';
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final theme = Theme.of(context); // 获取主题

    return Center(
      // 1. 使用 Center 包裹，让对话框居中
      child: ConstrainedBox(
        // 2. 使用 ConstrainedBox 限制对话框大小
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 600 : 400,
          // maxHeight: MediaQuery.of(context).size.height * 0.8, // 高度可以自适应内容，不需要限制最大高度
          minWidth: 280, //  添加最小宽度，和 CustomConfirmDialog 保持一致
        ),
        child: Material(
          // 3. 使用 Material 组件提供背景和阴影
          color: Colors.white, //  背景色白色
          elevation: 6.0, //  阴影大小
          shadowColor: Colors.black26, // 阴影颜色
          shape: RoundedRectangleBorder(
            // 4. 圆角边框
            borderRadius: BorderRadius.circular(12.0),
          ),
          clipBehavior: Clip.antiAlias,

          child: Padding(
            // 5. 使用 Padding  设置对话框内部边距
            padding: const EdgeInsets.fromLTRB(
                16.0, 18.0, 18.0, 16.0), //  和 CustomConfirmDialog 相同的边距
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, title), // 头部保持不变
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0), //  可以适当调整这里的内边距
                          child: Text(
                            gameName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        CollectionForm(
                          //  表单内容保持不变
                          gameId: gameId,
                          initialStatus: currentStatus ?? '',
                          initialNotes: currentNotes,
                          initialReview: currentReview, // Pass the review field
                          initialRating: currentRating,
                          showRemoveButton: isEditing,
                          onCancel: () => NavigationUtils.of(context).pop(),
                          onRemove: () {
                            NavigationUtils.of(context).pop({
                              'action': 'remove',
                            });
                          },
                          onSubmit: (status, notes, review, rating) {
                            // Make sure this function accepts review
                            NavigationUtils.of(context).pop({
                              'action': 'set',
                              'status': status,
                              'notes': notes,
                              'review': review, // Include review in result
                              'rating': rating,
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        //  可以考虑移除 BoxDecoration， 让 header 也融入 Material 的风格， 如果需要自定义 header 背景色， 可以在 Material 组件之外再包裹一层 Container
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
