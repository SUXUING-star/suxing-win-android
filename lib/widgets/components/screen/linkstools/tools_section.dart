// lib/widgets/components/screen/linkstools/tools_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/linkstools/tool.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_sliver_list.dart';
import 'tool_list_item.dart';

class ToolsSection extends StatelessWidget {
  final List<Tool> tools;
  final bool isAdmin;

  const ToolsSection({
    super.key,
    required this.tools,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: AnimatedSliverList<Tool>(
        items: tools,
        itemBuilder: (context, index, tool) {
          // 不需要再传递 onLaunchURL
          return ToolListItem(
            tool: tool,
          );
        },
      ),
    );
  }
}