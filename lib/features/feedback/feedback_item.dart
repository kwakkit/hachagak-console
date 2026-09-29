import 'feedback_status.dart';

/// `feedback` 한 행.
class FeedbackItem {
  FeedbackItem.fromRow(Map<String, dynamic> r)
    : id = r['id'] as int,
      category = r['category'] as String,
      message = r['message'] as String,
      status = FeedbackStatus.parse(r['status'] as String),
      adminNote = r['admin_note'] as String?,
      appVersion = r['app_version'] as String?,
      os = r['os'] as String?,
      createdAt = DateTime.parse(r['created_at'] as String).toLocal();

  final int id;
  final String category;
  final String message;
  final FeedbackStatus status;
  final String? adminNote;
  final String? appVersion;
  final String? os;
  final DateTime createdAt;
}
