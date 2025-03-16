// lib/widgets/components/screen/gamelist/panel/game_left_panel.dart
import 'package:flutter/material.dart';
import '../../../../../models/tag/tag.dart';
import '../../../../../utils/device/device_utils.dart';
import '../tag/tag_cloud.dart';

class GameLeftPanel extends StatelessWidget {
  final List<Tag> tags;
  final String? selectedTag;
  final Function(String) onTagSelected;

  const GameLeftPanel({
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
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTagCloudPanel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTagCloudPanel(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '标签云',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (selectedTag != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () => onTagSelected(selectedTag!),
                    tooltip: '清除筛选',
                    constraints: BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            SizedBox(height: 16),
            tags.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('没有可用的标签'),
              ),
            )
                : TagCloud(
              tags: tags,
              selectedTag: selectedTag,
              onTagSelected: onTagSelected,
              compact: DeviceUtils.getSidePanelWidth(context) < 220, // 使用紧凑模式当面板宽度较小时
            ),
          ],
        ),
      ),
    );
  }
}