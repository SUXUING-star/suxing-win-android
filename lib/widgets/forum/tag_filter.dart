// lib/widgets/forum/tag_filter.dart
import 'package:flutter/material.dart';
import '../../utils/font_config.dart';

class TagFilter extends StatelessWidget {
  final List<String> tags;
  final String selectedTag;
  final ValueChanged<String> onTagSelected;

  const TagFilter({
    Key? key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = tag == selectedTag;
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tag,
                  style: TextStyle(
                      fontFamily: FontConfig.defaultFontFamily,
                      fontFamilyFallback: FontConfig.fontFallback)
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onTagSelected(tag);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
