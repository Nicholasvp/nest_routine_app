import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';

class QuickActionBar extends StatelessWidget {
  final VoidCallback? onSleep;
  final VoidCallback? onFeed;
  final VoidCallback? onPee;
  final VoidCallback? onPoop;
  final bool isSleeping;
  final bool isFeeding;

  const QuickActionBar({
    super.key,
    this.onSleep,
    this.onFeed,
    this.onPee,
    this.onPoop,
    this.isSleeping = false,
    this.isFeeding = false,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: isSleeping ? Icons.nightlight_round : Icons.bedtime_outlined,
            label: isSleeping ? strings.awake : strings.sleep_,
            color: AppColors.sleepPurple,
            isActive: isSleeping,
            onTap: onSleep,
          ),
          _ActionButton(
            icon: isFeeding ? Icons.local_dining_outlined : Icons.local_dining_outlined,
            label: strings.feed_,
            color: AppColors.feedOrange,
            glowEnabled: true,
            isActive: isFeeding,
            onTap: onFeed,
          ),
          _ActionButton(
            icon: Icons.water_drop_outlined,
            label: strings.pee,
            color: AppColors.diaperTeal,
            glowEnabled: true,
            onTap: onPee,
          ),
          _ActionButton(
            icon: Icons.circle_outlined,
            label: strings.poop,
            color: AppColors.diaperMint,
            glowEnabled: true,
            onTap: onPoop,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final bool glowEnabled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isActive = false,
    this.glowEnabled = false,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late AnimationController _glowController;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );
    _glow = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
    if (widget.glowEnabled) _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scale, _glow]),
        builder: (context, _) => Transform.scale(
          scale: _scale.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? widget.color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: widget.isActive ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                    boxShadow: widget.isActive || widget.glowEnabled
                        ? [
                            BoxShadow(
                              color: widget.color.withValues(
                                alpha: widget.isActive
                                    ? 0.18 + (_glow.value * 0.12)
                                    : 0.08 + (_glow.value * 0.1),
                              ),
                              blurRadius: 5 + (_glow.value * 5),
                              spreadRadius: 0.5 + (_glow.value * 0.8),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.isActive
                        ? widget.color
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isActive
                        ? widget.color
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
