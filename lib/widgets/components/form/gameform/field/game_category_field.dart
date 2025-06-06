// lib/widgets/components/form/gameform/field/game_category_field.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';

class GameCategoryField extends StatelessWidget {
  static const List<String> categoryOptions = GameConstants.defaultGameCategory;

  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const GameCategoryField({
    super.key,
    required this.selectedCategory, // 更新构造函数参数名
    required this.onChanged, // 更新构造函数参数类型
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
                onChanged(selected ? category : null);
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }
}
