// lib/screens/game/list/common_game_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/base_game_card.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_content_grid.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';

class CommonGameListScreen extends StatelessWidget {
  final String title;
  final User? currentUser;
  final List<Game> games;
  final bool isLoading;
  final String? error;
  final Future<void> Function()? onRefreshTriggered;
  final int pageSize;
  final bool showSortOptions;
  final bool showAddButton;
  final Widget? emptyStateIcon;
  final String emptyStateMessage;
  final bool useScaffold;
  final bool showAddButtonInAppBar;
  final bool showMySubmissionsButton;
  final bool showSearchButton;
  final void Function(BuildContext)? onFilterPressed;
  final void Function()? onMySubmissionsPressed;
  final void Function()? onAddPressed;
  final Future<void> Function(Game game)? onDeleteGameAction;
  final Widget Function(Game)? customCardBuilder;
  final List<Widget>? additionalActions;
  final WindowStateProvider windowStateProvider;

  const CommonGameListScreen({
    super.key,
    required this.currentUser,
    required this.title,
    required this.games,
    required this.windowStateProvider,
    this.isLoading = false,
    this.error,
    this.onRefreshTriggered,
    this.pageSize = 15,
    this.showSortOptions = false,
    this.showAddButton = false,
    this.emptyStateIcon,
    required this.emptyStateMessage,
    this.useScaffold = true,
    this.additionalActions,
    this.onFilterPressed,
    this.onMySubmissionsPressed,
    this.onAddPressed,
    this.showAddButtonInAppBar = false,
    this.showMySubmissionsButton = false,
    this.showSearchButton = false,
    this.customCardBuilder,
    this.onDeleteGameAction,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title;
    final finalShowAddButton = currentUser == null ? false : showAddButton;

    final appBar = useScaffold
        ? CustomAppBar(
            title: displayTitle,
            actions: _buildAppBarActions(context),
            bottom: null,
          )
        : null;

    final floatingActionButton = (useScaffold && finalShowAddButton)
        ? GenericFloatingActionButton(
            onPressed: onAddPressed ??
                () => NavigationUtils.pushNamed(context, AppRoutes.addGame),
            icon: Icons.add,
            tooltip: '添加游戏',
            heroTag: 'common_game_list_fab_${key?.toString() ?? title}',
          )
        : null;

    Widget bodyContent;
    if (isLoading && games.isEmpty) {
      bodyContent = _buildLoading();
    } else if (error != null && games.isEmpty) {
      bodyContent = _buildError(error!, onRefreshTriggered);
    } else if (!isLoading && games.isEmpty) {
      bodyContent = _buildEmptyState(context);
    } else {
      bodyContent = _buildContentWrapper(context);
    }

    if (useScaffold) {
      return Scaffold(
          appBar: appBar,
          body: bodyContent,
          floatingActionButton: floatingActionButton);
    } else {
      return bodyContent;
    }
  }

  Widget _buildContentWrapper(BuildContext context) {
    Widget content = _buildContentList(context: context);
    if (onRefreshTriggered != null) {
      return RefreshIndicator(
        onRefresh: onRefreshTriggered!,
        child: content,
      );
    } else {
      return content;
    }
  }

  Widget _buildContentList({
    required BuildContext context,
  }) {
    final cardsPerRow = DeviceUtils.calculateGameCardsInGameListPerRow(
      context,
      withPanels: false,
    );
    final cardRatio = DeviceUtils.calculateSimpleGameCardRatio(context);

    return LazyLayoutBuilder(
      windowStateProvider: windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = DeviceUtils.isDesktopInThisWidth(screenWidth);
        return AnimatedContentGrid<Game>(
          gridKey: PageStorageKey('game_grid_$title'),
          items: games,
          crossAxisCount: cardsPerRow > 0 ? cardsPerRow : 1,
          childAspectRatio: cardRatio,
          padding: EdgeInsets.all(isDesktop ? 16 : 8),
          mainAxisSpacing: isDesktop ? 16 : 8,
          itemBuilder: (context, index, game) {
            // itemBuilder 专注于构建业务卡片。
            return customCardBuilder != null
                ? customCardBuilder!(game)
                : BaseGameCard(
                    key: ValueKey(game.id),
                    currentUser: currentUser,
                    game: game,
                    isGridItem: true,
                    adaptForPanels: false,
                    showCollectionStats: true,
                    forceCompact: cardsPerRow > 3,
                    maxTags: 1,
                    onDeleteAction: onDeleteGameAction != null
                        ? () => onDeleteGameAction!(game)
                        : null,
                  );
          },
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    final actions = <Widget>[];
    final Color enabledColor = Colors.white;

    final finalShowMySubmissionsButton =
        currentUser == null ? false : showMySubmissionsButton;
    final finalShowAddButtonInAppBar =
        currentUser == null ? false : showAddButtonInAppBar;

    if (additionalActions != null) {
      actions.addAll(additionalActions!);
    }
    if (finalShowAddButtonInAppBar) {
      actions.add(IconButton(
          icon: Icon(Icons.add, color: enabledColor),
          onPressed: onAddPressed ??
              () => NavigationUtils.pushNamed(context, AppRoutes.addGame),
          tooltip: '添加游戏'));
    }
    if (finalShowMySubmissionsButton) {
      actions.add(IconButton(
          icon: Icon(Icons.history_edu, color: enabledColor),
          onPressed: onMySubmissionsPressed ??
              () => NavigationUtils.pushNamed(context, AppRoutes.myGames),
          tooltip: '我的提交'));
    }
    if (showSearchButton) {
      actions.add(IconButton(
          icon: Icon(Icons.search, color: enabledColor),
          onPressed: () =>
              NavigationUtils.pushNamed(context, AppRoutes.searchGame),
          tooltip: '搜索游戏'));
    }
    if (showSortOptions && onFilterPressed != null) {
      actions.add(IconButton(
          icon: Icon(Icons.filter_list, color: enabledColor),
          onPressed: () => onFilterPressed!(context),
          tooltip: '排序/筛选'));
    }

    return actions;
  }

  static Widget _buildLoading() {
    return const FadeInItem(
      // 全屏加载组件
      child: LoadingWidget(
        isOverlay: true,
        message: "少女祈祷中...",
        overlayOpacity: 0.4,
        size: 36,
      ),
    ); //
  }

  static Widget _buildError(String message, Future<void> Function()? onRetry) {
    return FadeInItem(
        child: CustomErrorWidget(errorMessage: message, onRetry: onRetry));
  }

  // *** 改为非静态，可以访问 emptyStateMessage ***
  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      iconData: emptyStateIcon as IconData? ??
          Icons.sentiment_dissatisfied_outlined, // 使用传入的 Icon 或默认
      message: emptyStateMessage, // 使用传入的消息
    );
  }
}
