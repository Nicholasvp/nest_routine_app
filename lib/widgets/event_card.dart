import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../utils/strings.dart';

class EventCard extends StatelessWidget {
  final BabyEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showDate;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onDelete,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.eventColor(event.type.name);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_eventIcon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.localizedTypeLabel(context.read<LocaleProvider>().strings),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (event.durationLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          event.durationLabel,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(context.read<LocaleProvider>().strings),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData get _eventIcon {
    switch (event.type) {
      case EventType.sleep:
        return Icons.nightlight_round;
      case EventType.feed:
        return Icons.local_dining_outlined;
      case EventType.pee:
        return Icons.water_drop_outlined;
      case EventType.poop:
        return Icons.circle_outlined;
    }
  }

  String _subtitle(Strings strings) {
    final time = AppDateUtils.formatTime(event.startTime, isPt: strings.pt);
    final datePart =
        showDate ? ' ${AppDateUtils.formatDate(event.startTime, isPt: strings.pt)}' : '';

    if (event.type == EventType.feed) {
      final details = <String>[];
      if (event.feedType != null) {
        details.add(event.feedType == FeedType.breast ? strings.breast : strings.bottle);
      }
      if (event.feedSide != null && event.feedSide != FeedSide.both) {
        details.add(event.feedSide == FeedSide.left ? strings.left : strings.right);
      }
      if (event.feedType == FeedType.bottle && event.volumeMl != null) {
        details.add('${event.volumeMl}ml');
      }
      final detailStr =
          details.isNotEmpty ? ' · ${details.join(' · ')}' : '';
      return '$time$datePart$detailStr';
    }

    if (event.type == EventType.pee || event.type == EventType.poop) {
      final details = <String>[];
      if (event.hasPee) details.add(strings.pee);
      if (event.hasPoop) details.add(strings.poop);
      if (event.diaperTexture != null) {
        final labels = {
          DiaperTexture.normal: strings.normal,
          DiaperTexture.soft: strings.soft,
          DiaperTexture.liquid: strings.liquid,
          DiaperTexture.dry: strings.dry,
        };
        details.add(labels[event.diaperTexture]!);
      }
      final detailStr =
          details.isNotEmpty ? ' · ${details.join(' · ')}' : '';
      return '$time$datePart$detailStr';
    }

    if (event.durationLabel.isNotEmpty) {
      return '$time$datePart · ${event.durationLabel}';
    }

    return '$time$datePart';
  }
}
