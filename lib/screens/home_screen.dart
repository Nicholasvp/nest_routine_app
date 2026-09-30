import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../providers/baby_provider.dart';
import '../providers/event_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/prediction_engine.dart';
import '../utils/sleep_window.dart';
import '../widgets/circular_timeline.dart';
import '../widgets/sleep_window_battery.dart';
import '../widgets/event_card.dart';
import '../widgets/quick_action_bar.dart';
import '../widgets/bottom_sheets/sleep_sheet.dart';
import '../widgets/bottom_sheets/feed_sheet.dart';
import '../widgets/bottom_sheets/diaper_sheet.dart';
import '../widgets/bottom_sheets/bug_report_sheet.dart';
import '../services/navigation_service.dart';
import '../services/analytics_service.dart';
import '../services/review_service.dart';
import '../providers/subscription_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_settings_modal.dart';
import '../services/paywall_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _onRefresh(
      BabyProvider babyProvider, EventProvider eventProvider) async {
    final baby = babyProvider.currentBaby;
    if (baby != null) {
      eventProvider.loadEvents(baby.id);
      await eventProvider.loadEventsFromCloud(baby.id);
    }
    await babyProvider.loadBabiesFromCloud();
  }

  void _checkReviewPrompt(EventProvider eventProvider) {
    if (eventProvider.shouldShowReview) {
      eventProvider.consumeReviewPrompt();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final totalEvents = eventProvider.getAllEventsCount();
        final authProvider = context.read<AuthProvider>();
        final analytics = AnalyticsService(authProvider.authService);
        ReviewService.showReviewPrompt(
          context,
          totalEvents: totalEvents,
          analytics: analytics,
        );
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = context.watch<BabyProvider>();
    final eventProvider = context.watch<EventProvider>();
    final baby = babyProvider.currentBaby;
    final tr = context.watch<LocaleProvider>().strings;

    _checkReviewPrompt(eventProvider);

    if (baby == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.baby_changing_station_outlined,
                  size: 64, color: AppColors.textTertiary),
              SizedBox(height: 16),
              Text(
                tr.addBabyToStart,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => NavigationService.goToProfile(),
                icon: const Icon(Icons.add, size: 20),
                label: Text(tr.addBaby),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.softLavender,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isPro = context.watch<SubscriptionProvider>().isPro;
    final notificationsEnabled = context.watch<NotificationProvider>().permissionGranted;
    final settings = context.watch<NotificationProvider>().settings;
    final hasAnySmartNotification = settings.sleepEnabled || settings.diaperPeeEnabled || settings.diaperPoopEnabled;
    debugPrint('[HomeScreen] isPro=$isPro, notificationsEnabled=$notificationsEnabled, sleep=${settings.sleepEnabled}, diaperPee=${settings.diaperPeeEnabled}, diaperPoop=${settings.diaperPoopEnabled}, hasAnySmart=$hasAnySmartNotification, shouldShow=${!isPro || !notificationsEnabled || !hasAnySmartNotification}');
    final todayEvents = eventProvider.getTodayEvents(baby.id);
    final activeSleep = eventProvider.activeSleepTimer;
    final nextNap = eventProvider.predictNextNap(baby.id);
    final nextFeed = eventProvider.predictNextFeed(baby.id);
    final nextDiaper = eventProvider.predictNextDiaper(baby.id);
    final totalSleep = eventProvider.getTotalSleepToday(baby.id);
    final lastWakeUp = _lastWakeUpTime(eventProvider, baby.id);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, babyProvider, baby.name),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _onRefresh(babyProvider, eventProvider),
                color: AppColors.softLavender,
                backgroundColor: AppColors.cardDark,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      _buildTimelineSection(
                          context, eventProvider, todayEvents, activeSleep),
                      const SizedBox(height: 24),
                      _buildPredictionCards(
                          context, nextNap, nextFeed, nextDiaper, totalSleep,
                          onNapTap: () => _showSleepSheet(
                              context, eventProvider, activeSleep),
                          onFeedTap: () => _showFeedSheet(
                              context, eventProvider, baby.id),
                          onDiaperTap: () => _showDiaperSheet(
                              context, eventProvider, baby.id, defaultPee: true),
                        ),
                      const SizedBox(height: 12),
                      if (!isPro || !notificationsEnabled || !hasAnySmartNotification) ...[
                        _buildNotificationCtaBanner(context),
                        const SizedBox(height: 12),
                      ],
                      _SleepWindowBatteryWidget(
                        ageMonths: baby.ageInMonths,
                        lastWakeUp: lastWakeUp,
                        isSleeping: activeSleep != null,
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionSection(context, eventProvider, baby.id),
                      const SizedBox(height: 16),
                      _buildRecentEvents(context, eventProvider, baby.id, todayEvents),
                      const SizedBox(height: 24),
                      _buildBugReportLink(context),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, BabyProvider babyProvider, String name) {
    final tr = context.watch<LocaleProvider>().strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.hiThere,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => NavigationService.goToProfile(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.person_outline,
                  color: AppColors.textSecondary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(
    BuildContext context,
    EventProvider eventProvider,
    List<BabyEvent> todayEvents,
    BabyEvent? activeSleep,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: activeSleep != null
          ? AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CircularTimeline(
                  todayEvents: todayEvents,
                  activeSleep: activeSleep,
                  pulseScale: _pulseAnimation.value,
                  glowRadius: _glowAnimation.value,
                  onTap: () =>
                      _showSleepSheet(context, eventProvider, activeSleep),
                );
              },
            )
          : CircularTimeline(
              todayEvents: todayEvents,
              activeSleep: activeSleep,
              onTap: () =>
                  _showSleepSheet(context, eventProvider, activeSleep),
            ),
    );
  }

  Widget _buildPredictionCards(
    BuildContext context,
    PredictionResult nextNap,
    PredictionResult nextFeed,
    PredictionResult nextDiaper,
    double totalSleep, {
    VoidCallback? onNapTap,
    VoidCallback? onFeedTap,
    VoidCallback? onDiaperTap,
  }) {
    final tr = context.watch<LocaleProvider>().strings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PredictionCard(
                  icon: Icons.nightlight_round,
                  label: tr.nextNap,
                  value: nextNap.timeUntilLabel(tr.noPrediction, tr.late),
                  color: AppColors.sleepPurple,
                  confidence: nextNap.confidencePercent,
                  onTap: onNapTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PredictionCard(
                  icon: Icons.local_dining_outlined,
                  label: tr.nextFeed,
                  value: nextFeed.timeUntilLabel(tr.noPrediction, tr.late),
                  color: AppColors.feedOrange,
                  confidence: nextFeed.confidencePercent,
                  onTap: onFeedTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PredictionCard(
                  icon: Icons.cleaning_services_outlined,
                  label: tr.nextDiaper,
                  value: nextDiaper.timeUntilLabel(tr.noPrediction, tr.late),
                  color: AppColors.diaperTeal,
                  confidence: nextDiaper.confidencePercent,
                  onTap: onDiaperTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PredictionCard(
                  icon: Icons.bedtime_outlined,
                  label: tr.sleepToday,
                  value: '${totalSleep.toStringAsFixed(1)}h',
                  color: AppColors.softLavender,
                  confidence: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionSection(
      BuildContext context, EventProvider eventProvider, String babyId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: QuickActionBar(
        isSleeping: eventProvider.activeSleepTimer != null,
        isFeeding: eventProvider.activeFeedTimer != null,
        onSleep: () => _showSleepSheet(
            context, eventProvider, eventProvider.activeSleepTimer),
        onFeed: () => _showFeedSheet(context, eventProvider, babyId),
        onPee: () =>
            _showDiaperSheet(context, eventProvider, babyId, defaultPee: true),
        onPoop: () =>
            _showDiaperSheet(context, eventProvider, babyId, defaultPee: false, defaultPoop: true),
      ),
    );
  }

  Widget _buildRecentEvents(BuildContext context, EventProvider eventProvider,
      String babyId, List<BabyEvent> todayEvents) {
    final tr = context.watch<LocaleProvider>().strings;
    final recent = todayEvents.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.today,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  GestureDetector(
                    onTap: () => NavigationService.goToHistory(),
                    child: Text(
                      tr.seeAll,
                      style: const TextStyle(
                        color: AppColors.softLavender,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
        ),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history_outlined,
                      size: 40,
                      color: AppColors.textTertiary.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    tr.noEventsToday,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 14),
                  ),
                  Text(
                    tr.tapActionToStart,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...recent.map((event) => EventCard(
                event: event,
                onTap: () => _showEditEventSheet(context, eventProvider, event),
                onDelete: () => _confirmDelete(context, eventProvider, event),
              )),
      ],
    );
  }

  void _showSleepSheet(
      BuildContext context, EventProvider eventProvider, BabyEvent? activeTimer) {
    final babyId = context.read<BabyProvider>().currentBaby!.id;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SleepSheet(
        activeTimer: activeTimer,
        onStartSleep: (startTime) {
          eventProvider.startSleepTimer(babyId, startTime: startTime);
        },
        onStopSleep: (endTime) {
          eventProvider.stopSleepTimer(babyId, endTime: endTime);
        },
        onQuickLog: (startTime, endTime) {
          final event = BabyEvent(
            id: const Uuid().v4(),
            babyId: babyId,
            type: EventType.sleep,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: endTime.difference(startTime).inMinutes,
          );
          eventProvider.addEvent(event);
        },
      ),
    );
  }

  void _showFeedSheet(
      BuildContext context, EventProvider eventProvider, String babyId) {
    final activeFeed = eventProvider.activeFeedTimer;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedSheet(
        activeTimer: activeFeed,
        onStartNursing: (startTime, feedSide) {
          if (startTime.isAfter(DateTime.now().subtract(const Duration(minutes: 1)))) {
            eventProvider.startFeedTimer(babyId);
          } else {
            final event = BabyEvent(
              id: const Uuid().v4(),
              babyId: babyId,
              type: EventType.feed,
              startTime: startTime,
              endTime: DateTime.now(),
              feedType: FeedType.breast,
              feedSide: feedSide,
              durationMinutes: DateTime.now().difference(startTime).inMinutes,
            );
            eventProvider.addEvent(event);
          }
        },
        onStopNursing: (endTime, feedSide, {startTime}) {
          eventProvider.stopFeedTimer(babyId, endTime: endTime, feedSide: feedSide, startTime: startTime);
        },
        onLogFeed: (event) {
          final completeEvent = event.copyWith(
            id: const Uuid().v4(),
            babyId: babyId,
          );
          eventProvider.addEvent(completeEvent);
        },
        onTimerFeedSideChanged: (feedSide) {
          eventProvider.updateTimerFeedSide(babyId, feedSide);
        },
      ),
    );
  }

  void _showDiaperSheet(BuildContext context, EventProvider eventProvider,
      String babyId, {required bool defaultPee, bool defaultPoop = false}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiaperSheet(
        defaultPee: defaultPee,
        defaultPoop: defaultPoop,
        onLogDiaper: (event) {
          final completeEvent = event.copyWith(
            id: const Uuid().v4(),
            babyId: babyId,
          );
          eventProvider.addEvent(completeEvent);
        },
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
            onStopNursing: (_, __, {startTime}) {},
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

  Widget _buildBugReportLink(BuildContext context) {
    final tr = context.watch<LocaleProvider>().strings;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const BugReportSheet(),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bug_report_outlined,
                size: 16, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(
              tr.reportBugHome,
              style: TextStyle(
                color: AppColors.error.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCtaBanner(BuildContext context) {
    final tr = context.watch<LocaleProvider>().strings;
    final isPro = context.watch<SubscriptionProvider>().isPro;
    final notificationsEnabled = context.watch<NotificationProvider>().permissionGranted;
    return GestureDetector(
      onTap: () {
        if (!isPro) {
          PaywallService.present(
            context,
            trigger: PaywallTriggerPoint.homeBanner,
          );
        } else if (!notificationsEnabled) {
          context.read<NotificationProvider>().requestPermission();
        } else {
          NotificationSettingsModal.show(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.sleepPurple.withValues(alpha: 0.15),
              AppColors.sleepPurple.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.sleepPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.sleepPurple.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.sleepPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.enableSmartNotifications,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr.homeNotificationCtaDesc,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.sleepPurple.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, EventProvider eventProvider, BabyEvent event) {
    final tr = context.read<LocaleProvider>().strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.deleteEvent),
        content: Text(tr.removeEventLog(event.typeLabel.toLowerCase())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () {
              eventProvider.removeEvent(event.babyId, event.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
  }
}

DateTime? _lastWakeUpTime(EventProvider eventProvider, String babyId) {
  final activeSleep = eventProvider.activeSleepTimer;
  if (activeSleep != null) return null;

  final events = eventProvider.getEvents(babyId);
  final sleeps = events
      .where((e) => e.type == EventType.sleep && e.endTime != null)
      .toList()
    ..sort((a, b) => b.endTime!.compareTo(a.endTime!));

  if (sleeps.isEmpty) return null;
  return sleeps.first.endTime;
}

class _SleepWindowBatteryWidget extends StatelessWidget {
  final int ageMonths;
  final DateTime? lastWakeUp;
  final bool isSleeping;

  const _SleepWindowBatteryWidget({
    required this.ageMonths,
    this.lastWakeUp,
    required this.isSleeping,
  });

  @override
  Widget build(BuildContext context) {
    final calc = SleepBatteryCalculator(
      ageMonths: ageMonths,
      lastWakeUp: lastWakeUp,
      isCurrentlySleeping: isSleeping,
    );
    return SleepWindowBattery(calculator: calc);
  }
}

class _PredictionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int confidence;
  final VoidCallback? onTap;

  const _PredictionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.confidence,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<LocaleProvider>().strings;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (confidence > 0) ...[
              const SizedBox(height: 2),
              Text(
                tr.percentConfidence(confidence),
                style: TextStyle(
                  color: AppColors.textTertiary.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
