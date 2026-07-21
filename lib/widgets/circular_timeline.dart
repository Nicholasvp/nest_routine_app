import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';

class CircularTimeline extends StatelessWidget {
  final List<BabyEvent> todayEvents;
  final BabyEvent? activeSleep;
  final double? pulseScale;
  final VoidCallback? onTap;

  const CircularTimeline({
    super.key,
    required this.todayEvents,
    this.activeSleep,
    this.pulseScale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomPaint(
              painter: _TimelinePainter(
                todayEvents: todayEvents,
                activeSleep: activeSleep,
                now: DateTime.now(),
              ),
              child: Center(
                child: onTap != null
                    ? GestureDetector(
                        onTap: onTap,
                        behavior: HitTestBehavior.opaque,
                        child: _buildCenterContent(context),
                      )
                    : _buildCenterContent(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterContent(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    if (activeSleep != null) {
      final duration = DateTime.now().difference(activeSleep!.startTime);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: pulseScale ?? 1.0,
            child: const Icon(
              Icons.nightlight_round,
              color: AppColors.sleepPurple,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.sleeping,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.sleepPurple,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            AppDateUtils.formatDuration(duration),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.sleepPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.sleepPurple.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.sleepPurple,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  strings.tapToStopSleepTimer,
                  style: const TextStyle(
                    color: AppColors.sleepPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final awakeNow = DateTime.now();
    final lastSleep = todayEvents
        .where((e) =>
            e.type == EventType.sleep && e.endTime != null)
        .fold<BabyEvent?>(
          null,
          (prev, e) =>
              prev == null || e.endTime!.isAfter(prev.endTime!)
                  ? e
                  : prev,
        );

    if (lastSleep != null) {
      final awakeDuration = awakeNow.difference(lastSleep.endTime!);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wb_sunny_outlined,
            color: AppColors.wakeYellow,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            strings.awake_,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.wakeYellow,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            AppDateUtils.formatDuration(awakeDuration),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.wb_sunny_outlined,
          color: AppColors.wakeYellow.withValues(alpha: 0.5),
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          strings.goodMorning,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<BabyEvent> todayEvents;
  final BabyEvent? activeSleep;
  final DateTime now;

  _TimelinePainter({
    required this.todayEvents,
    this.activeSleep,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final innerRadius = radius * 0.72;

    _drawStarDots(canvas, size, center, radius);
    _drawClockRing(canvas, center, radius, innerRadius);
    _drawIdealSleepWindow(canvas, center, radius, innerRadius);
    _drawAwakeArcs(canvas, center, radius, innerRadius);

    final sleepEvents = todayEvents
        .where((e) => e.type == EventType.sleep)
        .toList();
    for (final event in sleepEvents) {
      _drawSleepArc(canvas, center, radius, innerRadius, event);
    }

    if (activeSleep != null) {
      _drawActiveSleepArc(canvas, center, radius, innerRadius, activeSleep!);
    }

    _drawPredictedSleepArc(canvas, center, radius, innerRadius);
    _drawEventDots(canvas, center, radius, innerRadius);
    _drawTimeMarkers(canvas, center, radius + 6);
    _drawNowIndicator(canvas, center, radius, innerRadius);
  }

  void _drawStarDots(Canvas canvas, Size size, Offset center, double radius) {
    final paint = Paint()
      ..color = AppColors.starColor.withValues(alpha: 0.3);
    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = random.nextDouble() * radius * 0.85;
      final x = center.dx + math.cos(angle) * dist;
      final y = center.dy + math.sin(angle) * dist;
      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 1.5 + 0.5,
        paint..color = paint.color.withValues(alpha: random.nextDouble() * 0.3),
      );
    }
  }

  void _drawClockRing(Canvas canvas, Offset center, double radius, double innerRadius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.cardBorder.withValues(alpha: 0.3);
    canvas.drawCircle(center, radius, paint);

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.cardBorder.withValues(alpha: 0.15);
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  void _drawAwakeArcs(Canvas canvas, Offset center, double radius,
      double innerRadius) {
    final completedSleeps = todayEvents
        .where((e) => e.type == EventType.sleep && e.endTime != null)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (completedSleeps.isEmpty) {
      _drawAwakeArc(canvas, center, radius, innerRadius,
          DateTime(now.year, now.month, now.day), now);
      return;
    }

    final midnight = DateTime(now.year, now.month, now.day);

    _drawAwakeArc(canvas, center, radius, innerRadius,
        midnight, completedSleeps.first.startTime);

    for (int i = 0; i < completedSleeps.length - 1; i++) {
      _drawAwakeArc(canvas, center, radius, innerRadius,
          completedSleeps[i].endTime!, completedSleeps[i + 1].startTime);
    }

    final lastEnd = completedSleeps.last.endTime!;
    final endOfAwake = activeSleep?.startTime ?? now;
    if (endOfAwake.isAfter(lastEnd)) {
      _drawAwakeArc(canvas, center, radius, innerRadius, lastEnd, endOfAwake);
    }
  }

  void _drawAwakeArc(Canvas canvas, Offset center, double radius,
      double innerRadius, DateTime from, DateTime to) {
    final startAngle = _timeToAngle(from) - math.pi / 2;
    final endAngle = _timeToAngle(to) - math.pi / 2;
    final sweepAngle = _normalizeAngle(endAngle - startAngle);

    if (sweepAngle < 0.01 || sweepAngle > 2 * math.pi - 0.01) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = AppColors.wakeYellow.withValues(alpha: 0.2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawIdealSleepWindow(
      Canvas canvas, Offset center, double radius, double innerRadius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = AppColors.sleepPurple.withValues(alpha: 0.08);
    final startAngle = -math.pi / 2 + (21 * 60 / (24 * 60)) * 2 * math.pi;
    final endAngle = -math.pi / 2 + (7 * 60 / (24 * 60)) * 2 * math.pi;
    final sweepAngle = endAngle > startAngle
        ? endAngle - startAngle
        : 2 * math.pi - startAngle + endAngle;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawSleepArc(Canvas canvas, Offset center, double radius,
      double innerRadius, BabyEvent event) {
    if (event.endTime == null) return;
    final startAngle = _timeToAngle(event.startTime) - math.pi / 2;
    final endAngle = _timeToAngle(event.endTime!) - math.pi / 2;
    final sweepAngle = _normalizeAngle(endAngle - startAngle);

    if (sweepAngle < 0.01) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = AppColors.sleepPurple.withValues(alpha: 0.3);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawActiveSleepArc(Canvas canvas, Offset center, double radius,
      double innerRadius, BabyEvent event) {
    final startAngle = _timeToAngle(event.startTime) - math.pi / 2;
    final nowAngle = _timeToAngle(now) - math.pi / 2;
    final sweepAngle = _normalizeAngle(nowAngle - startAngle);

    if (sweepAngle < 0.01) return;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = AppColors.sleepGlow.withValues(alpha: 0.4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          AppColors.sleepPurple,
          AppColors.sleepGlow,
          AppColors.sleepPurple.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawPredictedSleepArc(Canvas canvas, Offset center, double radius,
      double innerRadius) {
    final sleepEvents = todayEvents
        .where((e) => e.type == EventType.sleep && e.endTime != null)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (sleepEvents.isEmpty) return;

    final lastWakeUp = sleepEvents.first.endTime!;
    final awakeSince = now.difference(lastWakeUp).inMinutes;

    if (awakeSince < 30 || activeSleep != null) return;

    final predictedMinutes = (90 - awakeSince).clamp(15, 180);
    final predictedStart = now.add(Duration(minutes: 5));
    final predictedEnd =
        predictedStart.add(Duration(minutes: predictedMinutes));

    if (predictedEnd.hour >= 22 || predictedEnd.hour < 6) return;

    final startAngle = _timeToAngle(predictedStart) - math.pi / 2;
    final endAngle = _timeToAngle(predictedEnd) - math.pi / 2;
    final sweepAngle = _normalizeAngle(endAngle - startAngle);

    if (sweepAngle < 0.01) return;

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = AppColors.sleepPurple.withValues(alpha: 0.2);

    final path = Path();
    final arcRect =
        Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2);
    path.addArc(arcRect, startAngle, sweepAngle);
    canvas.drawPath(_dashPath(path, 6), dashPaint);
  }

  Path _dashPath(Path source, double dashLength) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len =
            dashLength < metric.length - distance ? dashLength : metric.length - distance;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  void _drawEventDots(Canvas canvas, Offset center, double radius,
      double innerRadius) {
    final eventRadius = (radius + innerRadius) / 2;
    final dotRadius = 5.0;

    final events = todayEvents
        .where((e) =>
            e.type == EventType.feed ||
            e.type == EventType.pee ||
            e.type == EventType.poop)
        .toList();

    for (final event in events) {
      final angle = _timeToAngle(event.startTime) - math.pi / 2;
      final x = center.dx + math.cos(angle) * eventRadius;
      final y = center.dy + math.sin(angle) * eventRadius;

      Color dotColor;
      switch (event.type) {
        case EventType.feed:
          dotColor = AppColors.feedOrange;
          break;
        case EventType.pee:
        case EventType.poop:
          dotColor = AppColors.diaperTeal;
          break;
        default:
          continue;
      }

      final glowPaint = Paint()
        ..color = dotColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), dotRadius + 2, glowPaint);

      final dotPaint = Paint()..color = dotColor;
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);

      final innerDotPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
      canvas.drawCircle(Offset(x, y), dotRadius * 0.4, innerDotPaint);
    }
  }

  void _drawTimeMarkers(Canvas canvas, Offset center, double radius) {
    for (int hour = 0; hour < 24; hour += 3) {
      final angle = (hour / 24.0) * 2 * math.pi - math.pi / 2;
      final x = center.dx + math.cos(angle) * (radius + 12);
      final y = center.dy + math.sin(angle) * (radius + 12);

      final tp = TextPainter(
        text: TextSpan(
          text: '${hour.toString().padLeft(2, '0')}:00',
          style: TextStyle(
            color: AppColors.textTertiary.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  void _drawNowIndicator(
      Canvas canvas, Offset center, double radius, double innerRadius) {
    final angle = _timeToAngle(now) - math.pi / 2;
    final outerX = center.dx + math.cos(angle) * radius;
    final outerY = center.dy + math.sin(angle) * radius;
    final innerX = center.dx + math.cos(angle) * innerRadius;
    final innerY = center.dy + math.sin(angle) * innerRadius;

    final linePaint = Paint()
      ..color = AppColors.wakeYellow
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), linePaint);

    final dotPaint = Paint()..color = AppColors.wakeYellow;
    canvas.drawCircle(
        Offset(outerX, outerY), 4,
        dotPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(outerX, outerY), 3, dotPaint..maskFilter = null);
  }

  double _timeToAngle(DateTime dt) {
    final totalMinutes = dt.hour * 60.0 + dt.minute + dt.second / 60.0;
    return (totalMinutes / (24 * 60)) * 2 * math.pi;
  }

  double _normalizeAngle(double angle) {
    while (angle < 0) {
      angle += 2 * math.pi;
    }
    while (angle > 2 * math.pi) {
      angle -= 2 * math.pi;
    }
    return angle;
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return true;
  }
}
