import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/baby.dart';
import '../models/event.dart';
import '../providers/baby_provider.dart';
import '../providers/event_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/navigation_service.dart';
import '../services/purchase_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../utils/prediction_engine.dart';
import '../utils/strings.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = context.watch<BabyProvider>();
    final eventProvider = context.watch<EventProvider>();
    final baby = babyProvider.currentBaby;
    final strings = context.read<LocaleProvider>().strings;
    final isPro = context.watch<SubscriptionProvider>().isPro;

    if (baby == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.analytics)),
        body: Center(child: Text(strings.noBabyProfile)),
      );
    }

    if (!isPro) {
      return _buildProGate(context, baby, eventProvider, strings);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.analytics),
        leading: GestureDetector(
          onTap: () => NavigationService.goToHome(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.sleepPurple,
            labelColor: AppColors.sleepPurple,
            unselectedLabelColor: AppColors.textTertiary,
            tabs: [
              Tab(icon: Icon(Icons.bedtime_outlined), text: strings.sleep),
              Tab(icon: Icon(Icons.local_dining_outlined), text: strings.feed),
              Tab(icon: Icon(Icons.cleaning_services_outlined), text: strings.diaper),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SleepTab(baby: baby, eventProvider: eventProvider, days: _selectedDays),
                _FeedTab(baby: baby, eventProvider: eventProvider, days: _selectedDays),
                _DiaperTab(baby: baby, eventProvider: eventProvider, days: _selectedDays),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProGate(BuildContext context, Baby baby, EventProvider eventProvider, Strings strings) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.analytics),
        leading: GestureDetector(
          onTap: () => NavigationService.goToHome(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    _buildPeriodSelector(),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.sleepPurple,
                      labelColor: AppColors.sleepPurple,
                      unselectedLabelColor: AppColors.textTertiary,
                      tabs: [
                        Tab(icon: Icon(Icons.bedtime_outlined), text: strings.sleep),
                        Tab(icon: Icon(Icons.local_dining_outlined), text: strings.feed),
                        Tab(icon: Icon(Icons.cleaning_services_outlined), text: strings.diaper),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _SleepTab(baby: baby, eventProvider: eventProvider, days: _selectedDays),
                          _FeedTab(baby: baby, eventProvider: eventProvider, days: _selectedDays),
                          _DiaperTab(baby: baby, eventProvider: eventProvider, days: _selectedDays),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: _buildProOverlayCard(context, strings),
          ),
        ],
      ),
    );
  }

  Widget _buildProOverlayCard(BuildContext context, Strings strings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.sleepPurple.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.sleepPurple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.sleepPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.unlockInsights,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.unlockInsightsDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _openPaywall(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sleepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                strings.upgradeToPro,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaywall(BuildContext context) async {
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        PurchaseService.proEntitlementId,
        displayCloseButton: true,
      );
      if (!context.mounted) return;
      if (result == PaywallResult.purchased || result == PaywallResult.restored) {
        context.read<SubscriptionProvider>().refresh();
      }
    } catch (e) {
      debugPrint('[InsightsScreen] Paywall error: $e');
    }
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final days in [7, 14, 30])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$days d'),
                selected: _selectedDays == days,
                selectedColor: AppColors.sleepPurple.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _selectedDays == days
                      ? AppColors.sleepPurple
                      : AppColors.textSecondary,
                  fontWeight:
                      _selectedDays == days ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: _selectedDays == days
                      ? AppColors.sleepPurple
                      : AppColors.cardBorder.withValues(alpha: 0.3),
                ),
                backgroundColor: Colors.transparent,
                onSelected: (_) => setState(() => _selectedDays = days),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sleep Tab
// ---------------------------------------------------------------------------
class _SleepTab extends StatelessWidget {
  final Baby baby;
  final EventProvider eventProvider;
  final int days;

  const _SleepTab({
    required this.baby,
    required this.eventProvider,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final sleepHours =
        eventProvider.getSleepHoursPerDay(baby.id, days: days);
    final avgSleep = eventProvider.getAverageSleepPerDay(baby.id, days: days);
    final todaySleep = eventProvider.getTotalSleepToday(baby.id);
    final nextNap = eventProvider.predictNextNap(baby.id);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final sleepEvents = eventProvider
        .getSleepEvents(baby.id)
        .where((e) => e.endTime != null && e.startTime.isAfter(cutoff))
        .toList();
    final avgNapCount =
        sleepEvents.isEmpty ? 0 : sleepEvents.length / days;
    final strings = context.read<LocaleProvider>().strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryRow(context, [
            _MetricData(
              icon: Icons.bedtime_outlined,
              label: strings.avgSleepPerDay,
              value: '${avgSleep.toStringAsFixed(1)}h',
              color: AppColors.sleepPurple,
            ),
            _MetricData(
              icon: Icons.water_drop_outlined,
              label: strings.todayLabel,
              value: '${todaySleep.toStringAsFixed(1)}h',
              color: AppColors.diaperTeal,
            ),
            _MetricData(
              icon: Icons.nightlight_round,
              label: strings.avgNapsPerDay,
              value: avgNapCount.toStringAsFixed(1),
              color: AppColors.wakeYellow,
            ),
          ]),
          const SizedBox(height: 16),
          _buildSleepChart(context, sleepHours, avgSleep, baby.ageInMonths),
          const SizedBox(height: 16),
          _buildAgeComparison(context, baby.ageInMonths, avgSleep),
          const SizedBox(height: 16),
          _buildPredictionCard(context, nextNap, strings.nextNapLabel,
              Icons.nightlight_round, AppColors.sleepPurple),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSleepChart(BuildContext context,
      Map<DateTime, double> sleepHours, double avgSleep, int ageMonths) {
    final entries = sleepHours.entries.toList();
    final maxSleep = entries.fold<double>(
        0, (max, e) => e.value > max ? e.value : max);
    final chartMax = (maxSleep < 24 ? 24 : maxSleep).ceilToDouble();
    final strings = context.read<LocaleProvider>().strings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.sleepHours,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                strings.avgLabel('${avgSleep.toStringAsFixed(1)}h'),
                style: const TextStyle(
                    color: AppColors.sleepPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.cardDark,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = entries[group.x.toInt()].key;
                      return BarTooltipItem(
                        '${AppDateUtils.formatDate(day)}\n${rod.toY.toStringAsFixed(1)}h',
                        const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final day = entries[value.toInt()].key;
                        return Text(
                          DateFormat('E').format(day).substring(0, 2),
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 6,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.cardBorder.withValues(alpha: 0.2),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: AppColors.sleepPurple,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: chartMax,
                          color: AppColors.sleepPurple.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14,
                  color: AppColors.textTertiary.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                strings.recommendedSleepFor(baby.ageInMonths, _recommendedSleep(baby.ageInMonths)),
                style: TextStyle(
                    color: AppColors.textTertiary.withValues(alpha: 0.7),
                    fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgeComparison(
      BuildContext context, int ageMonths, double avgSleep) {
    final recommended = _recommendedSleep(ageMonths);
    final diff = avgSleep - recommended;
    final isGood = diff.abs() < 2;
    final strings = context.read<LocaleProvider>().strings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isGood ? AppColors.diaperTeal : AppColors.wakeYellow)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGood ? Icons.check_circle_outline : Icons.info_outline,
              color: isGood ? AppColors.diaperTeal : AppColors.wakeYellow,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.vsRecommendedSleep,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  isGood
                      ? strings.sleepingWell(recommended, ageMonths)
                      : strings.sleepingOff(avgSleep, recommended, ageMonths),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(BuildContext context, PredictionResult prediction,
      String label, IconData icon, Color color) {
    final strings = context.read<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  prediction.timeUntilLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (prediction.confidencePercent > 0)
                  Text(strings.confidence(prediction.confidencePercent),
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _recommendedSleep(int ageMonths) {
    if (ageMonths < 1) return 16;
    if (ageMonths < 3) return 15;
    if (ageMonths < 6) return 14;
    if (ageMonths < 12) return 13;
    if (ageMonths < 24) return 12;
    return 11;
  }
}

// ---------------------------------------------------------------------------
// Feed Tab
// ---------------------------------------------------------------------------
class _FeedTab extends StatelessWidget {
  final Baby baby;
  final EventProvider eventProvider;
  final int days;

  const _FeedTab({
    required this.baby,
    required this.eventProvider,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final feedCount = eventProvider.getFeedCountByDay(baby.id, days: days);
    final avgFeeds = eventProvider.getAverageFeedsPerDay(baby.id, days: days);
    final avgInterval =
        eventProvider.getAverageFeedInterval(baby.id, days: days);
    final breastRatio = eventProvider.getBreastFeedRatio(baby.id, days: days);
    final sideDist =
        eventProvider.getFeedSideDistribution(baby.id, days: days);
    final nextFeed = eventProvider.predictNextFeed(baby.id);
    final volumeByDay =
        eventProvider.getFeedVolumeByDay(baby.id, days: days);
    final hasVolume = volumeByDay.values.any((v) => v > 0);
    final strings = context.read<LocaleProvider>().strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryRow(context, [
            _MetricData(
              icon: Icons.repeat_outlined,
              label: strings.avgFeedsPerDay,
              value: avgFeeds.toStringAsFixed(1),
              color: AppColors.feedOrange,
            ),
            _MetricData(
              icon: Icons.timer_outlined,
              label: strings.avgInterval,
              value: avgInterval > 0 ? '${avgInterval.round()}min' : '--',
              color: AppColors.wakeYellow,
            ),
            _MetricData(
              icon: Icons.balance_outlined,
              label: strings.breast,
              value: '${(breastRatio * 100).round()}%',
              color: AppColors.feedOrange,
            ),
          ]),
          const SizedBox(height: 16),
          _buildFeedCountChart(context, feedCount, avgFeeds),
          const SizedBox(height: 16),
          if (hasVolume) ...[
            _buildVolumeChart(context, volumeByDay),
            const SizedBox(height: 16),
          ],
          _buildSideDistribution(context, sideDist),
          const SizedBox(height: 16),
          _buildPredictionCard(context, nextFeed, strings.nextFeedLabel,
              Icons.local_dining_outlined, AppColors.feedOrange),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFeedCountChart(
      BuildContext context, Map<DateTime, int> feedCount, double avg) {
    final entries = feedCount.entries.toList();
    final maxCount = entries.fold<int>(0, (max, e) => e.value > max ? e.value : max);
    final chartMax = (maxCount < 8 ? 8 : maxCount).toDouble();
    final strings = context.read<LocaleProvider>().strings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.feedsPerDay,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                strings.avgLabel(avg.toStringAsFixed(1)),
                style: const TextStyle(
                    color: AppColors.feedOrange,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.cardDark,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = entries[group.x.toInt()].key;
                      return BarTooltipItem(
                        '${AppDateUtils.formatDate(day)}\n${strings.feedsCount(rod.toY.toInt())}',
                        const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final day = entries[value.toInt()].key;
                        return Text(
                          DateFormat('E').format(day).substring(0, 2),
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 2,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.cardBorder.withValues(alpha: 0.2),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: AppColors.feedOrange,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: chartMax,
                          color: AppColors.feedOrange.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeChart(
      BuildContext context, Map<DateTime, int> volumeByDay) {
    final entries = volumeByDay.entries.toList();
    final maxVol = entries.fold<int>(0, (max, e) => e.value > max ? e.value : max);
    final strings = context.read<LocaleProvider>().strings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.milkVolumePerDay,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxVol < 200 ? 200 : maxVol).toDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.cardDark,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = entries[group.x.toInt()].key;
                      return BarTooltipItem(
                        '${AppDateUtils.formatDate(day)}\n${rod.toY.toInt()}ml',
                        const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('E').format(entries[value.toInt()].key).substring(0, 2),
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}ml',
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.cardBorder.withValues(alpha: 0.2),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: AppColors.wakeYellow,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: (maxVol < 200 ? 200 : maxVol).toDouble(),
                          color: AppColors.wakeYellow.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideDistribution(
      BuildContext context, Map<FeedSide, int> sides) {
    final total = sides.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final strings = context.read<LocaleProvider>().strings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.breastfeedingSideDistribution,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSideItem(context, strings.left, sides[FeedSide.left] ?? 0, total,
                  AppColors.feedOrange),
              const SizedBox(width: 12),
              _buildSideItem(context, strings.right, sides[FeedSide.right] ?? 0,
                  total, AppColors.wakeYellow),
              const SizedBox(width: 12),
              _buildSideItem(context, strings.both, sides[FeedSide.both] ?? 0, total,
                  AppColors.sleepPurple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideItem(BuildContext context, String label, int count,
      int total, Color color) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    final strings = context.read<LocaleProvider>().strings;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$pct%',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
            Text(strings.feedsCount(count),
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(BuildContext context, PredictionResult prediction,
      String label, IconData icon, Color color) {
    final strings = context.read<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  prediction.timeUntilLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (prediction.confidencePercent > 0)
                  Text(strings.confidence(prediction.confidencePercent),
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diaper Tab
// ---------------------------------------------------------------------------
class _DiaperTab extends StatelessWidget {
  final Baby baby;
  final EventProvider eventProvider;
  final int days;

  const _DiaperTab({
    required this.baby,
    required this.eventProvider,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final diaperCount =
        eventProvider.getDiaperCountByDay(baby.id, days: days);
    final avgDiapers =
        eventProvider.getAverageDiapersPerDay(baby.id, days: days);
    final totalDiapers =
        eventProvider.getTotalDiaperChanges(baby.id, days: days);
    final breakdown = eventProvider.getPeePoopBreakdown(baby.id, days: days);
    final textures =
        eventProvider.getDiaperTextureDistribution(baby.id, days: days);
    final nextDiaper = eventProvider.predictNextDiaper(baby.id);
    final strings = context.read<LocaleProvider>().strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryRow(context, [
            _MetricData(
              icon: Icons.cleaning_services_outlined,
              label: strings.avgDiapersPerDay,
              value: avgDiapers.toStringAsFixed(1),
              color: AppColors.diaperTeal,
            ),
            _MetricData(
              icon: Icons.numbers_outlined,
              label: strings.totalDays(days),
              value: '$totalDiapers',
              color: AppColors.sleepPurple,
            ),
            _MetricData(
              icon: Icons.water_drop_outlined,
              label: strings.peeOnly,
              value: '${breakdown.$1}',
              color: AppColors.wakeYellow,
            ),
          ]),
          const SizedBox(height: 16),
          _buildDiaperCountChart(context, diaperCount, avgDiapers),
          const SizedBox(height: 16),
          _buildPeePoopBreakdown(context, breakdown),
          const SizedBox(height: 16),
          if (textures.isNotEmpty) ...[
            _buildTextureDistribution(context, textures),
            const SizedBox(height: 16),
          ],
          _buildPredictionCard(context, nextDiaper, strings.nextDiaperLabel,
              Icons.cleaning_services_outlined, AppColors.diaperTeal),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDiaperCountChart(
      BuildContext context, Map<DateTime, int> diaperCount, double avg) {
    final entries = diaperCount.entries.toList();
    final maxCount = entries.fold<int>(0, (max, e) => e.value > max ? e.value : max);
    final chartMax = (maxCount < 8 ? 8 : maxCount).toDouble();
    final strings = context.read<LocaleProvider>().strings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.diaperChangesPerDay,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                strings.avgLabel(avg.toStringAsFixed(1)),
                style: const TextStyle(
                    color: AppColors.diaperTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.cardDark,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = entries[group.x.toInt()].key;
                      return BarTooltipItem(
                        '${AppDateUtils.formatDate(day)}\n${strings.changesCount(rod.toY.toInt())}',
                        const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final day = entries[value.toInt()].key;
                        return Text(
                          DateFormat('E').format(day).substring(0, 2),
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 2,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.cardBorder.withValues(alpha: 0.2),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: AppColors.diaperTeal,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: chartMax,
                          color: AppColors.diaperTeal.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeePoopBreakdown(
      BuildContext context, (int, int, int) breakdown) {
    final pee = breakdown.$1;
    final poop = breakdown.$2;
    final both = breakdown.$3;
    final total = pee + poop + both;
    if (total == 0) return const SizedBox.shrink();
    final strings = context.read<LocaleProvider>().strings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.peeVsPoopBreakdown,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  if (pee > 0)
                    Expanded(
                      flex: pee,
                      child: Container(
                        color: AppColors.wakeYellow.withValues(alpha: 0.7),
                        child: Center(
                          child: Text(
                            strings.peePercent((pee / total * 100).round()),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  if (both > 0)
                    Expanded(
                      flex: both,
                      child: Container(
                        color: AppColors.sleepPurple.withValues(alpha: 0.7),
                        child: Center(
                          child: Text(
                            strings.bothPercent((both / total * 100).round()),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  if (poop > 0)
                    Expanded(
                      flex: poop,
                      child: Container(
                        color: AppColors.diaperTeal.withValues(alpha: 0.7),
                        child: Center(
                          child: Text(
                            strings.poopPercent((poop / total * 100).round()),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendDot(AppColors.wakeYellow, strings.peeOnlyLabel(pee)),
              _legendDot(AppColors.sleepPurple, strings.bothLabel(both)),
              _legendDot(AppColors.diaperTeal, strings.poopOnlyLabel(poop)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textTertiary, fontSize: 10)),
      ],
    );
  }

  Widget _buildTextureDistribution(
      BuildContext context, Map<DiaperTexture, int> textures) {
    if (textures.values.every((v) => v == 0)) return const SizedBox.shrink();
    final total = textures.values.fold(0, (a, b) => a + b);
    final strings = context.read<LocaleProvider>().strings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.stoolTexture,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...textures.entries.map((e) {
            final pct = total > 0 ? (e.value / total * 100).round() : 0;
            final label = _textureLabel(e.key, strings);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13)),
                      Text('${e.value} ($pct%)',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? e.value / total : 0,
                      backgroundColor:
                          AppColors.cardBorder.withValues(alpha: 0.2),
                      color: AppColors.diaperTeal,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _textureLabel(DiaperTexture t, Strings strings) {
    switch (t) {
      case DiaperTexture.normal:
        return strings.normal;
      case DiaperTexture.soft:
        return strings.soft;
      case DiaperTexture.liquid:
        return strings.liquid;
      case DiaperTexture.dry:
        return strings.dry;
    }
  }

  Widget _buildPredictionCard(BuildContext context, PredictionResult prediction,
      String label, IconData icon, Color color) {
    final strings = context.read<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  prediction.timeUntilLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (prediction.confidencePercent > 0)
                  Text(strings.confidence(prediction.confidencePercent),
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _MetricData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

Widget _buildSummaryRow(BuildContext context, List<_MetricData> metrics) {
  return Row(
    children: metrics.map((m) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(m.icon, size: 18, color: m.color),
                const SizedBox(height: 6),
                Text(
                  m.value,
                  style: TextStyle(
                    color: m.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  m.label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}
