import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/baby_tip.dart';

class BabyTipsService {
  BabyTipsService._();

  static Future<List<BabyTip>> loadForWeek(
    int week, {
    required bool isPortuguese,
  }) async {
    if (week < 1 || week > 52) return const [];

    final rows = await Supabase.instance.client
        .from('baby_tips')
        .select()
        .lte('min_week', week)
        .gte('max_week', week)
        .eq('is_active', true)
        .order('sort_order');

    return (rows as List)
        .map(
          (row) => BabyTip.fromJson(
            Map<String, dynamic>.from(row as Map),
            isPt: isPortuguese,
          ),
        )
        .toList();
  }
}
