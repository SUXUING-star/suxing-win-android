// lib/widgets/components/screen/activity/activity_target.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

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
    this.cardHeight = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (target == null) {
      return const SizedBox.shrink();
    }

    Widget targetWidget;

    switch (targetType) {
      case 'game':
        targetWidget = _buildGameTarget();
        break;
      case 'post':
        targetWidget = _buildPostTarget();
        break;
      case 'user':
        targetWidget = _buildUserTarget();
        break;
      default:
        targetWidget = const SizedBox.shrink();
    }

    return targetWidget;
  }

  Widget _buildGameTarget() {
    final title = target?['title'] ?? '未知游戏';
    final coverImage = target?['coverImage'];

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
          _buildTargetImage(coverImage, 'game'),
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

  Widget _buildPostTarget() {
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

  Widget _buildUserTarget() {
    final username = target?['username'] ?? '未知用户';
    final avatar = target?['avatar'];

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
          CircleAvatar(
            radius: 20 * math.sqrt(cardHeight),
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null ? Text(username[0].toUpperCase()) : null,
          ),
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

  Widget _buildTargetImage(String? coverImage, String type) {
    if (coverImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4 * math.sqrt(cardHeight)),
        child: Image.network(
          coverImage,
          width: 60 * cardHeight,
          height: 60 * cardHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(type),
        ),
      );
    } else {
      return _buildPlaceholderImage(type);
    }
  }

  Widget _buildPlaceholderImage(String type) {
    return Container(
      width: 60 * cardHeight,
      height: 60 * cardHeight,
      color: Colors.grey.shade300,
      child: Icon(
        type == 'game' ? Icons.gamepad : Icons.image_not_supported,
        size: 24 * math.sqrt(cardHeight),
      ),
    );
  }
}