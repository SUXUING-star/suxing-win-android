// lib/initialization/initialization_wrapper.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import './app_initializer.dart';
import '../widgets/startup/initialization_screen.dart';
import '../providers/initialize/initialization_provider.dart';

class InitializationWrapper extends StatefulWidget {
  final Widget Function(List<ChangeNotifierProvider> providers) onInitialized;

  const InitializationWrapper({
    Key? key,
    required this.onInitialized,
  }) : super(key: key);

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  late Future<Map<String, dynamic>> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = Future.microtask(() async {
      final initProvider = context.read<InitializationProvider>();
      return AppInitializer.initializeServices(initProvider);
    });
  }

  void _handleExit() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  void _handleRetry() {
    setState(() {
      _initFuture = Future.microtask(() async {
        final initProvider = context.read<InitializationProvider>();
        initProvider.reset();
        return AppInitializer.initializeServices(initProvider);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initFuture,
      builder: (context, snapshot) {
        final initProvider = context.watch<InitializationProvider>();

        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              initProvider.setError(snapshot.error.toString());
            }
          });
          return InitializationScreen(
            status: InitializationStatus.error,
            message: snapshot.error.toString(),
            progress: 0,
            onRetry: _handleRetry,
            onExit: _handleExit,
          );
        }

        if (snapshot.hasData) {
          final providers = AppInitializer.createProviders(snapshot.data!);
          return widget.onInitialized(providers);
        }

        return InitializationScreen(
          status: InitializationStatus.inProgress,
          message: initProvider.message,
          progress: initProvider.progress,
          onRetry: null,
          onExit: _handleExit,
        );
      },
    );
  }
}