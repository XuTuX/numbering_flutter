import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

OverlayEntry? _currentOverlay;

void showAppSnackBar({
  required String message,
  String? title,
  Color backgroundColor = const Color(0xFF171716),
  Color textColor = const Color(0xFFFFFFFF),
  Color borderColor = const Color(0x33FFFFFF),
  IconData icon = Icons.info_outline_rounded,
  Color? iconColor,
  Duration duration = const Duration(seconds: 3),
}) {
  _currentOverlay?.remove();
  _currentOverlay = null;

  final navigatorState = _findNavigatorOverlay();
  if (navigatorState == null) {
    debugPrint('SnackBar skipped because Overlay is not available.');
    return;
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopSnackBarWidget(
      message: message,
      title: title,
      backgroundColor: backgroundColor,
      textColor: textColor,
      borderColor: borderColor,
      icon: icon,
      iconColor: iconColor,
      duration: duration,
      onDismiss: () {
        entry.remove();
        if (_currentOverlay == entry) {
          _currentOverlay = null;
        }
      },
    ),
  );

  _currentOverlay = entry;
  navigatorState.insert(entry);
}

OverlayState? _findNavigatorOverlay() {
  try {
    if (Get.key.currentState?.overlay != null) {
      return Get.key.currentState?.overlay;
    }
  } catch (_) {}

  try {
    final context = appScaffoldMessengerKey.currentContext;
    if (context != null) {
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay != null) return overlay;
    }
  } catch (_) {}

  try {
    final navKey = WidgetsBinding.instance.rootElement;
    if (navKey != null) {
      NavigatorState? navigator;
      navKey.visitChildElements((element) {
        element.visitChildElements((child) {
          if (child is StatefulElement && child.state is NavigatorState) {
            navigator = child.state as NavigatorState;
          }
        });
      });
      return navigator?.overlay;
    }
  } catch (_) {}

  return null;
}

void clearAppSnackBars() {
  _currentOverlay?.remove();
  _currentOverlay = null;
  appScaffoldMessengerKey.currentState?.clearSnackBars();
}

class _TopSnackBarWidget extends StatefulWidget {
  const _TopSnackBarWidget({
    required this.message,
    this.title,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.icon,
    this.iconColor,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final String? title;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final IconData icon;
  final Color? iconColor;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_TopSnackBarWidget> createState() => _TopSnackBarWidgetState();
}

class _TopSnackBarWidgetState extends State<_TopSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _animController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final effectiveIconColor = widget.iconColor ?? widget.textColor;
    final hasTitle = widget.title != null && widget.title!.trim().isNotEmpty;
    final isCompactInline = hasTitle && widget.message.trim().length <= 20;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -100) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: widget.borderColor.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          size: 18,
                          color: effectiveIconColor,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: isCompactInline
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.title!.tr,
                                      style: GoogleFonts.blackHanSans(
                                        fontSize: 13.5,
                                        color: widget.textColor,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                      ),
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: widget.textColor
                                            .withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        widget.message.tr,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: widget.textColor
                                              .withValues(alpha: 0.95),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasTitle)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 1),
                                        child: Text(
                                          widget.title!.tr,
                                          style: GoogleFonts.blackHanSans(
                                            fontSize: 13,
                                            color: widget.textColor,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      widget.message.tr,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: widget.textColor
                                            .withValues(alpha: 0.85),
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

