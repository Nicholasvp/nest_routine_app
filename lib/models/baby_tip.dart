class BabyTip {
  const BabyTip({
    required this.slug,
    required this.minWeek,
    required this.maxWeek,
    required this.category,
    required this.title,
    required this.body,
    this.activity,
    required this.sourceName,
    required this.sourceUrl,
  });

  final String slug;
  final int minWeek;
  final int maxWeek;
  final String category;
  final String title;
  final String body;
  final String? activity;
  final String sourceName;
  final String sourceUrl;

  factory BabyTip.fromJson(Map<String, dynamic> json, {required bool isPt}) {
    final content = Map<String, dynamic>.from(
      json[isPt ? 'content_pt' : 'content_en'] as Map,
    );
    return BabyTip(
      slug: json['slug'] as String,
      minWeek: json['min_week'] as int,
      maxWeek: json['max_week'] as int,
      category: json['category'] as String,
      title: content['title'] as String,
      body: content['body'] as String,
      activity: content['activity'] as String?,
      sourceName: json['source_name'] as String,
      sourceUrl: json['source_url'] as String,
    );
  }
}
