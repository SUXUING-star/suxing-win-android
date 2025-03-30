// lib/widgets/components/screen/forum/card/post_grid_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../../models/post/post.dart';
import 'post_card.dart';

class PostGridView extends StatelessWidget {
  final List<Post> posts;
  final ScrollController? scrollController;
  final bool isLoading;
  final bool hasMoreData;
  final VoidCallback? onLoadMore;
  final bool isDesktopLayout;

  const PostGridView({
    Key? key,
    required this.posts,
    this.scrollController,
    this.isLoading = false,
    this.hasMoreData = false,
    this.onLoadMore,
    this.isDesktopLayout = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      controller: scrollController,
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      itemCount: posts.length + (isLoading && hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < posts.length) {
          final post = posts[index];
          return PostCard(
            post: post,
            isDesktopLayout: isDesktopLayout,
            onDeleted: () {},  // Optional: Pass a deletion callback if needed
          );
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }
      },
    );
  }
}