class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isPinned,
    required this.publishedAt,
  });
  final String id;
  final String title;
  final String content;
  final String type;
  final bool isPinned;
  final DateTime publishedAt;

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    id: '${json['id']}',
    title: '${json['title'] ?? ''}',
    content: '${json['content'] ?? ''}',
    type: '${json['notice_type'] ?? 'GENERAL'}',
    isPinned: json['is_pinned'] == true,
    publishedAt:
        DateTime.tryParse('${json['published_at'] ?? ''}') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  String get typeLabel => switch (type) {
    'IMPORTANT' => '중요',
    'MAINTENANCE' => '점검',
    'EVENT' => '이벤트',
    'UPDATE' => '업데이트',
    _ => '일반',
  };
}
