import 'dart:ui';

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
import '../utils/sleep_routine.dart';
import '../utils/date_utils.dart';
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
  const HomeScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _homeViewportKey = GlobalKey();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  bool _loadingSleepRoutine = false;
  bool _isScrolled = false;
  bool _isHomeActive = true;
  int _revealGeneration = 0;
  bool _timelineVisible = false;
  bool _timelineHasActiveSleep = false;
  bool _pulseRunning = false;
  bool _pulseSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    _isHomeActive = widget.isActive;
    _scrollController.addListener(_handleScroll);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    _isHomeActive = widget.isActive;
    _schedulePulseSync();
  }

  void _handleScroll() {
    final isScrolled = _scrollController.offset > 24;
    if (isScrolled != _isScrolled && mounted) {
      setState(() => _isScrolled = isScrolled);
    }
  }

  void _onTimelineVisibilityChanged(bool visible) {
    _timelineVisible = visible;
    _schedulePulseSync();
  }

  void _schedulePulseSync() {
    if (_pulseSyncScheduled) return;
    _pulseSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pulseSyncScheduled = false;
      if (!mounted) return;
      final shouldRun =
          _isHomeActive && _timelineVisible && _timelineHasActiveSleep;
      if (shouldRun == _pulseRunning) return;
      _pulseRunning = shouldRun;
      if (shouldRun) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    });
  }

  Widget _revealOnScroll(
    Widget child, {
    ValueChanged<bool>? onVisibilityChanged,
  }) => _ScrollReveal(
    scrollController: _scrollController,
    viewportKey: _homeViewportKey,
    isPageActive: _isHomeActive,
    generation: _revealGeneration,
    onVisibilityChanged: onVisibilityChanged,
    child: child,
  );

  Future<void> _onRefresh(
    BabyProvider babyProvider,
    EventProvider eventProvider,
  ) async {
    final baby = babyProvider.currentBaby;
    if (baby != null) {
      eventProvider.loadEvents(baby.id);
      await eventProvider.loadEventsFromCloud(baby.id);
    }
    await babyProvider.loadBabiesFromCloud();
    if (!mounted) return;
    setState(() => _revealGeneration++);
    _pulseRunning = false;
    _pulseController
      ..stop()
      ..value = 0;
    _schedulePulseSync();
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
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
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
              Icon(
                Icons.baby_changing_station_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
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
    final notificationsEnabled = context
        .watch<NotificationProvider>()
        .permissionGranted;
    final settings = context.watch<NotificationProvider>().settings;
    final hasAnySmartNotification =
        settings.sleepEnabled ||
        settings.diaperPeeEnabled ||
        settings.diaperPoopEnabled;
    debugPrint(
      '[HomeScreen] isPro=$isPro, notificationsEnabled=$notificationsEnabled, sleep=${settings.sleepEnabled}, diaperPee=${settings.diaperPeeEnabled}, diaperPoop=${settings.diaperPoopEnabled}, hasAnySmart=$hasAnySmartNotification, shouldShow=${!isPro || !notificationsEnabled || !hasAnySmartNotification}',
    );
    final todayEvents = eventProvider.getTodayEvents(baby.id);
    final activeSleep = eventProvider.activeSleepTimer;
    _timelineHasActiveSleep = activeSleep != null;
    _schedulePulseSync();
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
                  key: _homeViewportKey,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  controller: _scrollController,
                  child: Column(
                    children: [
                      _revealOnScroll(
                        _buildTimelineSection(
                          context,
                          eventProvider,
                          todayEvents,
                          activeSleep,
                        ),
                        onVisibilityChanged: _onTimelineVisibilityChanged,
                      ),
                      const SizedBox(height: 24),
                      _revealOnScroll(
                        _buildPredictionCards(
                          context,
                          nextNap,
                          nextFeed,
                          nextDiaper,
                          totalSleep,
                          onNapTap: () => _showSleepSheet(
                            context,
                            eventProvider,
                            activeSleep,
                          ),
                          onFeedTap: () =>
                              _showFeedSheet(context, eventProvider, baby.id),
                          onDiaperTap: () => _showDiaperSheet(
                            context,
                            eventProvider,
                            baby.id,
                            defaultPee: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!isPro ||
                          !notificationsEnabled ||
                          !hasAnySmartNotification) ...[
                        _revealOnScroll(_buildNotificationCtaBanner(context)),
                        const SizedBox(height: 12),
                      ],
                      _revealOnScroll(
                        _SleepWindowBatteryWidget(
                          ageMonths: baby.ageInMonths,
                          lastWakeUp: lastWakeUp,
                          isSleeping: activeSleep != null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _revealOnScroll(
                          _buildSleepRoutineShortcut(
                            context,
                            eventProvider,
                            baby.id,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _revealOnScroll(
                        _buildQuickActionSection(
                          context,
                          eventProvider,
                          baby.id,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _revealOnScroll(
                        _buildRecentEvents(
                          context,
                          eventProvider,
                          baby.id,
                          todayEvents,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _revealOnScroll(_buildBugReportLink(context)),
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
    BuildContext context,
    BabyProvider babyProvider,
    String name,
  ) {
    final tr = context.watch<LocaleProvider>().strings;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(
        20,
        _isScrolled ? 6 : 12,
        20,
        _isScrolled ? 4 : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: SizedBox(
                  height: _isScrolled ? 0 : null,
                  child: ClipRect(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: _isScrolled ? 0 : 1,
                      child: Text(
                        tr.hiThere,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: _isScrolled ? 18 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => NavigationService.goToProfile(),
            child: AnimatedRotation(
              turns: _isScrolled ? 0.025 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
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
              onTap: () => _showSleepSheet(context, eventProvider, activeSleep),
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
    BuildContext context,
    EventProvider eventProvider,
    String babyId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: QuickActionBar(
        isSleeping: eventProvider.activeSleepTimer != null,
        isFeeding: eventProvider.activeFeedTimer != null,
        onSleep: () => _showSleepSheet(
          context,
          eventProvider,
          eventProvider.activeSleepTimer,
        ),
        onFeed: () => _showFeedSheet(context, eventProvider, babyId),
        onPee: () =>
            _showDiaperSheet(context, eventProvider, babyId, defaultPee: true),
        onPoop: () => _showDiaperSheet(
          context,
          eventProvider,
          babyId,
          defaultPee: false,
          defaultPoop: true,
        ),
      ),
    );
  }

  Widget _buildRecentEvents(
    BuildContext context,
    EventProvider eventProvider,
    String babyId,
    List<BabyEvent> todayEvents,
  ) {
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                  Icon(
                    Icons.history_outlined,
                    size: 40,
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr.noEventsToday,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    tr.tapActionToStart,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recent.map(
            (event) => EventCard(
              event: event,
              onTap: () => _showEditEventSheet(context, eventProvider, event),
              onDelete: () => _confirmDelete(context, eventProvider, event),
            ),
          ),
      ],
    );
  }

  Widget _buildSleepRoutineShortcut(
    BuildContext context,
    EventProvider eventProvider,
    String babyId,
  ) {
    final strings = context.watch<LocaleProvider>().strings;
    const radius = 18.0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: _loadingSleepRoutine
            ? null
            : () => _showSleepRoutine(context, eventProvider, babyId),
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.sleepPurple.withValues(alpha: 0.18),
                AppColors.cardDark,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(radius),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _loadingSleepRoutine
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.softLavender,
                          ),
                        )
                      : const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.softLavender,
                          size: 23,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.seeMyRoutine,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.sleepRoutineShortcutDesc,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.softLavender,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepSheet(
    BuildContext context,
    EventProvider eventProvider,
    BabyEvent? activeTimer,
  ) {
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

  Future<void> _showSleepRoutine(
    BuildContext context,
    EventProvider eventProvider,
    String babyId,
  ) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final localEvents = eventProvider
        .getSleepEvents(babyId)
        .where(
          (event) =>
              event.endTime != null &&
              event.startTime.isAfter(cutoff) &&
              event.duration != null &&
              event.duration!.inMinutes > 0 &&
              event.duration!.inMinutes <= 12 * 60,
        )
        .toList();
    setState(() => _loadingSleepRoutine = true);
    List<BabyEvent>? cloudEvents;
    try {
      cloudEvents = await eventProvider.loadSleepEventsFromCloudSince(
        babyId,
        cutoff,
      );
    } finally {
      if (mounted) setState(() => _loadingSleepRoutine = false);
    }
    if (!mounted || !context.mounted) return;
    final events = (cloudEvents ?? localEvents)
        .where(
          (event) =>
              event.endTime != null &&
              event.duration != null &&
              event.duration!.inMinutes > 0 &&
              event.duration!.inMinutes <= 12 * 60,
        )
        .toList();
    final routine = findCommonSleepRoutine(events);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final strings = sheetContext.watch<LocaleProvider>().strings;
        final isPt = sheetContext.watch<LocaleProvider>().isPortuguese;
        final isPro = sheetContext.watch<SubscriptionProvider>().isPro;
        final routinePreview = routine.isEmpty
            ? Text(
                strings.needMoreSleepHistory,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: routine.indexed.map((entry) {
                  final index = entry.$1;
                  final item = entry.$2;
                  final minute = item.minuteOfDay;
                  final label = minute >= 18 * 60 || minute < 5 * 60
                      ? strings.nightSleep
                      : minute < 11 * 60
                      ? strings.morningNap
                      : minute < 16 * 60
                      ? strings.afternoonNap
                      : strings.eveningNap;
                  final time = DateTime(2000, 1, 1, minute ~/ 60, minute % 60);
                  final row = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bedtime_outlined,
                          color: AppColors.sleepPurple,
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          AppDateUtils.formatTimeAmPm(time, isPt: isPt),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                  if (!isPro && index > 0) {
                    return ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: row,
                    );
                  }
                  return row;
                }).toList(),
              );
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: const BoxDecoration(
            color: AppColors.darkPurple,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  strings.commonSleepRoutine,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  strings.basedOnSleepHistory,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                if (isPro)
                  routinePreview
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 72),
                          child: routinePreview,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.only(top: 18, bottom: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.darkPurple.withValues(alpha: 0),
                                  AppColors.darkPurple,
                                ],
                              ),
                            ),
                            child: Center(
                              child: FilledButton.icon(
                                onPressed: () => PaywallService.present(
                                  sheetContext,
                                  trigger: PaywallTriggerPoint.homeRoutineGate,
                                ),
                                icon: const Icon(Icons.lock_open_rounded),
                                label: Text(strings.unlock),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.sleepPurple,
                                  foregroundColor: AppColors.textPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFeedSheet(
    BuildContext context,
    EventProvider eventProvider,
    String babyId,
  ) {
    final activeFeed = eventProvider.activeFeedTimer;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedSheet(
        activeTimer: activeFeed,
        onStartNursing: (startTime, feedSide) {
          if (startTime.isAfter(
            DateTime.now().subtract(const Duration(minutes: 1)),
          )) {
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
          eventProvider.stopFeedTimer(
            babyId,
            endTime: endTime,
            feedSide: feedSide,
            startTime: startTime,
          );
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

  void _showDiaperSheet(
    BuildContext context,
    EventProvider eventProvider,
    String babyId, {
    required bool defaultPee,
    bool defaultPoop = false,
  }) {
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
    BuildContext context,
    EventProvider eventProvider,
    BabyEvent event,
  ) {
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
            onStartNursing: (_, _) {},
            onStopNursing: (_, _, {startTime}) {},
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
            Icon(
              Icons.bug_report_outlined,
              size: 16,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
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
    final notificationsEnabled = context
        .watch<NotificationProvider>()
        .permissionGranted;
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
    BuildContext context,
    EventProvider eventProvider,
    BabyEvent event,
  ) {
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
  }
}

class _ScrollReveal extends StatefulWidget {
  const _ScrollReveal({
    required this.scrollController,
    required this.viewportKey,
    required this.isPageActive,
    required this.generation,
    required this.child,
    this.onVisibilityChanged,
  });

  final ScrollController scrollController;
  final GlobalKey viewportKey;
  final bool isPageActive;
  final int generation;
  final Widget child;
  final ValueChanged<bool>? onVisibilityChanged;

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal>
    with SingleTickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey();
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  bool _isVisible = false;
  bool _checkScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    widget.scrollController.addListener(_scheduleVisibilityCheck);
    _scheduleVisibilityCheck();
  }

  @override
  void didUpdateWidget(_ScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation) {
      _isVisible = false;
      _controller.reset();
      _scheduleVisibilityCheck();
    }
    if (oldWidget.isPageActive != widget.isPageActive) {
      _scheduleVisibilityCheck();
    }
  }

  void _scheduleVisibilityCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (mounted) _updateVisibility();
    });
  }

  void _updateVisibility() {
    final childObject = _childKey.currentContext?.findRenderObject();
    final viewportObject =
        widget.viewportKey.currentContext?.findRenderObject();
    if (childObject is! RenderBox ||
        viewportObject is! RenderBox ||
        !childObject.hasSize ||
        !viewportObject.hasSize) {
      return;
    }

    final childRect = childObject.localToGlobal(Offset.zero) & childObject.size;
    final viewportRect =
        viewportObject.localToGlobal(Offset.zero) & viewportObject.size;
    final overlap = childRect.overlaps(viewportRect)
        ? childRect.intersect(viewportRect)
        : Rect.zero;
    final visibilityThreshold = (childRect.height * 0.2).clamp(24.0, 64.0);
    final isVisible =
        widget.isPageActive && overlap.height >= visibilityThreshold;
    if (isVisible == _isVisible) return;

    _isVisible = isVisible;
    widget.onVisibilityChanged?.call(isVisible);
    if (isVisible) {
      if (!_controller.isCompleted && !_controller.isAnimating) {
        _controller.forward();
      }
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scheduleVisibilityCheck);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: AnimatedBuilder(
      animation: _opacity,
      child: TickerMode(
        enabled: _isVisible && widget.isPageActive,
        child: KeyedSubtree(key: _childKey, child: widget.child),
      ),
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 10 * (1 - _opacity.value)),
        child: child,
      ),
    ),
  );
}

DateTime? _lastWakeUpTime(EventProvider eventProvider, String babyId) {
  final activeSleep = eventProvider.activeSleepTimer;
  if (activeSleep != null) return null;

  final events = eventProvider.getEvents(babyId);
  final sleeps =
      events
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
          border: Border.all(
            color: AppColors.cardBorder.withValues(alpha: 0.3),
          ),
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
