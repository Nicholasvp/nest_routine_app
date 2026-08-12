import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import '../theme/app_colors.dart';
import 'analytics_service.dart';

class ReviewService {
  static late Box _settingsBox;
  static bool _isShowing = false;

  static Future<void> init() async {
    _settingsBox = Hive.box('settings');
  }

  static bool get _reviewed =>
      _settingsBox.get('review_reviewed', defaultValue: false) as bool;

  static int get _promptCount =>
      _settingsBox.get('review_prompt_count', defaultValue: 0) as int;

  static String? get _lastPromptDate =>
      _settingsBox.get('review_last_prompt_date') as String?;

  static int get _totalEventsAtLastPrompt =>
      _settingsBox.get('review_total_events_at_last_prompt', defaultValue: 0) as int;

  static int get _declinedCount =>
      _settingsBox.get('review_declined_count', defaultValue: 0) as int;

  static Future<void> _save(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static bool shouldShowPrompt(int totalEvents) {
    if (_reviewed) return false;
    if (_isShowing) return false;

    if (_promptCount == 0) {
      return totalEvents >= 1;
    }

    if (_declinedCount >= 3) return false;

    final lastDate = _lastPromptDate;
    if (lastDate != null) {
      final last = DateTime.parse(lastDate);
      final daysSince = DateTime.now().difference(last).inDays;
      if (daysSince < 3) return false;
    }

    final eventsSinceLast = totalEvents - _totalEventsAtLastPrompt;
    if (eventsSinceLast < 5) return false;

    return true;
  }

  static Future<void> showReviewPrompt(
    BuildContext context, {
    required int totalEvents,
    required AnalyticsService analytics,
  }) async {
    if (!shouldShowPrompt(totalEvents)) return;

    _isShowing = true;
    await _save('review_prompt_count', _promptCount + 1);
    await _save('review_last_prompt_date', DateTime.now().toIso8601String());
    await _save('review_total_events_at_last_prompt', totalEvents);

    analytics.log('review_prompt_shown', 'engagement', properties: {
      'total_events': totalEvents,
      'prompt_count': _promptCount,
    });

    if (!context.mounted) {
      _isShowing = false;
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ReviewModal(
        onAccept: () async {
          Navigator.of(context).pop();
          await _save('review_reviewed', true);
          analytics.log('review_prompt_accepted', 'engagement');
          final inAppReview = InAppReview.instance;
          if (await inAppReview.isAvailable()) {
            await inAppReview.requestReview();
          }
          _isShowing = false;
        },
        onDecline: () {
          Navigator.of(context).pop();
          _save('review_declined_count', _declinedCount + 1);
          analytics.log('review_prompt_dismissed', 'engagement');
          _isShowing = false;
        },
      ),
    );

    _isShowing = false;
  }

  static Future<void> requestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }
}

class _ReviewModal extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _ReviewModal({
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.sleepPurple.withValues(alpha: 0.3),
          ),
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
                Icons.star_rounded,
                color: AppColors.sleepPurple,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enjoying NestRoutine?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your review helps other parents discover NestRoutine!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.star_rounded, size: 20),
                label: const Text(
                  'Rate NestRoutine',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sleepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onDecline,
              child: Text(
                'Not now',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
