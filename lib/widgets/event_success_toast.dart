import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class EventSuccessToast extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  const EventSuccessToast({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });

  static void show(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _EventSuccessToastOverlay(
        icon: icon,
        color: color,
        title: title,
        subtitle: subtitle,
        onDismissed: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _EventSuccessToastOverlay extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onDismissed;

  const _EventSuccessToastOverlay({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onDismissed,
  });

  @override
  State<_EventSuccessToastOverlay> createState() => _EventSuccessToastOverlayState();
}

class _EventSuccessToastOverlayState extends State<_EventSuccessToastOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_outline,
                color: widget.color,
                size: 18,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 200.ms, curve: Curves.easeOut)
            .slideY(begin: -0.3, end: 0, duration: 250.ms, curve: Curves.easeOut)
            .then(delay: 1400.ms)
            .fadeOut(duration: 300.ms, curve: Curves.easeIn)
            .slideY(begin: 0, end: -0.2, duration: 300.ms, curve: Curves.easeIn),
      ),
    );
  }
}
