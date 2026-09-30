import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';

const double _dayMinutes = 24 * 60.0;

const double _minVisibleMinutes = 0.75;

enum _SegmentKind { idealWindow, awake, sleep, activeSleep }

class _TimelineSegment {
  const _TimelineSegment({
    required this.startMinute,
    required this.endMinute,
    required this.kind,
    this.eventId,
  });

  final double startMinute;
  final double endMinute;
  final _SegmentKind kind;
  final String? eventId;
}

class CircularTimeline extends StatefulWidget {
  final List<BabyEvent> todayEvents;
  final BabyEvent? activeSleep;
  final double? pulseScale;
  final double? glowRadius;
  final VoidCallback? onTap;

  const CircularTimeline({
    super.key,
    required this.todayEvents,
    this.activeSleep,
    this.pulseScale,
    this.glowRadius,
    this.onTap,
  });

  @override
  State<CircularTimeline> createState() => _CircularTimelineState();
}

class _CircularTimelineState extends State<CircularTimeline>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Duration _revealDuration = Duration(milliseconds: 1600);
  static const Duration _newEventDuration = Duration(milliseconds: 900);
  static const Duration _shimmerDuration = Duration(milliseconds: 2600);

  late final AnimationController _revealController;
  late final Animation<double> _revealAnimation;
  late final AnimationController _newEventController;
  late final Animation<double> _newEventAnimation;
  late final AnimationController _shimmerController;

  Set<String> _knownEventIds = <String>{};
  Set<String> _paintingEventIds = <String>{};
  bool _initialRevealDone = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      duration: _revealDuration,
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _initialRevealDone = true;
        }
      });
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );

    _newEventController = AnimationController(
      duration: _newEventDuration,
      vsync: this,
    );
    _newEventAnimation = CurvedAnimation(
      parent: _newEventController,
      curve: Curves.easeOutCubic,
    );

    _shimmerController = AnimationController(
      duration: _shimmerDuration,
      vsync: this,
    )..repeat(reverse: true);

    _knownEventIds = widget.todayEvents.map((e) => e.id).toSet();
    _revealController.forward();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_initialRevealDone) return;
    _revealController.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant CircularTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.todayEvents.map((e) => e.id).toSet();
    final addedIds = currentIds.difference(_knownEventIds);
    _knownEventIds = currentIds;

    if (addedIds.isEmpty || !_initialRevealDone) return;

    setState(() => _paintingEventIds = addedIds);
    _newEventController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _paintingEventIds = <String>{});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _revealController.dispose();
    _newEventController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _revealAnimation,
        _newEventAnimation,
        _shimmerController,
      ]),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth;
            final centerOpacity =
                ((_revealAnimation.value - 0.35) / 0.65).clamp(0.0, 1.0);
            return SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _TimelinePainter(
                  todayEvents: widget.todayEvents,
                  activeSleep: widget.activeSleep,
                  now: now,
                  reveal: _revealAnimation.value,
                  newEventReveal: _newEventAnimation.value,
                  paintingEventIds: _paintingEventIds,
                  shimmer: _shimmerController.value,
                ),
                child: Center(
                  child: Opacity(
                    opacity: centerOpacity,
                    child: widget.onTap != null
                        ? GestureDetector(
                            onTap: widget.onTap,
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
      },
    );
  }

  Widget _buildCenterContent(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    if (widget.activeSleep != null) {
      final duration = Duration(
        microseconds: DateTime.now()
            .difference(widget.activeSleep!.startTime)
            .inMicroseconds
            .clamp(0, 1 << 62),
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (widget.glowRadius != null && widget.glowRadius! > 0)
                  BoxShadow(
                    color: AppColors.sleepPurple.withValues(alpha: 0.4),
                    blurRadius: widget.glowRadius!,
                    spreadRadius: widget.glowRadius! * 0.3,
                  ),
              ],
            ),
            child: Transform.scale(
              scale: widget.pulseScale ?? 1.0,
              child: const Icon(
                Icons.nightlight_round,
                color: AppColors.sleepPurple,
                size: 28,
              ),
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
                  width: 6,
                  height: 6,
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
    final lastSleep = widget.todayEvents
        .where((e) => e.type == EventType.sleep && e.endTime != null)
        .fold<BabyEvent?>(
          null,
          (prev, e) =>
              prev == null || e.endTime!.isAfter(prev.endTime!) ? e : prev,
        );

    if (lastSleep != null) {
      final awakeDuration = Duration(
        microseconds: awakeNow
            .difference(lastSleep.endTime!)
            .inMicroseconds
            .clamp(0, 1 << 62),
      );
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
  _TimelinePainter({
    required this.todayEvents,
    this.activeSleep,
    required this.now,
    required this.reveal,
    required this.newEventReveal,
    required this.paintingEventIds,
    required this.shimmer,
  });

  final List<BabyEvent> todayEvents;
  final BabyEvent? activeSleep;
  final DateTime now;
  final double reveal;
  final double newEventReveal;
  final Set<String> paintingEventIds;
  final double shimmer;

  DateTime get _dayStart => DateTime(now.year, now.month, now.day);
  DateTime get _dayEnd => DateTime(now.year, now.month, now.day + 1);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 24;
    final innerRadius = radius * 0.72;
    final arcRadius = (radius + innerRadius) / 2;
    final revealedMinutes = reveal * _dayMinutes;

    _drawStarDots(canvas, size, center, radius);
    _drawClockRing(canvas, center, radius, innerRadius);

    final segments = _buildSegments();

    // Purpura (sono) e sempre desenhado depois do amarelo (acordado), entao
    // nunca fica por baixo dele.
    for (final segment in segments) {
      switch (segment.kind) {
        case _SegmentKind.idealWindow:
          _drawIdealWindowSegment(canvas, center, arcRadius, segment);
          break;
        case _SegmentKind.awake:
          _drawAwakeSegment(canvas, center, arcRadius, segment);
          break;
        case _SegmentKind.sleep:
          _drawSleepSegment(canvas, center, arcRadius, segment);
          break;
        case _SegmentKind.activeSleep:
          _drawActiveSleepSegment(canvas, center, radius, arcRadius, segment);
          break;
      }
    }

    _drawPredictedSleepArc(canvas, center, arcRadius);
    _drawEventDots(canvas, center, arcRadius, revealedMinutes);
    if (reveal > 0 && reveal < 1) {
      _drawPaintHead(canvas, center, arcRadius, revealedMinutes);
    }
    _drawTimeMarkers(canvas, center, radius + 6);
    _drawNowIndicator(canvas, center, radius, innerRadius, revealedMinutes);
  }

  List<_TimelineSegment> _buildSegments() {
    final dayStart = _dayStart;
    final dayEnd = _dayEnd;
    final nowMinutes = _minutesFrom(dayStart, now).clamp(0.0, _dayMinutes);
    final activeId = activeSleep?.id;

    final sleepSegments = <_TimelineSegment>[];

    for (final event in todayEvents) {
      if (event.type != EventType.sleep) continue;
      final endTime = event.endTime;
      if (endTime == null || event.id == activeId) continue;
      final segment = _clipToDay(
        start: event.startTime,
        end: endTime,
        kind: _SegmentKind.sleep,
        eventId: event.id,
        dayStart: dayStart,
        dayEnd: dayEnd,
      );
      if (segment != null) sleepSegments.add(segment);
    }

    if (activeSleep != null) {
      final segment = _clipToDay(
        start: activeSleep!.startTime,
        end: now,
        kind: _SegmentKind.activeSleep,
        eventId: activeSleep!.id,
        dayStart: dayStart,
        dayEnd: dayEnd,
      );
      if (segment != null) sleepSegments.add(segment);
    }

    sleepSegments.sort((a, b) => a.startMinute.compareTo(b.startMinute));

    // O amarelo e o complemento do sono dentro do dia: assim ele nunca
    // invade um arco roxo.
    final awakeSegments = <_TimelineSegment>[];
    var cursor = 0.0;
    for (final sleep in sleepSegments) {
      if (sleep.startMinute > cursor) {
        awakeSegments.add(
          _TimelineSegment(
            startMinute: cursor,
            endMinute: math.min(sleep.startMinute, nowMinutes),
            kind: _SegmentKind.awake,
          ),
        );
      }
      cursor = math.max(cursor, sleep.endMinute);
    }
    if (cursor < nowMinutes) {
      awakeSegments.add(
        _TimelineSegment(
          startMinute: cursor,
          endMinute: nowMinutes,
          kind: _SegmentKind.awake,
        ),
      );
    }

    return <_TimelineSegment>[
      ..._idealWindowSegments(),
      ...awakeSegments.where(
          (s) => s.endMinute - s.startMinute > _minVisibleMinutes),
      ...sleepSegments,
    ];
  }

  List<_TimelineSegment> _idealWindowSegments() {
    return const <_TimelineSegment>[
      _TimelineSegment(
        startMinute: 0,
        endMinute: 7 * 60,
        kind: _SegmentKind.idealWindow,
      ),
      _TimelineSegment(
        startMinute: 21 * 60,
        endMinute: _dayMinutes,
        kind: _SegmentKind.idealWindow,
      ),
    ];
  }

  _TimelineSegment? _clipToDay({
    required DateTime start,
    required DateTime end,
    required _SegmentKind kind,
    required String? eventId,
    required DateTime dayStart,
    required DateTime dayEnd,
  }) {
    if (!end.isAfter(start)) return null;
    if (!start.isBefore(dayEnd) || !end.isAfter(dayStart)) return null;

    final startMinute =
        start.isAfter(dayStart) ? _minutesFrom(dayStart, start) : 0.0;
    final endMinute =
        end.isBefore(dayEnd) ? _minutesFrom(dayStart, end) : _dayMinutes;

    if (endMinute - startMinute <= _minVisibleMinutes) return null;

    return _TimelineSegment(
      startMinute: startMinute.clamp(0.0, _dayMinutes),
      endMinute: endMinute.clamp(0.0, _dayMinutes),
      kind: kind,
      eventId: eventId,
    );
  }

  double _visibleEnd(_TimelineSegment segment) {
    var limit = reveal * _dayMinutes;
    final id = segment.eventId;
    if (id != null && paintingEventIds.contains(id)) {
      final grown = segment.startMinute +
          (segment.endMinute - segment.startMinute) * newEventReveal;
      if (grown < limit) limit = grown;
    }
    return math.min(segment.endMinute, limit);
  }

  double? _visibleSweep(_TimelineSegment segment) {
    final visibleEnd = _visibleEnd(segment);
    final visibleMinutes = visibleEnd - segment.startMinute;
    if (visibleMinutes <= _minVisibleMinutes) return null;
    return (visibleMinutes / _dayMinutes) * 2 * math.pi;
  }

  double _angleFor(double minute) =>
      -math.pi / 2 + (minute / _dayMinutes) * 2 * math.pi;

  double _minutesFrom(DateTime origin, DateTime value) =>
      value.difference(origin).inMicroseconds / Duration.microsecondsPerMinute;

  void _drawStarDots(Canvas canvas, Size size, Offset center, double radius) {
    final paint = Paint()..color = AppColors.starColor.withValues(alpha: 0.3);
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

  void _drawClockRing(
      Canvas canvas, Offset center, double radius, double innerRadius) {
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

  void _drawIdealWindowSegment(
      Canvas canvas, Offset center, double arcRadius, _TimelineSegment segment) {
    final sweep = _visibleSweep(segment);
    if (sweep == null) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = AppColors.sleepPurple.withValues(alpha: 0.08);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      _angleFor(segment.startMinute),
      sweep,
      false,
      paint,
    );
  }

  void _drawAwakeSegment(
      Canvas canvas, Offset center, double arcRadius, _TimelineSegment segment) {
    final sweep = _visibleSweep(segment);
    if (sweep == null) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = AppColors.wakeYellow.withValues(alpha: 0.2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      _angleFor(segment.startMinute),
      sweep,
      false,
      paint,
    );
  }

  void _drawSleepSegment(
      Canvas canvas, Offset center, double arcRadius, _TimelineSegment segment) {
    final sweep = _visibleSweep(segment);
    if (sweep == null) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = AppColors.sleepPurple.withValues(alpha: 0.3);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      _angleFor(segment.startMinute),
      sweep,
      false,
      paint,
    );
  }

  void _drawActiveSleepSegment(Canvas canvas, Offset center, double radius,
      double arcRadius, _TimelineSegment segment) {
    final sweep = _visibleSweep(segment);
    if (sweep == null) return;

    final startAngle = _angleFor(segment.startMinute);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = AppColors.sleepGlow.withValues(alpha: 0.4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      startAngle,
      sweep,
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
      Rect.fromCircle(center: center, radius: arcRadius),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  void _drawPredictedSleepArc(Canvas canvas, Offset center, double arcRadius) {
    final sleepEvents = todayEvents
        .where((e) => e.type == EventType.sleep && e.endTime != null)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (sleepEvents.isEmpty) return;

    final lastWakeUp = sleepEvents.first.endTime!;
    final awakeSince = now.difference(lastWakeUp).inMinutes;

    if (awakeSince < 30 || activeSleep != null) return;

    final predictedMinutes = (90 - awakeSince).clamp(15, 180);
    final predictedStart = now.add(const Duration(minutes: 5));
    final predictedEnd = predictedStart.add(Duration(minutes: predictedMinutes));

    if (predictedEnd.hour >= 22 || predictedEnd.hour < 6) return;

    final dayStart = _dayStart;
    final startMinute =
        _minutesFrom(dayStart, predictedStart).clamp(0.0, _dayMinutes);
    final endMinute =
        _minutesFrom(dayStart, predictedEnd).clamp(0.0, _dayMinutes);
    final visibleEnd = math.min(endMinute, reveal * _dayMinutes);

    if (visibleEnd - startMinute <= _minVisibleMinutes) return;

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = AppColors.sleepPurple.withValues(alpha: 0.2);

    final path = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        _angleFor(startMinute),
        ((visibleEnd - startMinute) / _dayMinutes) * 2 * math.pi,
      );
    canvas.drawPath(_dashPath(path, 6), dashPaint);
  }

  Path _dashPath(Path source, double dashLength) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = dashLength < metric.length - distance
            ? dashLength
            : metric.length - distance;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  void _drawEventDots(
      Canvas canvas, Offset center, double arcRadius, double revealedMinutes) {
    final dotRadius = 5.0;

    final events = todayEvents
        .where((e) =>
            e.type == EventType.feed ||
            e.type == EventType.pee ||
            e.type == EventType.poop)
        .toList();

    for (final event in events) {
      final minute = _minutesFrom(_dayStart, event.startTime);
      if (minute < 0 || minute > _dayMinutes) continue;

      final isPainting =
          newEventReveal > 0 && paintingEventIds.contains(event.id);
      // Antes do "pincel" passar pelo horario do ponto, ele nao aparece.
      if (!isPainting && minute > revealedMinutes) continue;

      final appear = isPainting
          ? Curves.easeOutBack
              .transform((newEventReveal * 1.4).clamp(0.0, 1.0))
              .clamp(0.0, 1.0)
          : 1.0;
      if (appear <= 0.01) continue;

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

      final angle = _angleFor(minute);
      final offset = Offset(
        center.dx + math.cos(angle) * arcRadius,
        center.dy + math.sin(angle) * arcRadius,
      );

      final pulse = 1.0 + shimmer * 0.6;

      final glowPaint = Paint()
        ..color = dotColor.withValues(alpha: (0.18 + shimmer * 0.22) * appear)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(offset, dotRadius + 2 + pulse * 2.5, glowPaint);

      final haloPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = dotColor.withValues(alpha: (0.35 - shimmer * 0.2) * appear);
      canvas.drawCircle(offset, dotRadius + 3 + pulse * 4, haloPaint);

      if (isPainting) {
        final burstProgress = (newEventReveal * 1.2).clamp(0.0, 1.0);
        final burstPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - burstProgress)
          ..color = dotColor.withValues(alpha: (1 - burstProgress) * 0.7);
        canvas.drawCircle(offset, dotRadius + burstProgress * 22, burstPaint);
      }

      final dotPaint = Paint()..color = dotColor.withValues(alpha: appear);
      canvas.drawCircle(offset, dotRadius * appear, dotPaint);

      final innerDotPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8 * appear);
      canvas.drawCircle(offset, dotRadius * 0.4 * appear, innerDotPaint);
    }
  }

  void _drawPaintHead(
      Canvas canvas, Offset center, double arcRadius, double revealedMinutes) {
    final angle = _angleFor(revealedMinutes.clamp(0.0, _dayMinutes));
    final offset = Offset(
      center.dx + math.cos(angle) * arcRadius,
      center.dy + math.sin(angle) * arcRadius,
    );
    final alpha = (1 - reveal) * 4;

    final glowPaint = Paint()
      ..color = AppColors.softLavender.withValues(alpha: 0.25 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(offset, 14, glowPaint);

    final headPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * alpha);
    canvas.drawCircle(offset, 3, headPaint);
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

  void _drawNowIndicator(Canvas canvas, Offset center, double radius,
      double innerRadius, double revealedMinutes) {
    final nowMinutes = _minutesFrom(_dayStart, now).clamp(0.0, _dayMinutes);
    if (nowMinutes > revealedMinutes) return;

    final angle = _angleFor(nowMinutes);
    final outer = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    final inner = Offset(
      center.dx + math.cos(angle) * innerRadius,
      center.dy + math.sin(angle) * innerRadius,
    );

    final linePaint = Paint()
      ..color = AppColors.wakeYellow
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(inner, outer, linePaint);

    final dotPaint = Paint()..color = AppColors.wakeYellow;
    canvas.drawCircle(
        outer, 4, dotPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(outer, 3, dotPaint..maskFilter = null);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return reveal != oldDelegate.reveal ||
        newEventReveal != oldDelegate.newEventReveal ||
        shimmer != oldDelegate.shimmer ||
        !_sameIds(paintingEventIds, oldDelegate.paintingEventIds) ||
        todayEvents.length != oldDelegate.todayEvents.length ||
        activeSleep?.id != oldDelegate.activeSleep?.id ||
        now != oldDelegate.now;
  }

  bool _sameIds(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final id in a) {
      if (!b.contains(id)) return false;
    }
    return true;
  }
}
