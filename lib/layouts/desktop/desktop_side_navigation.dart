// // lib/layouts/desktop/desktop_side_navigation.dart
// import 'package:flutter/material.dart';
// import '../../routes/app_routes.dart';
// import '../../widgets/components/screen/home/player/windows/windows_side_player.dart';
//
// class DesktopSideNavigation extends StatelessWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//
//   const DesktopSideNavigation({
//     Key? key,
//     required this.currentIndex,
//     required this.onTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 260,
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.9),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // 当前页面导航标题
//           _buildPageTitle(context, currentIndex),
//
//           Divider(height: 1, thickness: 1, color: Colors.grey[200]),
//
//           // 导航项
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.symmetric(vertical: 12),
//               children: [
//                 _buildNavItem(context, 0, Icons.home_rounded, '首页', AppRoutes.home),
//                 _buildNavItem(context, 1, Icons.games_rounded, '游戏', AppRoutes.gamesList),
//                 _buildNavItem(context, 2, Icons.link_rounded, '外部', AppRoutes.externalLinks),
//                 _buildNavItem(context, 3, Icons.forum_rounded, '论坛', AppRoutes.forum),
//                 _buildNavItem(context, 4, Icons.person_rounded, '我的', AppRoutes.profile),
//               ],
//             ),
//           ),
//
//           // 音乐播放器固定在左侧栏底部
//           WindowsSidePlayer(),
//         ],
//       ),
//     );
//   }
//
//   // 构建页面标题
//   Widget _buildPageTitle(BuildContext context, int index) {
//     String title;
//     IconData icon;
//
//     switch(index) {
//       case 0:
//         title = '首页';
//         icon = Icons.home_rounded;
//         break;
//       case 1:
//         title = '游戏';
//         icon = Icons.games_rounded;
//         break;
//       case 2:
//         title = '外部';
//         icon = Icons.link_rounded;
//         break;
//       case 3:
//         title = '论坛';
//         icon = Icons.forum_rounded;
//         break;
//       case 4:
//         title = '我的';
//         icon = Icons.person_rounded;
//         break;
//       default:
//         title = '首页';
//         icon = Icons.home_rounded;
//     }
//
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             size: 24,
//             color: Theme.of(context).primaryColor,
//           ),
//           SizedBox(width: 16),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[800],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, String route) {
//     final isSelected = currentIndex == index;
//     final primaryColor = Theme.of(context).primaryColor;
//
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//       child: Material(
//         color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//         child: InkWell(
//           onTap: () {
//             // 使用路由跳转
//             if (!isSelected) {
//               onTap(index);
//               Navigator.pushReplacementNamed(context, route);
//             }
//           },
//           borderRadius: BorderRadius.circular(8),
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               border: Border(
//                 left: BorderSide(
//                   color: isSelected ? primaryColor : Colors.transparent,
//                   width: 3,
//                 ),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   icon,
//                   size: 22,
//                   color: isSelected ? primaryColor : Colors.grey[700],
//                 ),
//                 SizedBox(width: 12),
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: isSelected ? primaryColor : Colors.grey[800],
//                     fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }