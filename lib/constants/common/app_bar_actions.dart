
import 'package:flutter/material.dart';

enum AppBarAction {
  // 定义枚举值，并在构造函数中传入常量
  toggleLeftPanel(
      icon: Icons.menu_open, type: 'functional', defaultBgColor: Colors.white),
  toggleRightPanel(
      icon: Icons.bar_chart_outlined,
      type: 'functional',
      defaultBgColor: Colors.white),
  addGame(
      icon: Icons.add,
      defaultTooltip: '添加游戏',
      defaultIconColor: Colors.green,
      type: 'functional',
      defaultBgColor: Colors.white), // 注意：颜色用了 Colors.green，更稳定
  myGames(
      icon: Icons.history_edu,
      defaultTooltip: '我的提交',
      defaultIconColor: Colors.orange,
      type: 'functional',
      defaultBgColor: Colors.white),
  searchGame(
      icon: Icons.search,
      defaultTooltip: '搜索游戏',
      defaultIconColor: Colors.blue,
      type: 'functional',
      defaultBgColor: Colors.white),
  filterSort(
      icon: Icons.filter_list,
      defaultTooltip: '筛选与排序',
      defaultIconColor: Colors.deepOrangeAccent,
      type: 'functional',
      defaultBgColor: Colors.white),
  clearCategoryFilter(
      icon: Icons.filter_list_off_outlined,
      defaultIconColor: Colors.red,
      type: 'icon'), // 使用 Colors.red
  clearTagFilter(
      icon: Icons.label_off_outlined,
      defaultIconColor: Colors.red,
      type: 'icon'),
  toggleMobileTagBar(icon: Icons.tag, type: 'icon'), // 默认颜色依赖主题
  searchForumPost(
      // 和 searchGame 区分开
      icon: Icons.search, // 可以用同一个图标
      defaultTooltip: '搜索帖子',
      defaultIconColor: Colors.blue, // 保持一致或自定义
      defaultBgColor: Colors.white,
      type: 'functional'),
  refreshForum(
      // 区分 refresh
      icon: Icons.refresh,
      defaultTooltip: '刷新帖子',
      defaultIconColor: Colors.green,
      defaultBgColor: Colors.white,
      type: 'functional'),
  createForumPost(
      // 区分 addGame
      icon: Icons.add_circle_outline,
      defaultTooltip: '发布新帖子',
      defaultIconColor: Colors.orange,
      defaultBgColor: Colors.white,
      type: 'functional');

  // 枚举成员变量 (常量)
  final IconData icon;
  final String? defaultTooltip;
  final Color? defaultIconColor;
  final Color? defaultBgColor; // FunctionalIconButton 背景色
  final String type; // 'functional' or 'icon'

  // 枚举构造函数 (必须是 const)
  const AppBarAction({
    required this.icon,
    this.defaultTooltip,
    this.defaultIconColor,
    this.defaultBgColor,
    required this.type,
  });
}
