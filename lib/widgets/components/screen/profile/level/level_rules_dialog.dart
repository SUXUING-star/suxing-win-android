// // lib/widgets/components/screen/profile/level/level_rules_dialog.dart
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:suxingchahui/constants/user/level_constants.dart';
// import 'package:suxingchahui/services/main/user/user_service.dart';
// import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
// import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
// import '../../../../../utils/font/font_config.dart';
//
// class LevelRulesDialog extends StatefulWidget {
//   final int currentLevel;
//
//   const LevelRulesDialog({
//     super.key,
//     required this.currentLevel,
//   });
//
//   @override
//   _LevelRulesDialogState createState() => _LevelRulesDialogState();
// }
//
// class _LevelRulesDialogState extends State<LevelRulesDialog> {
//   List<Map<String, dynamic>> _levelRequirements = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadLevelRequirements();
//   }
//
//
//   Future<void> _loadLevelRequirements() async {
//     try {
//
//       final requirements = await userService.getLevelRequirements();
//       if (mounted) {
//         setState(() {
//           _levelRequirements = requirements;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDesktop = MediaQuery.of(context).size.width > 900;
//     final dialogWidth =
//         isDesktop ? 500.0 : MediaQuery.of(context).size.width * 0.9;
//
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         width: dialogWidth,
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.7,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // 标题栏
//             Padding(
//               padding: EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Icon(Icons.stars, color: theme.primaryColor),
//                   SizedBox(width: 8),
//                   Text(
//                     '等级规则',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: FontConfig.defaultFontFamily,
//                       fontFamilyFallback: FontConfig.fontFallback,
//                     ),
//                   ),
//                   Spacer(),
//                   IconButton(
//                     icon: Icon(Icons.close),
//                     padding: EdgeInsets.zero,
//                     constraints: BoxConstraints(),
//                     onPressed: () => NavigationUtils.of(context).pop(),
//                   ),
//                 ],
//               ),
//             ),
//
//             Divider(height: 1),
//
//             // 使用 Expanded + ListView 避免溢出
//             Flexible(
//               child: ListView(
//                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 shrinkWrap: true,
//                 children: [
//                   // 当前等级信息
//                   Text(
//                     '当前等级：Lv.${widget.currentLevel}',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: theme.primaryColor,
//                       fontFamily: FontConfig.defaultFontFamily,
//                       fontFamilyFallback: FontConfig.fontFallback,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     LevelUtils.getLevelDescription(widget.currentLevel),
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[700],
//                       fontFamily: FontConfig.defaultFontFamily,
//                       fontFamilyFallback: FontConfig.fontFallback,
//                     ),
//                   ),
//
//                   SizedBox(height: 16),
//
//                   // 等级特权
//                   Card(
//                     color: theme.primaryColor.withSafeOpacity(0.1),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8)),
//                     child: Padding(
//                       padding: EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '等级特权',
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.bold,
//                               fontFamily: FontConfig.defaultFontFamily,
//                               fontFamilyFallback: FontConfig.fontFallback,
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           _buildLevelBenefits(widget.currentLevel),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   SizedBox(height: 16),
//
//                   // 等级需求表
//                   Text(
//                     '等级经验需求表',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: FontConfig.defaultFontFamily,
//                       fontFamilyFallback: FontConfig.fontFallback,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//
//                   _isLoading
//                       ? Center(child: CircularProgressIndicator())
//                       : _buildLevelRequirementsTable(),
//
//                   SizedBox(height: 16),
//
//                   // 如何获取经验
//                   Text(
//                     '如何获取经验',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: FontConfig.defaultFontFamily,
//                       fontFamilyFallback: FontConfig.fontFallback,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//
//                   _buildExpItem('每日签到', '15~30经验/次'),
//                   _buildExpItem('发表帖子', '15经验/条'),
//                   _buildExpItem('评论', '5经验/条'),
//                   _buildExpItem('点赞', '5经验/次'),
//                 ],
//               ),
//             ),
//
//             // 底部按钮
//             Padding(
//               padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     child: Text('关闭'),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLevelBenefits(int level) {
//     final benefits = <Widget>[];
//
//     // 基础特权 - 所有等级都有
//     benefits.add(_buildBenefitItem('基础功能使用权限'));
//
//     // 根据等级添加特权
//     if (level >= 2) {
//       benefits.add(_buildBenefitItem('个性化头像框'));
//     }
//
//     if (level >= 3) {
//       benefits.add(_buildBenefitItem('扩展表情包'));
//     }
//
//     if (level >= 5) {
//       benefits.add(_buildBenefitItem('发图权限'));
//     }
//
//     if (level >= 10) {
//       benefits.add(_buildBenefitItem('创建主题帖权限'));
//     }
//
//     if (level >= 15) {
//       benefits.add(_buildBenefitItem('发布长文章权限'));
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: benefits,
//     );
//   }
//
//   Widget _buildBenefitItem(String text) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 6),
//       child: Row(
//         children: [
//           Icon(Icons.check_circle, color: Colors.green, size: 16),
//           SizedBox(width: 8),
//           Flexible(
//             child: Text(
//               text,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontFamily: FontConfig.defaultFontFamily,
//                 fontFamilyFallback: FontConfig.fontFallback,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildExpItem(String activity, String exp) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 6),
//       child: Row(
//         children: [
//           Icon(Icons.stars, color: Colors.amber, size: 16),
//           SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               activity,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontFamily: FontConfig.defaultFontFamily,
//                 fontFamilyFallback: FontConfig.fontFallback,
//               ),
//             ),
//           ),
//           Text(
//             exp,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[700],
//               fontFamily: FontConfig.defaultFontFamily,
//               fontFamilyFallback: FontConfig.fontFallback,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLevelRequirementsTable() {
//     // 检查是否有数据
//     if (_levelRequirements.isEmpty) {
//       return Center(
//         child: Text(
//           '暂无等级数据',
//           style: TextStyle(
//             color: Colors.grey[600],
//             fontFamily: FontConfig.defaultFontFamily,
//             fontFamilyFallback: FontConfig.fontFallback,
//           ),
//         ),
//       );
//     }
//
//     return Column(
//       children: List.generate(
//         _levelRequirements.length > 10
//             ? 10
//             : _levelRequirements.length, // 只显示前10级
//         (index) {
//           final levelData = _levelRequirements[index];
//           final level = levelData['level'] ?? index;
//           final totalExp = levelData['expRequired'] ?? 0;
//           final expToNextLevel = levelData['expToNextLevel'] ?? 0;
//
//           final isCurrentLevel = level == widget.currentLevel;
//
//           return Container(
//             decoration: BoxDecoration(
//               color: isCurrentLevel
//                   ? Theme.of(context).primaryColor.withSafeOpacity(0.1)
//                   : null,
//               border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
//             ),
//             padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//             child: Row(
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: Text(
//                     'Lv.$level',
//                     style: TextStyle(
//                       fontWeight:
//                           isCurrentLevel ? FontWeight.bold : FontWeight.normal,
//                       color: isCurrentLevel
//                           ? Theme.of(context).primaryColor
//                           : null,
//                       fontFamily: FontConfig.defaultFontFamily,
//                       fontFamilyFallback: FontConfig.fontFallback,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   flex: 3,
//                   child: Text(
//                     '累计: $totalExp',
//                     style: TextStyle(
//                       fontFamily: FontConfig.defaultFontFamily,
//                       fontFamilyFallback: FontConfig.fontFallback,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   flex: 3,
//                   child: Text(
//                     '升级: $expToNextLevel',
//                     style: TextStyle(
//                       fontFamily: FontConfig.defaultFontFamily,
//                       fontFamilyFallback: FontConfig.fontFallback,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
