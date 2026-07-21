import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/baby_provider.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/event_card.dart';
import '../widgets/bottom_sheets/sleep_sheet.dart';
import '../widgets/bottom_sheets/feed_sheet.dart';
import '../widgets/bottom_sheets/diaper_sheet.dart';
import '../services/navigation_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late ValueNotifier<DateTime> _currentDay;

  @override
  void initState() {
    super.initState();
    _currentDay = ValueNotifier<DateTime>(DateTime.now());
  }

  @override
  void dispose() {
    _currentDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = context.watch<BabyProvider>();
    final eventProvider = context.watch<EventProvider>();
    final baby = babyProvider.currentBaby;

    if (baby == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: const Center(child: Text('No baby profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppDateUtils.formatDateFull(_currentDay.value)),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => NavigationService.goToHome(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
      ),
      body: Column(
        children: [
          _buildDayNavigation(context, eventProvider, baby.id),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _currentDay,
              builder: (context, day, __) {
                final events =
                    eventProvider.getEventsForDay(baby.id, day);
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_outlined,
                            size: 48,
                            color: AppColors.textTertiary
                                .withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'No events for this day',
                          style: TextStyle(
                              color: AppColors.textTertiary, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(
                      event: event,
                      onTap: () => _showEditEventSheet(
                          context, eventProvider, event),
                      onDelete: () => _confirmDelete(
                          context, eventProvider, event),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayNavigation(BuildContext context,
      EventProvider eventProvider, String babyId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              _currentDay.value = _currentDay.value.subtract(const Duration(days: 1));
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _currentDay.value,
                  firstDate: now.subtract(const Duration(days: 365)),
                  lastDate: now,
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.sleepPurple,
                        surface: AppColors.darkPurple,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  _currentDay.value = picked;
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentDay.value == today
                          ? Icons.today
                          : Icons.calendar_month_outlined,
                      size: 16,
                      color: AppColors.softLavender,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, yyyy').format(_currentDay.value),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            isEnabled: !AppDateUtils.isSameDay(_currentDay.value, today),
            onTap: _currentDay.value.isBefore(today)
                ? () {
                    _currentDay.value =
                        _currentDay.value.add(const Duration(days: 1));
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showEditEventSheet(
      BuildContext context, EventProvider eventProvider, BabyEvent event) {
    HapticFeedback.lightImpact();

    switch (event.type) {
      case EventType.sleep:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SleepSheet(
            event: event,
            onStartSleep: (_) {},
            onStopSleep: (_) {},
            onUpdateSleep: (updated) {
              eventProvider.updateEvent(updated);
            },
          ),
        );
      case EventType.feed:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => FeedSheet(
            event: event,
            onStartNursing: (_, __) {},
            onStopNursing: (_, __) {},
            onLogFeed: (_) {},
            onUpdateFeed: (updated) {
              eventProvider.updateEvent(updated);
            },
          ),
        );
      case EventType.pee:
      case EventType.poop:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DiaperSheet(
            event: event,
            defaultPee: event.hasPee,
            onLogDiaper: (_) {},
            onUpdateDiaper: (updated) {
              eventProvider.updateEvent(updated);
            },
          ),
        );
    }
  }

  void _confirmDelete(
      BuildContext context, EventProvider eventProvider, BabyEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('Remove this ${event.typeLabel.toLowerCase()} log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              eventProvider.removeEvent(event.babyId, event.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _NavButton({
    required this.icon,
    this.isEnabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isEnabled
              ? AppColors.textSecondary
              : AppColors.textTertiary.withValues(alpha: 0.4),
          size: 22,
        ),
      ),
    );
  }
}
