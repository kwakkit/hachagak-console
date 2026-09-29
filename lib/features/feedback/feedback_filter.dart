import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feedback_status.dart';

/// null = 전체.
final feedbackFilterProvider =
    NotifierProvider<FeedbackFilterNotifier, FeedbackStatus?>(
      FeedbackFilterNotifier.new,
    );

class FeedbackFilterNotifier extends Notifier<FeedbackStatus?> {
  @override
  FeedbackStatus? build() => FeedbackStatus.newOne;

  void set(FeedbackStatus? v) => state = v;
}
