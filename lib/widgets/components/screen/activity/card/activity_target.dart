// lib/widgets/components/screen/activity/card/activity_target.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
// Import the SafeCachedImage widget
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';

class ActivityTarget extends StatelessWidget {
  final Map<String, dynamic>? target;
  final String? targetType;
  final bool isAlternate;
  final double cardHeight;

  const ActivityTarget({
    Key? key,
    required this.target,
    required this.targetType,
    this.isAlternate = false,
    this.cardHeight = 1.0, // Default to 1.0 if not provided elsewhere
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (target == null) {
      return const SizedBox.shrink();
    }

    Widget targetWidget;

    switch (targetType) {
      case 'game':
        targetWidget = _buildGameTarget(context); // Pass context for devicePixelRatio
        break;
      case 'post':
        targetWidget = _buildPostTarget(context);
        break;
      case 'user':
        targetWidget = _buildUserTarget(context); // Pass context for devicePixelRatio
        break;
      default:
        targetWidget = const SizedBox.shrink();
    }

    return targetWidget;
  }

  // Helper to calculate cache size based on display size and pixel ratio
  int _calculateCacheSize(BuildContext context, double displaySize) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return (displaySize * devicePixelRatio).round();
  }

  Widget _buildGameTarget(BuildContext context) {
    final title = target?['title'] ?? '未知游戏';
    final coverImage = target?['coverImage'];
    final double imageSize = 60 * cardHeight;
    final double borderRadiusValue = 4 * math.sqrt(cardHeight);
    final int cacheSize = _calculateCacheSize(context, imageSize);

    return Container(
      padding: EdgeInsets.all(12 * cardHeight),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // Use SafeCachedImage for the game cover
          coverImage != null
              ? SafeCachedImage(
            imageUrl: coverImage,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(borderRadiusValue),
            memCacheWidth: cacheSize,
            memCacheHeight: cacheSize,
            // Optional: Add specific background if needed for placeholder/error
            // backgroundColor: Colors.grey.shade300,
          )
              : _buildPlaceholderImage('game'), // Fallback if no cover image URL
          SizedBox(width: 12 * cardHeight),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16 * math.sqrt(cardHeight),
              ),
              textAlign: isAlternate ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTarget(BuildContext context) {
    final title = target?['title'] ?? '未知帖子';

    return Container(
      padding: EdgeInsets.all(12 * cardHeight),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Icon(Icons.article, color: Colors.blue.shade700, size: 24 * math.sqrt(cardHeight)),
          SizedBox(width: 12 * cardHeight),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16 * math.sqrt(cardHeight),
                color: Colors.blue.shade900,
              ),
              textAlign: isAlternate ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTarget(BuildContext context) {
    final username = target?['username'] ?? '未知用户';
    final avatar = target?['avatar'];
    final double avatarDiameter = 40 * math.sqrt(cardHeight); // Diameter = radius * 2
    final double avatarRadius = avatarDiameter / 2;
    final int cacheSize = _calculateCacheSize(context, avatarDiameter);

    return Container(
      padding: EdgeInsets.all(12 * cardHeight),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8 * math.sqrt(cardHeight)),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // Use SafeCachedImage for the user avatar
          avatar != null
              ? SafeCachedImage(
            imageUrl: avatar,
            width: avatarDiameter,
            height: avatarDiameter,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(avatarRadius), // Make it circular
            memCacheWidth: cacheSize,
            memCacheHeight: cacheSize,
            // Optional: Background for placeholder/error
            // backgroundColor: Colors.purple.shade100,
          )
              : _buildFallbackAvatar(username, avatarDiameter), // Fallback if no avatar URL
          SizedBox(width: 12 * cardHeight),
          Expanded(
            child: Text(
              username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16 * math.sqrt(cardHeight),
                color: Colors.purple.shade900,
              ),
              textAlign: isAlternate ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  // Fallback for User avatar (when URL is null)
  Widget _buildFallbackAvatar(String username, double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: Colors.purple.shade200, // Use a slightly darker shade maybe
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (username.isNotEmpty) ? username[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: diameter * 0.4, // Adjust font size relative to avatar size
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }


  // Placeholder for Game image (when URL is null)
  // This remains needed for the case where coverImage URL itself is null
  Widget _buildPlaceholderImage(String type) {
    final double size = 60 * cardHeight;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4 * math.sqrt(cardHeight)),
      ),
      child: Icon(
        type == 'game' ? Icons.gamepad_outlined : Icons.image_not_supported_outlined,
        size: 24 * math.sqrt(cardHeight),
        color: Colors.grey.shade600,
      ),
    );
  }
}