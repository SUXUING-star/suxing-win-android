// lib/widgets/layouts/desktop/desktop_sidebar_nav_item.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class DesktopSidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const DesktopSidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.index,
    this.isSelected = false,
    required this.onTap,
  });

  // Define icon background colors for each nav item
  static final List<Color> _navItemColors = [
    Color(0xFF4CAF50), // Home - Green
    Color(0xFFE91E63), // Games - Pink
    Color(0xFF9C27B0), // Forum - Purple
    Color(0xFFFF9800), // Activity - Orange
    Color(0xFF03A9F4), // External - Blue
  ];

  Color get _navItemColor =>
      index < _navItemColors.length ? _navItemColors[index] : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: label,
          preferBelow: false,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            hoverColor: Colors.white.withSafeOpacity(0.2),
            splashColor: Colors.white.withSafeOpacity(0.3),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with background
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withSafeOpacity(0.3)
                            : _navItemColor.withSafeOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : _navItemColor.withSafeOpacity(0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _navItemColor.withSafeOpacity(0.4),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
