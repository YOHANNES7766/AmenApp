import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utility class for performance optimizations
class PerformanceUtils {
  /// Run a potentially expensive operation off the main thread
  static Future<T> computeOffMainThread<T>(
      FutureOr<T> Function() callback) async {
    return await compute<_ComputeArg<T>, T>(
        _computeCallbackRunner, _ComputeArg(callback));
  }

  /// Debounce function calls to reduce rebuilds
  static Debouncer debouncer(int milliseconds) {
    return Debouncer(milliseconds);
  }
}

// Helper class to wrap callback function for compute
class _ComputeArg<T> {
  final FutureOr<T> Function() callback;
  _ComputeArg(this.callback);
}

// Isolate-safe wrapper to run function
FutureOr<T> _computeCallbackRunner<T>(_ComputeArg<T> arg) {
  return arg.callback();
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer(this.milliseconds);

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Helper class for logging with timestamps
class Logger {
  static void debug(String message) {
    debugPrint('[${DateTime.now()}] DEBUG: $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[${DateTime.now()}] ERROR: $message');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
