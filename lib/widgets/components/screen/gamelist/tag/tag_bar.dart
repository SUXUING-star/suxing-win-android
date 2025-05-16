// lib/widgets/components/screen/gamelist/tag/tag_bar.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import '../../../../../models/tag/tag.dart';

class TagBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Tag> tags;
  final String? selectedTag;
  final Function(String) onTagSelected;

  const TagBar({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Size get preferredSize => Size.fromHeight(48.0);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Opacity(
        opacity: 0.7, // 透明度调整为0.7
        child: Container(
          height: 48.0,
          color: Colors.white,
          child: Column(
            children: [
              // 顶部蓝色条
              Container(
                height: 2,
                color: Colors.blue,
              ),

              // 标签列表
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    final isSelected = selectedTag == tag.name;

                    return Container(
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.blue.withSafeOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => onTagSelected(tag.name),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tag.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withSafeOpacity(0.3) : Colors.blue.withSafeOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${tag.count}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}