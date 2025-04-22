import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart';
import '../../../../models/game/game_collection.dart';

class CollectionForm extends StatefulWidget {
  final String gameId;
  final String initialStatus;
  final String? initialNotes;
  final String? initialReview;
  final double? initialRating;
  final bool showRemoveButton;
  final Function() onCancel;
  final Function() onRemove;
  final Function(String status, String? notes, String? review, double? rating)
      onSubmit;

  const CollectionForm({
    super.key,
    required this.gameId,
    required this.initialStatus,
    this.initialNotes,
    this.initialReview,
    this.initialRating,
    required this.showRemoveButton,
    required this.onCancel,
    required this.onRemove,
    required this.onSubmit,
  });

  @override
  _CollectionFormState createState() => _CollectionFormState();
}

class _CollectionFormState extends State<CollectionForm> {
  late String _selectedStatus;
  late TextEditingController _notesController;
  late TextEditingController _reviewController;
  double? _rating;
  bool _showRating = false;
  bool _showReview = false;
  bool _isSubmitting = false; //  添加提交状态

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus.isEmpty
        ? GameCollectionStatus.wantToPlay
        : widget.initialStatus;
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _reviewController = TextEditingController(text: widget.initialReview ?? '');
    _rating = widget.initialRating;
    _showRating = _selectedStatus == GameCollectionStatus.played;
    _showReview = _selectedStatus == GameCollectionStatus.played;
    _isSubmitting = false; // 初始化提交状态
  }

  @override
  void dispose() {
    _notesController.dispose();
    _reviewController.dispose();
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
          if (_showReview) _buildReviewInput(),
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
            _showReview = status == GameCollectionStatus.played;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
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
        TextInputField(
          controller: _notesController, // 传递 controller
          hintText: '添加个人备注...',
          maxLines: 2,
          padding: EdgeInsets.zero, // 如果 CollectionForm 已有 padding，这里可能设为 zero
          showSubmitButton: false, // 这个场景不需要单独的提交按钮
          // textInputAction: TextInputAction.newline, // 已在 TextInputField 内部根据 maxLines 设置
        ),
      ],
    );
  }

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
        TextInputField( // <--- 使用封装的组件
          controller: _reviewController,
          hintText: '写下你对这款游戏的评价...',
          maxLines: 5,
          padding: EdgeInsets.zero,
          showSubmitButton: false,
          // textInputAction: TextInputAction.newline, // 已在 TextInputField 内部根据 maxLines 设置
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
            label: _rating?.toStringAsFixed(1),
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
    return Padding(
      padding: const EdgeInsets.only(top: 24.0), //  给按钮区域添加一些上边距，更美观
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, //  调整按钮的 MainAxisAlignment
        children: [
          // 删除收藏按钮 (红色主题)
          if (widget.showRemoveButton)
            Theme(
              //  使用 Theme 组件包裹删除按钮，设置红色主题
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: Colors.red.shade700, //  设置 primaryColor 为红色
                    ),
              ),
              child: FunctionalButton(
                onPressed: widget.onRemove,
                label: '删除收藏',
                icon: Icons.delete_outline,
              ),
            ),
          //  如果不需要删除按钮，则留空，不需要 Spacer() 占位
          if (!widget.showRemoveButton) const SizedBox.shrink(),

          //  右侧的 取消 和 保存 按钮
          Row(
            children: [
              FunctionalButton(
                onPressed: widget.onCancel,
                label: '取消',
                icon: Icons.cancel_outlined,
              ),
              const SizedBox(width: 12),
              FunctionalButton(
                onPressed: _handleSubmit, //  调用 _handleSubmit 方法处理提交
                label: '保存',
                icon: Icons.save_outlined,
                isLoading: _isSubmitting, //  传递加载状态
              ),
            ],
          ),
        ],
      ),
    );
  }

  //  处理表单提交的方法
  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
    }); //  设置提交状态为加载中
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟提交延迟
      widget.onSubmit(
        _selectedStatus,
        _notesController.text.trim(),
        _reviewController.text.trim(),
        _rating,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      }); //  提交完成后，取消加载状态
    }
  }
}
