// lib/widgets/loading/loading_screen.dart
import 'package:flutter/material.dart';
import 'normal_loading_overlay.dart';
import 'first_load_screen.dart';

class LoadingScreen extends StatefulWidget {
  final bool isLoading;
  final bool isFirstLoad;
  final String? message;

  const LoadingScreen({
    Key? key,
    required this.isLoading,
    this.isFirstLoad = false,
    this.message,
  }) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return const SizedBox.shrink();

    return widget.isFirstLoad
        ? FirstLoadScreen(message: widget.message)
        : NormalLoadingOverlay(message: widget.message);
  }
}
