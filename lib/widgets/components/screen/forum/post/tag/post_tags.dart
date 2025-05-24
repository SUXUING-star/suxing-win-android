import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/widgets/ui/components/post/post_tag_item.dart';

class PostTags extends StatelessWidget {
  final Post post;
  final bool isMini;
  final double tagSpacing;
  final EdgeInsets? scrollPadding;
  final Function(BuildContext context, String tagString)? onTagTap;
  final String? selectedTagString;

  const PostTags({
    super.key,
    required this.post,
    required this.isMini,
    this.tagSpacing = 8.0,
    this.scrollPadding = const EdgeInsets.symmetric(vertical: 4.0),
    this.onTagTap,
    this.selectedTagString,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> tags = post.tags;

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> tagItemWidgets = [];
    for (int i = 0; i < tags.length; i++) {
      final String currentTagString = tags[i];
      tagItemWidgets.add(
        PostTagItem(
          key: ValueKey('post_tag_item_${post.id}_$currentTagString'),
          tagString: currentTagString,
          isMini: isMini,
          isSelected: selectedTagString == currentTagString,
          onTap: (onTagTap != null)
              ? (_) {
                  onTagTap!(context, currentTagString);
                }
              : null,
        ),
      );
      if (i < tags.length - 1) {
        tagItemWidgets.add(SizedBox(width: tagSpacing));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: scrollPadding,
      child: Row(
        children: tagItemWidgets,
      ),
    );
  }
}
