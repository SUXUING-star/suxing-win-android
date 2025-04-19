// 这个组件已经不再需要了

// // lib/widgets/components/loading/loading_screen.dart
// import 'package:flutter/material.dart';
// // --- 导入统一的动画组件 ---
// import 'package:suxingchahui/widgets/ui/animation/modern_loading_animation.dart';
//
// class LoadingScreen extends StatelessWidget {
//   final bool isLoading;
//   final String? message;
//   final Color? backgroundColor; // 允许自定义背景色 (默认半透明黑)
//   final Color? loadingColor;    // **允许外部强制指定加载颜色**
//   final double loadingSize;
//
//   const LoadingScreen({
//     Key? key,
//     required this.isLoading,
//     this.message,
//     this.backgroundColor,
//     this.loadingColor, // 允许外部覆盖主题色
//     this.loadingSize = 40.0,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     if (!isLoading) {
//       return const SizedBox.shrink();
//     }
//
//     final theme = Theme.of(context);
//     final effectiveBackgroundColor = backgroundColor ?? Colors.black.withOpacity(0.3);
//
//     final Color effectiveLoadingColor = loadingColor ?? theme.primaryColor;        // 亮背景（虽然默认是暗的）配主题色
//
//     // 文字颜色也应与背景形成对比
//     final textColor =  theme.colorScheme.onPrimary; // 暗背景配亮字
//
//
//     return Material(
//       type: MaterialType.transparency,
//       child: Container(
//         color: effectiveBackgroundColor,
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // --- 使用统一动画组件，并传入【计算好的主题相关颜色】 ---
//               ModernLoadingAnimation(
//                 size: loadingSize,
//                 color: effectiveLoadingColor, // **使用这个计算好的颜色**
//               ),
//               if (message != null && message!.isNotEmpty) ...[
//                 const SizedBox(height: 16),
//                 Text(
//                   message!,
//                   style: TextStyle(
//                     color: textColor, // 使用计算好的文字颜色
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }