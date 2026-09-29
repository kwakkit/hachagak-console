import 'package:intl/intl.dart';

/// 공지 게시 기간 표기.
final noticeTimeFormat = DateFormat('yyyy.MM.dd HH:mm', 'ko');

/// `notices` 한 행.
class Notice {
  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.startsAt,
    this.endsAt,
  });

  factory Notice.fromRow(Map<String, dynamic> r) => Notice(
    id: r['id'] as int,
    title: r['title'] as String,
    body: r['body'] as String,
    startsAt: DateTime.parse(r['starts_at'] as String).toLocal(),
    endsAt: r['ends_at'] == null
        ? null
        : DateTime.parse(r['ends_at'] as String).toLocal(),
  );

  final int id;
  final String title;
  final String body;
  final DateTime startsAt;
  final DateTime? endsAt;

  bool get isLive {
    final now = DateTime.now();
    return !startsAt.isAfter(now) && (endsAt == null || endsAt!.isAfter(now));
  }

  bool get isScheduled => startsAt.isAfter(DateTime.now());
}
