// lib/widgets/linkstools/tools_section.dart
import 'package:flutter/material.dart';
import '../../models/linkstools/tool.dart';

class ToolsSection extends StatelessWidget {
  final List<Tool> tools;
  final bool isAdmin;
  final Function(String) onLaunchURL;

  const ToolsSection({
    Key? key,
    required this.tools,
    required this.isAdmin,
    required this.onLaunchURL,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final tool = tools[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    childrenPadding: EdgeInsets.all(16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(
                            int.parse(tool.color.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.build, color: Colors.white, size: 24),
                    ),
                    title: Text(
                      tool.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        tool.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    children: [
                      if (tool.downloads.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: tool.downloads.map((download) =>
                              Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8),
                                  title: Text(
                                    download.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    download.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.download,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => onLaunchURL(download.url),
                                  ),
                                ),
                              ),
                          ).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: tools.length,
        ),
      ),
    );
  }
}