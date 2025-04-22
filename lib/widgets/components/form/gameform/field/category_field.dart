import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/components/form/gameform/config/category_list.dart';

class CategoryField extends StatelessWidget {
  static const List<String> categoryOptions = CategoryList.defaultCategory;

  // 将 selectedCategories 改为 selectedCategory，类型改为 String?
  final String? selectedCategory;
  // 将 onChanged 的类型改为 ValueChanged<String?>
  final ValueChanged<String?> onChanged;

  const CategoryField({
    super.key,
    required this.selectedCategory, // 更新构造函数参数名
    required this.onChanged,         // 更新构造函数参数类型
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('游戏分类'), // 推荐加上 const
        Wrap(
          spacing: 8.0, // 可以加点间距让 Wrap 更好看
          runSpacing: 4.0,
          children: categoryOptions.map((category) {
            // 判断当前 chip 是否是选中的 chip
            final bool isSelected = selectedCategory == category;

            return FilterChip(
              label: Text(category),
              // 根据 isSelected 设置 selected 状态
              selected: isSelected,
              onSelected: (bool selected) {
                // 当用户点击一个 chip 时：
                // 1. 如果这个 chip 被选中 (selected == true)：
                //    那么调用 onChanged，传递当前的 category 作为新的选中项。
                // 2. 如果这个 chip 被取消选中 (selected == false)：
                //    这意味着用户点击了*已经选中*的 chip，我们希望取消选择，
                //    所以调用 onChanged，传递 null。
                onChanged(selected ? category : null);
              },
              // 视觉优化：可以改变选中时的样式
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }
}