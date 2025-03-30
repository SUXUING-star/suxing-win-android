// lib/widgets/components/screen/forum/panel/forum_left_panel.dart
import 'package:flutter/material.dart';
import '../../../../../utils/device/device_utils.dart';

class ForumLeftPanel extends StatelessWidget {
  final List<String> tags;
  final String selectedTag;
  final Function(String) onTagSelected;

  const ForumLeftPanel({
    Key? key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 使用自适应宽度
    final panelWidth = DeviceUtils.getSidePanelWidth(context);

    return Container(
      width: panelWidth,
      margin: EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.8, // 透明度调整为0.8
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.blue,
                  child: Row(
                    children: [
                      Icon(Icons.label, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '论坛分类',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      if (selectedTag != '全部')
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () => onTagSelected('全部'),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.close, size: 12, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        '清除',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // 标签区域
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(12),
                    child: _buildTagsGrid(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagsGrid(BuildContext context) {
    if (tags.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.label_off,
                size: 32,
                color: Colors.grey[400],
              ),
              SizedBox(height: 8),
              Text(
                '没有可用的标签',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 使用Grid布局代替Wrap，更加整齐
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = tag == selectedTag;

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () => onTagSelected(tag),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.blue,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}