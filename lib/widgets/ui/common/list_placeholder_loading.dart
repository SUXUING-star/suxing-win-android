import 'package:flutter/material.dart';
import 'skeleton_loading.dart';
// 列表占位加载组件
class ListPlaceholderLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;
  final bool hasImage;
  final bool hasTitle;
  final bool hasSubtitle;
  final double spacing;

  const ListPlaceholderLoading({
    Key? key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.hasImage = true,
    this.hasTitle = true,
    this.hasSubtitle = true,
    this.spacing = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : spacing),
        child: _buildListItem(context),
      ),
    );
  }

  Widget _buildListItem(BuildContext context) {
    return Container(
      height: itemHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          if (hasImage) ...[
            SkeletonLoading(
              width: itemHeight - 16,
              height: itemHeight - 16,
              borderRadius: 8,
            ),
            SizedBox(width: spacing),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasTitle) ...[
                  SkeletonLoading(
                    width: 200,
                    height: 16,
                    borderRadius: 4,
                  ),
                  SizedBox(height: spacing),
                ],
                if (hasSubtitle) ...[
                  SkeletonLoading(
                    width: 150,
                    height: 12,
                    borderRadius: 4,
                  ),
                  SizedBox(height: spacing / 2),
                  SkeletonLoading(
                    width: 100,
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}