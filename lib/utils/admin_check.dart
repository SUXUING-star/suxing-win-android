import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth/auth_provider.dart';

class AdminCheck extends StatelessWidget {
  final Widget child;
  final Widget fallback;

  const AdminCheck({
    Key? key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isAdmin) {
      return child;
    }
    return fallback;
  }
}