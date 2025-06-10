// lib/widgets/components/screen/game/collection/game_collection_button.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/widgets/components/screen/game/dialog/collection_dialog.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';

class GameCollectionButton extends StatefulWidget {
  final Game game;
  final GameCollectionService gameCollectionService;
  final InputStateService inputStateService;
  final bool compact;
  final User? currentUser;
  final Function(GameCollectionItem?, Game?)? onCollectionChanged;
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

class _GameCollectionButtonState extends State<GameCollectionButton> {
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

      // *** 这里是修改的核心 ***
      try {
        if (action == 'set') {
          final status = result['status'] as String;
          final notes = result['notes'] as String?;
          final review = result['review'] as String?;
          final rating = result['rating'] as double?;

          // 调用 Service，现在接收三个返回值
          final (newItem, returnedStatus, updatedGame) = await widget
              .gameCollectionService
              .setGameCollection(widget.game.id, status, oldStatus?.status,
                  notes: notes, review: review, rating: rating);

          if (newItem != null && returnedStatus == status) {
            AppSnackBar.showSuccess('收藏状态已更新');
            // *** 直接用后端返回的数据更新状态和调用回调 ***
            if (mounted) {
              setState(() {
                _collectionStatus = newItem;
              });
              // 把后端给的最新 game 对象和 collection 对象传上去
              widget.onCollectionChanged?.call(newItem, updatedGame);
            }
          } else {
            AppSnackBar.showError("操作失败");
          }
        } else if (action == 'remove') {
          // 调用 Service，现在接收两个返回值
          final (success, updatedGame) = await widget.gameCollectionService
              .removeGameCollection(widget.game.id);

          if (success) {
            AppSnackBar.showSuccess('已从收藏中移除');
            if (mounted) {
              setState(() {
                _collectionStatus = null;
              });
              // 移除后 collection 为 null，同样把后端给的 game 对象传上去
              widget.onCollectionChanged?.call(null, updatedGame);
            }
          } else {
            AppSnackBar.showError("操作失败");
          }
        }
      } catch (e) {
        AppSnackBar.showError("操作失败, ${e.toString()}");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // 构建按钮 UI 的主方法 (build)
  @override
  Widget build(BuildContext context) {
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
            ? const LoadingWidget(size: 18)
            : Icon(Icons.add_circle_outline, color: theme.primaryColor),
        tooltip: _isLoading ? '处理中...' : '添加收藏',
        onPressed: _isLoading ? null : _showCollectionDialog,
      );
    } else {
      return ElevatedButton.icon(
        icon: _isLoading
            ? const LoadingWidget(size: 18)
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
    // 直接调用工具类，一行搞定
    final statusTheme = GameCollectionStatusUtils.getTheme(status);

    if (widget.compact) {
      return IconButton(
        icon: _isLoading
            ? const LoadingWidget(size: 18, message: "正在加载")
            : Icon(statusTheme.icon, color: statusTheme.textColor),
        tooltip: _isLoading ? '处理中...' : statusTheme.text,
        onPressed: _isLoading ? null : _showCollectionDialog,
      );
    } else {
      return OutlinedButton.icon(
        icon: _isLoading
            ? const LoadingWidget(size: 18, message: "正在加载")
            : Icon(statusTheme.icon, size: 18),
        label: Text(_isLoading ? '处理中...' : statusTheme.text),
        style: OutlinedButton.styleFrom(
          foregroundColor: statusTheme.textColor,
          backgroundColor: statusTheme.backgroundColor,
          side: BorderSide(
              color: statusTheme.textColor.withSafeOpacity(0.5), width: 1),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: _isLoading ? null : _showCollectionDialog,
      );
    }
  }
}
