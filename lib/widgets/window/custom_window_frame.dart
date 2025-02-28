// lib/widgets/window/custom_window_frame.dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomWindowFrame extends StatefulWidget {
  final Widget child;
  final String title;
  final Color backgroundColor;
  final Color iconColor;

  const CustomWindowFrame({
    Key? key,
    required this.child,
    this.title = '宿星茶会',
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.iconColor = Colors.white,
  }) : super(key: key);

  @override
  State<CustomWindowFrame> createState() => _CustomWindowFrameState();
}

class _CustomWindowFrameState extends State<CustomWindowFrame> with WindowListener {
  bool isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    isMaximized = await windowManager.isMaximized();
    setState(() {});
  }

  @override
  void onWindowMaximize() {
    setState(() {
      isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      isMaximized = false;
    });
  }

  Widget _buildWindowButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
    Color? backgroundColor,
    Color? hoverColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 46,
        height: 32,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            hoverColor: hoverColor ?? Colors.black12,
            child: Icon(
              icon,
              color: widget.iconColor,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      height: 32,
      color: widget.backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                windowManager.startDragging();
              },
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.iconColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          _buildWindowButton(
            onPressed: () {
              windowManager.minimize();
            },
            icon: Icons.remove,
            tooltip: '最小化',
          ),
          _buildWindowButton(
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
            icon: isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
            tooltip: isMaximized ? '还原' : '最大化',
          ),
          _buildWindowButton(
            onPressed: () {
              windowManager.close();
            },
            icon: Icons.close,
            tooltip: '关闭',
            hoverColor: Colors.red,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTitleBar(),
        Expanded(child: widget.child),
      ],
    );
  }
}