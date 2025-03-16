// lib/widgets/components/form/collection_form.dart
import 'package:flutter/material.dart';
import '../../../../models/game/game_collection.dart';

class CollectionForm extends StatefulWidget {
  final String gameId;
  final String initialStatus;
  final String? initialNotes;
  final String? initialReview;  // Add initialReview field
  final double? initialRating;
  final bool showRemoveButton;
  final Function() onCancel;
  final Function() onRemove;
  final Function(String status, String? notes, String? review, double? rating) onSubmit;  // Update callback to include review

  const CollectionForm({
    Key? key,
    required this.gameId,
    required this.initialStatus,
    this.initialNotes,
    this.initialReview,  // Add this parameter
    this.initialRating,
    required this.showRemoveButton,
    required this.onCancel,
    required this.onRemove,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _CollectionFormState createState() => _CollectionFormState();
}

class _CollectionFormState extends State<CollectionForm> {
  late String _selectedStatus;
  late TextEditingController _notesController;
  late TextEditingController _reviewController;  // Add controller for review
  double? _rating;
  bool _showRating = false;
  bool _showReview = false;  // Additional flag for review

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus.isEmpty
        ? GameCollectionStatus.wantToPlay
        : widget.initialStatus;
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _reviewController = TextEditingController(text: widget.initialReview ?? '');  // Initialize review controller
    _rating = widget.initialRating;
    _showRating = _selectedStatus == GameCollectionStatus.played;
    _showReview = _selectedStatus == GameCollectionStatus.played;  // Only show review for played games
  }

  @override
  void dispose() {
    _notesController.dispose();
    _reviewController.dispose();  // Dispose review controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusSelector(),
          const SizedBox(height: 16),
          _buildNotesInput(),
          const SizedBox(height: 16),
          if (_showRating) _buildRatingInput(),
          if (_showRating) const SizedBox(height: 16),
          if (_showReview) _buildReviewInput(),  // Add review input
          if (_showReview) const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '收藏状态',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildStatusOption(
                GameCollectionStatus.wantToPlay,
                '想玩',
                Icons.watch_later_outlined,
              ),
              _buildStatusOption(
                GameCollectionStatus.playing,
                '在玩',
                Icons.gamepad_outlined,
              ),
              _buildStatusOption(
                GameCollectionStatus.played,
                '玩过',
                Icons.task_alt_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOption(String status, String label, IconData icon) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = status;
            _showRating = status == GameCollectionStatus.played;
            _showReview = status == GameCollectionStatus.played;  // Update review visibility
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '备注 (可选)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: '添加个人备注...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  // Add review input widget
  Widget _buildReviewInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '评价 (可选)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          decoration: InputDecoration(
            hintText: '写下你对这款游戏的评价...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildRatingInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '评分 (可选)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _rating != null ? '${_rating!.toStringAsFixed(1)}/10' : '',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
            ),
          ),
          child: Slider(
            value: _rating ?? 0,
            min: 0,
            max: 10,
            divisions: 20,
            label: _rating != null ? _rating!.toStringAsFixed(1) : null,
            onChanged: (value) {
              setState(() {
                _rating = value;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('0', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('10', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.showRemoveButton)
          TextButton(
            onPressed: widget.onRemove,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除收藏'),
          ),
        const Spacer(),
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(
              _selectedStatus,
              _notesController.text.trim(),
              _reviewController.text.trim(),  // Pass review text to callback
              _rating,
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}