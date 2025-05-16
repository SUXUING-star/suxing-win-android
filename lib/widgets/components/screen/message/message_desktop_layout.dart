
// ---------------------------------------------------------------- //
// 该组件已经被封印了！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！
// ---------------------------------------------------------------- //

// // lib/widgets/components/screen/message/message_desktop_layout.dart
// import 'package:flutter/material.dart';
// import '../../../../utils/device/device_utils.dart';
//
// class MessageDesktopLayout extends StatelessWidget {
//   final String title;
//   final Widget body;
//   final List<Widget>? actions;
//   final Widget? rightPanel;
//   final bool rightPanelVisible;
//   final PreferredSizeWidget? bottom;
//
//   const MessageDesktopLayout({
//     Key? key,
//     required this.title,
//     required this.body,
//     this.actions,
//     this.rightPanel,
//     this.rightPanelVisible = false,
//     this.bottom,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final sidePanelWidth = DeviceUtils.getSidePanelWidth(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//         actions: actions,
//         bottom: bottom,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.centerLeft,
//               end: Alignment.centerRight,
//               colors: [
//                 Color(0xFF6AB7F0),
//                 Color(0xFF4E9DE3),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Main content
//           Expanded(
//             child: body,
//           ),
//
//           // Right panel
//           if (rightPanel != null && rightPanelVisible)
//             Container(
//               width: sidePanelWidth,
//               height: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withSafeOpacity(0.05),
//                     blurRadius: 5,
//                     offset: Offset(-2, 0),
//                   ),
//                 ],
//               ),
//               child: rightPanel,
//             ),
//         ],
//       ),
//     );
//   }
// }