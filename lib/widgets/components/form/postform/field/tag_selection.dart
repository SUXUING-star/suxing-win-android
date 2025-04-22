import 'package:flutter/material.dart';
import '../../../../../../utils/font/font_config.dart';

class TagSelection extends StatelessWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final Function(String tag, bool selected) onTagSelected;

  const TagSelection({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '标签 (最多选择3个)',
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(
                tag,
                style: TextStyle(
                  fontFamily: FontConfig.defaultFontFamily,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.blue.withOpacity(0.25),
              checkmarkColor: Colors.blue,
              backgroundColor: Colors.grey.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.transparent,
                ),
              ),
              onSelected: (selected) {
                onTagSelected(tag, selected);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}