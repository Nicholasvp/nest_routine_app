import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/baby_tip.dart';
import '../providers/baby_provider.dart';
import '../providers/locale_provider.dart';
import '../services/baby_tips_service.dart';
import '../theme/app_colors.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final Map<String, Future<List<BabyTip>>> _requests = {};
  int? _selectedWeek;

  Future<List<BabyTip>> _load(int week, bool isPortuguese) {
    final key = '$week-${isPortuguese ? 'pt' : 'en'}';
    return _requests.putIfAbsent(
      key,
      () => BabyTipsService.loadForWeek(week, isPortuguese: isPortuguese),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baby = context.watch<BabyProvider>().currentBaby;
    final locale = context.watch<LocaleProvider>();
    final strings = locale.strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.tipsTitle)),
      body: baby == null
          ? Center(child: Text(strings.noBabyProfile))
          : _buildTips(context, baby.dateOfBirth, locale.isPortuguese),
    );
  }

  Widget _buildTips(BuildContext context, DateTime dateOfBirth, bool isPt) {
    final strings = context.read<LocaleProvider>().strings;
    final ageDays = DateTime.now().difference(dateOfBirth).inDays;
    final currentWeek = ageDays < 0
        ? 1
        : (ageDays ~/ 7 + 1).clamp(1, 52).toInt();
    final week = _selectedWeek ?? currentWeek;

    final requestKey = '$week-${isPt ? 'pt' : 'en'}';
    return FutureBuilder<List<BabyTip>>(
      key: ValueKey(requestKey),
      future: _load(week, isPt),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.softLavender),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: AppColors.textTertiary,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.tipsLoadError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _requests.remove(requestKey)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(strings.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final tips = snapshot.data ?? const <BabyTip>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _WeekHeader(
              week: week,
              onWeekSelected: (selectedWeek) {
                setState(() => _selectedWeek = selectedWeek);
              },
            ),
            const SizedBox(height: 12),
            if (tips.isEmpty)
              _InfoCard(message: strings.tipsEmpty)
            else
              ...tips.map((tip) => _TipCard(tip: tip)),
            const SizedBox(height: 4),
            _InfoCard(message: strings.tipsDisclaimer),
          ],
        );
      },
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.week, required this.onWeekSelected});

  final int week;
  final ValueChanged<int> onWeekSelected;

  @override
  Widget build(BuildContext context) {
    final strings = context.read<LocaleProvider>().strings;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sleepPurple.withValues(alpha: 0.26),
            AppColors.cardDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.sleepPurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.sleepPurple.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.softLavender,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.weekOfLife(week),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.weeklyIdeasSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: strings.weekOfLife(week),
            onPressed: () => _showWeekPicker(context),
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.softLavender,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showWeekPicker(BuildContext context) async {
    final strings = context.read<LocaleProvider>().strings;
    var candidateWeek = week;
    final pickerController = FixedExtentScrollController(initialItem: week - 1);
    final selectedWeek = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: 330,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(strings.cancel),
                    ),
                    const Spacer(),
                    Text(
                      strings.monthOfLife(_monthForWeek(candidateWeek)),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, candidateWeek),
                      child: Text(strings.save),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setPickerState) => CupertinoPicker(
                    scrollController: pickerController,
                    itemExtent: 48,
                    useMagnifier: true,
                    magnification: 1.08,
                    onSelectedItemChanged: (index) {
                      candidateWeek = index + 1;
                      setPickerState(() {});
                    },
                    children: [
                      for (var item = 1; item <= 52; item++)
                        _WeekPickerItem(week: item),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    pickerController.dispose();
    if (selectedWeek != null) onWeekSelected(selectedWeek);
  }

  int _monthForWeek(int week) => ((week - 1) * 12 ~/ 52) + 1;
}

class _WeekPickerItem extends StatelessWidget {
  const _WeekPickerItem({required this.week});

  final int week;

  @override
  Widget build(BuildContext context) {
    final strings = context.read<LocaleProvider>().strings;
    final month = ((week - 1) * 12 ~/ 52) + 1;
    final isFirstWeekOfMonth =
        week == 1 || (((week - 2) * 12 ~/ 52) + 1) != month;
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: isFirstWeekOfMonth
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    strings.monthOfLife(month),
                    style: const TextStyle(
                      color: AppColors.softLavender,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            strings.weekOfLife(week),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final BabyTip tip;

  IconData get _icon => switch (tip.category) {
    'movement' => Icons.accessibility_new_rounded,
    'communication' => Icons.forum_outlined,
    'oral_health' => Icons.health_and_safety_outlined,
    'safety' => Icons.shield_outlined,
    'caregiver' => Icons.favorite_border_rounded,
    _ => Icons.toys_outlined,
  };

  Color get _color => switch (tip.category) {
    'movement' => AppColors.sleepPurple,
    'communication' => AppColors.softLavender,
    'oral_health' => AppColors.diaperTeal,
    'safety' => AppColors.wakeYellow,
    'caregiver' => AppColors.feedOrange,
    _ => AppColors.diaperMint,
  };

  @override
  Widget build(BuildContext context) {
    final strings = context.read<LocaleProvider>().strings;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 19, color: _color),
              const SizedBox(width: 8),
              Text(
                strings.tipCategory(tip.category),
                style: TextStyle(
                  color: _color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tip.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            tip.body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (tip.activity != null && tip.activity!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.tryThis,
                    style: TextStyle(
                      color: _color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.activity!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(tip.sourceUrl);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: Text('${strings.source}: ${tip.sourceName}'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
                textStyle: const TextStyle(fontSize: 11),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardDark.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      message,
      style: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 12,
        height: 1.5,
      ),
    ),
  );
}
