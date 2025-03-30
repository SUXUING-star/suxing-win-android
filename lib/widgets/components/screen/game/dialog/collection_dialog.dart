// lib/widgets/components/screen/game/dialog/collection_dialog.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/game/game_collection.dart';
import '../../../../../widgets/components/form/collection/collection_form.dart';

class CollectionDialog extends StatelessWidget {
  final String gameId;
  final String gameName;
  final String? currentStatus;
  final String? currentNotes;
  final String? currentReview;  // Add this field
  final double? currentRating;

  const CollectionDialog({
    Key? key,
    required this.gameId,
    required this.gameName,
    this.currentStatus,
    this.currentNotes,
    this.currentReview,  // Add this parameter
    this.currentRating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEditing = currentStatus != null && currentStatus!.isNotEmpty;
    final title = isEditing ? '编辑收藏' : '添加收藏';
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80.0 : 20.0,
        vertical: 24.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 600 : 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, title),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        gameName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    CollectionForm(
                      gameId: gameId,
                      initialStatus: currentStatus ?? '',
                      initialNotes: currentNotes,
                      initialReview: currentReview,  // Pass the review field
                      initialRating: currentRating,
                      showRemoveButton: isEditing,
                      onCancel: () => NavigationUtils.of(context).pop(),
                      onRemove: () {
                        NavigationUtils.of(context).pop({
                          'action': 'remove',
                        });
                      },
                      onSubmit: (status, notes, review, rating) {  // Make sure this function accepts review
                        NavigationUtils.of(context).pop({
                          'action': 'set',
                          'status': status,
                          'notes': notes,
                          'review': review,  // Include review in result
                          'rating': rating,
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}