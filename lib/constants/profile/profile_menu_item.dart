// lib/constants/profile/profile_menu_item.dart
import 'package:flutter/material.dart';

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final VoidCallback? onTap;

  ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.onTap,
  });
}
