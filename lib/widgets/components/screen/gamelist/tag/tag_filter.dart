// lib/widgets/components/screen/gamelist/tag/tag_filter.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import '../../../../../models/tag/tag.dart';
import '../../../../../utils/font/font_config.dart';

class TagFilter extends StatefulWidget {
  final List<Tag> tags;
  final String? selectedTag;
  final Function(String) onTagSelected;
  final VoidCallback onClearSelection;
  final bool isVisible;
  final VoidCallback onToggleVisibility;

  const TagFilter({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
    required this.onClearSelection,
    required this.isVisible,
    required this.onToggleVisibility,
  });

  @override
  _TagFilterState createState() => _TagFilterState();
}

class _TagFilterState extends State<TagFilter> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标签过滤器控制行
        _buildFilterControlRow(),

        // 标签列表 (仅在可见时显示)
        if (widget.isVisible && widget.tags.isNotEmpty)
          _buildTagList(),
      ],
    );
  }

  Widget _buildFilterControlRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 热门标签标题
          Text(
            '热门标签',
            style: TextStyle(
              fontFamily: FontConfig.defaultFontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
              color: Colors.white,
            ),
          ),

          // 过滤器控制按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 清除选择按钮 (仅在选中标签时显示)
              if (widget.selectedTag != null)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.white, size: 20.0),
                  onPressed: widget.onClearSelection,
                  tooltip: '清除筛选',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),

              // 显示/隐藏切换按钮
              IconButton(
                icon: Icon(
                  widget.isVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20.0,
                ),
                onPressed: widget.onToggleVisibility,
                tooltip: widget.isVisible ? '收起标签' : '展开标签',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagList() {
    return Container(
      height: 40.0,
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.tags.map((tag) {
            final isSelected = widget.selectedTag == tag.name;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(
                  '${tag.name} (${tag.count})',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: FontConfig.defaultFontFamily,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => widget.onTagSelected(tag.name),
                selectedColor: Theme.of(context).primaryColor,
                checkmarkColor: Colors.white,
                backgroundColor: Colors.white.withSafeOpacity(0.9),
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}