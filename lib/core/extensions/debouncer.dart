import 'dart:async';

/// Delays executing [action] until [duration] has passed since the last call.
/// Used to throttle camera-change events so we don't fire a Supabase query
/// on every single pixel of map pan.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 400)});

  final Duration duration;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() => _timer?.cancel();
}
