// widgets/form/gameform/category_field.dart

import 'package:flutter/material.dart';

class CategoryField extends StatelessWidget {
  static const List<String> categoryOptions = ['汉化', '生肉'];

  final List<String> selectedCategories;
  final ValueChanged<List<String>> onChanged;

  const CategoryField({
    Key? key,
    required this.selectedCategories,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('游戏分类'),
        Wrap(
          children: categoryOptions.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(category),
                selected: selectedCategories.contains(category),
                onSelected: (bool selected) {
                  final newCategories = List<String>.from(selectedCategories);
                  if (selected) {
                    newCategories.add(category);
                  } else {
                    newCategories.remove(category);
                  }
                  onChanged(newCategories);
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}