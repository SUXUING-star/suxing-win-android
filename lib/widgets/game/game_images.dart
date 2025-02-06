// lib/widgets/game/game_images.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../screens/game/image_preview_screen.dart';

class GameImages extends StatelessWidget {
  final Game game;

  const GameImages({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '游戏截图',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            itemCount: game.images.length,
            itemBuilder: (context, index) => _buildImageItem(context, index),
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(BuildContext context, int index) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _showImagePreview(context, index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            game.images[index],
            width: 250,
            height: 150,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(
          images: game.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}