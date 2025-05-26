import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/game/collection/game_collection_service.dart';
import 'package:suxingchahui/widgets/components/screen/game/dialog/collection_dialog.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';

class GameCollectionButton extends StatefulWidget {
  final Game game;
  final GameCollectionService gameCollectionService;
  final InputStateService inputStateService;
  final bool compact;
  final User? currentUser;
  final Function(CollectionChangeResult)? onCollectionChanged;
  final GameCollectionItem? initialCollectionStatus;
  final bool isPreview;

  const GameCollectionButton({
    super.key,
    required this.game,
    required this.gameCollectionService,
    required this.inputStateService,
    required this.currentUser,
    this.isPreview = false,
    this.compact = false,
    this.onCollectionChanged,
    this.initialCollectionStatus,
  });

  @override
  _GameCollectionButtonState createState() => _GameCollectionButtonState();
}

class _GameCollectionButtonState extends State<GameCollectionButton>
    with SnackBarNotifierMixin {
  bool _isLoading = false;
  GameCollectionItem? _collectionStatus; // 本地状态，用于按钮显示

  User? _currentUser;
  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
    _collectionStatus = widget.initialCollectionStatus;
    _isLoading = false;
    _currentUser = widget.currentUser;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
  }

  @override
  void didUpdateWidget(GameCollectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果游戏 ID 变了，强制同步
    if (_hasInitializedDependencies &&
        widget.game.id != oldWidget.game.id &&
        !_isLoading) {
      setState(() {
        _collectionStatus = widget.initialCollectionStatus;
      });
      return;
    }
    // 如果父组件传来的状态变了，并且按钮不在加载中，且内容确实不同，才同步
    if (_hasInitializedDependencies &&
        widget.initialCollectionStatus != oldWidget.initialCollectionStatus &&
        !_isLoading) {
      bool contentChanged = _collectionStatus?.status !=
              widget.initialCollectionStatus?.status ||
          _collectionStatus?.notes != widget.initialCollectionStatus?.notes ||
          _collectionStatus?.review != widget.initialCollectionStatus?.review ||
          _collectionStatus?.rating != widget.initialCollectionStatus?.rating;

      if (contentChanged) {
        setState(() {
          _collectionStatus = widget.initialCollectionStatus;
        });
      }
    }

    if (widget.currentUser != oldWidget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  Future<void> _showCollectionDialog() async {
    if (widget.currentUser == null) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    // *** 记住操作前的状态 ***
    final GameCollectionItem? oldStatus = _collectionStatus;

    final result = await showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true, //  允许点击外部关闭
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54, // 半透明遮罩层
      transitionDuration:
          const Duration(milliseconds: 350), // 动画时长，和 CustomConfirmDialog 一致

      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        // 返回 CollectionDialog 实例
        return GameCollectionDialog(
          inputStateService: widget.inputStateService,
          currentUser: widget.currentUser,
          gameId: widget.game.id,
          gameName: widget.game.title,
          currentStatus: _collectionStatus?.status,
          currentNotes: _collectionStatus?.notes,
          currentReview: _collectionStatus?.review,
          currentRating: _collectionStatus?.rating,
        );
      },

      transitionBuilder: (BuildContext buildContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child) {
        // 构建动画效果 (缩放 + 淡入)  和 CustomConfirmDialog 的动画效果一致
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack, // 使用传入的曲线
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn, // 淡入效果
            ),
            child: child, // child 就是 pageBuilder 返回的 CollectionDialog 实例
          ),
        );
      },
    );
    if (result != null && mounted) {
      final action = result['action'] as String;
      setState(() {
        _isLoading = true;
      });

      GameCollectionItem? finalNewStatus = oldStatus; // 默认为旧状态
      Map<String, int> countDeltas = {
        'want': 0,
        'playing': 0,
        'played': 0,
        'total': 0
      }; // 默认增量为0

      try {
        if (action == 'set') {
          final status = result['status'] as String;
          final notes = result['notes'] as String?;
          final review = result['review'] as String?;
          final rating = result['rating'] as double?;

          // 调用 Service
          final (item, returnedStatus) = await widget.gameCollectionService
              .setGameCollection(widget.game.id, status,oldStatus?.status,
                  notes: notes, review: review, rating: rating);

          if (item != null && returnedStatus == status) {
            finalNewStatus = item; // API 调用成功，记录新状态
            // *** 计算增量 ***
            countDeltas =
                _calculateCountDeltas(oldStatus?.status, finalNewStatus.status);

            showSnackbar(message: '收藏状态已更新', type: SnackbarType.success);
          } else {
            showSnackbar(message: "更新失败", type: SnackbarType.error);
            throw Exception("更新收藏失败");
          }
        } else if (action == 'remove') {
          // 调用 Service
          final success = await widget.gameCollectionService
              .removeGameCollection(widget.game.id);
          if (success) {
            finalNewStatus = null; // API 调用成功，新状态为 null
            // *** 计算增量 ***
            countDeltas = _calculateCountDeltas(oldStatus?.status, null);
            showSnackbar(message: '已从收藏中移除', type: SnackbarType.success);
          } else {
            showSnackbar(message: "移除收藏失败", type: SnackbarType.error);
            throw Exception("移除收藏失败");
          }
        }

        // *** 操作成功后 ***
        if (mounted) {
          // 1. 更新按钮自身的显示状态
          setState(() {
            _collectionStatus = finalNewStatus;
          });

          // 2. 调用回调，传递包含新状态和增量的结果对象给父组件
          final changeResult = CollectionChangeResult(
              newStatus: finalNewStatus, countDeltas: countDeltas);
          widget.onCollectionChanged?.call(changeResult); // <--- 传递结果对象
        }
      } catch (e) {
        // 统一处理 Service 调用失败或解析失败的异常
        // print(
        //     'GameCollectionButton (${widget.game.id}): Operation error in dialog handler: $e');
        showSnackbar(
            message: '操作失败: ${e.toString().split(':').last.trim()}',
            type: SnackbarType.error);
      } finally {
        // *** 无论成功失败，结束加载状态 ***
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {}
  }

  /// 计算收藏状态变化导致的计数增量
  Map<String, int> _calculateCountDeltas(
      String? oldStatusString, String? newStatusString) {
    Map<String, int> deltas = {
      'want': 0,
      'playing': 0,
      'played': 0,
      'total': 0
    };

    bool hadStatus = oldStatusString != null;
    bool hasStatus = newStatusString != null;

    // 1. 处理旧状态的减少
    if (hadStatus) {
      if (oldStatusString == GameCollectionStatus.wantToPlay) {
        deltas['want'] = -1;
      }
      if (oldStatusString == GameCollectionStatus.playing) {
        deltas['playing'] = -1;
      }
      if (oldStatusString == GameCollectionStatus.played) deltas['played'] = -1;
    }

    // 2. 处理新状态的增加
    if (hasStatus) {
      if (newStatusString == GameCollectionStatus.wantToPlay) {
        deltas['want'] = (deltas['want'] ?? 0) + 1;
      }
      if (newStatusString == GameCollectionStatus.playing) {
        deltas['playing'] = (deltas['playing'] ?? 0) + 1;
      }
      if (newStatusString == GameCollectionStatus.played) {
        deltas['played'] = (deltas['played'] ?? 0) + 1;
      }
    }

    // 3. 处理总数变化
    if (hadStatus && !hasStatus) {
      // 从有状态到无状态（移除）
      deltas['total'] = -1;
    } else if (!hadStatus && hasStatus) {
      // 从无状态到有状态（新增）
      deltas['total'] = 1;
    } else {
      // 状态变化 (want -> playing) 或无变化
      deltas['total'] = 0;
    }

    return deltas;
  }

  // 构建按钮 UI 的主方法 (build)
  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);
    // 检查本地状态 _collectionStatus 是否为 null 来判断是否已收藏
    final bool hasStatus = _collectionStatus != null;
    final ThemeData theme = Theme.of(context);

    // 预览模式下不允许显示按钮
    if (widget.isPreview) {
      return const SizedBox.shrink();
    }
    // 根据是否已收藏，返回不同的按钮 Widget
    if (hasStatus) {
      // 如果已收藏，调用 _buildCollectionStatusButton 来构建显示当前状态的按钮
      return _buildCollectionStatusButton(_collectionStatus!.status, theme);
    } else {
      // 如果未收藏，调用 _buildAddCollectionButton 来构建“添加收藏”按钮
      return _buildAddCollectionButton(theme);
    }
  }

  // 构建“添加收藏”按钮 (_buildAddCollectionButton) - 无变化
  Widget _buildAddCollectionButton(ThemeData theme) {
    if (widget.compact) {
      return IconButton(
        icon: _isLoading
            ? LoadingWidget.inline(size: 12)
            : Icon(Icons.add_circle_outline, color: theme.primaryColor),
        tooltip: _isLoading ? '处理中...' : '添加收藏',
        onPressed: _isLoading ? null : _showCollectionDialog,
      );
    } else {
      return ElevatedButton.icon(
        icon: _isLoading
            ? LoadingWidget.inline(size: 12)
            : Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
        label: Text(_isLoading ? '处理中...' : '添加收藏'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: theme.primaryColor,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: _isLoading ? null : _showCollectionDialog,
      );
    }
  }

  // 构建显示当前收藏状态的按钮 (_buildCollectionStatusButton) - 无变化
  Widget _buildCollectionStatusButton(String status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    IconData iconData;
    String statusText;

    switch (status) {
      case GameCollectionStatus.wantToPlay:
        backgroundColor = Color(0xFFE6F0FF);
        textColor = Color(0xFF3D8BFF);
        iconData = Icons.star_border;
        statusText = '想玩';
        break;
      case GameCollectionStatus.playing:
        backgroundColor = Color(0xFFE8F5E9);
        textColor = Color(0xFF4CAF50);
        iconData = Icons.sports_esports;
        statusText = '在玩';
        break;
      case GameCollectionStatus.played:
        backgroundColor = Color(0xFFF3E5F5);
        textColor = Color(0xFF9C27B0);
        iconData = Icons.check_circle_outline;
        statusText = '玩过';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        iconData = Icons.bookmark_border;
        statusText = '状态未知';
    }

    if (widget.compact) {
      return IconButton(
        icon: _isLoading
            ? LoadingWidget.inline(size: 12, message: "正在加载")
            : Icon(iconData, color: textColor),
        tooltip: _isLoading ? '处理中...' : statusText,
        onPressed: _isLoading ? null : _showCollectionDialog,
      );
    } else {
      return OutlinedButton.icon(
        icon: _isLoading
            ? LoadingWidget.inline(size: 12, message: "正在加载")
            : Icon(iconData, size: 18),
        label: Text(_isLoading ? '处理中...' : statusText),
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: backgroundColor,
          side: BorderSide(color: textColor.withSafeOpacity(0.5), width: 1),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: _isLoading ? null : _showCollectionDialog,
      );
    }
  }
}
