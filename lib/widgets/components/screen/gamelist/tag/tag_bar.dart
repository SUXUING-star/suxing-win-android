// lib/widgets/components/tag_bar/tag_bar.dart
import 'package:flutter/material.dart';
import '../../../../../models/tag/tag.dart';

class TagBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Tag> tags;
  final String? selectedTag;
  final Function(String) onTagSelected;

  const TagBar({
    Key? key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(50.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = selectedTag == tag.name;

          return Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: isSelected ? Icon(Icons.check, size: 18, color: Colors.white) : null,
              label: Text(
                tag.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
              ),
              backgroundColor: isSelected
                  ? Colors.blue.shade700
                  : Colors.white.withOpacity(0.9),
              onPressed: () => onTagSelected(tag.name),
            ),
          );
        },
      ),
    );
  }
}