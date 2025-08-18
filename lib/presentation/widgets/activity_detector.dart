import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiny_password/core/services/auto_lock_service.dart';

/// A widget that detects user activity and reports it to the auto-lock service
class ActivityDetector extends ConsumerWidget {
  final Widget child;
  final bool enabled;

  const ActivityDetector({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    final autoLockService = ref.watch(autoLockServiceProvider);

    return Listener(
      onPointerDown: (_) => _recordActivity(autoLockService),
      onPointerMove: (_) => _recordActivity(autoLockService),
      onPointerUp: (_) => _recordActivity(autoLockService),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _recordActivity(autoLockService);
          return false;
        },
        child: GestureDetector(
          onTap: () => _recordActivity(autoLockService),
          onPanUpdate: (_) => _recordActivity(autoLockService),
          onScaleUpdate: (_) => _recordActivity(autoLockService),
          behavior: HitTestBehavior.translucent,
          child: child,
        ),
      ),
    );
  }

  void _recordActivity(AutoLockService autoLockService) {
    autoLockService.recordActivity();
  }
}

/// A mixin that can be used with StatefulWidget to automatically detect activity
mixin ActivityDetectorMixin<T extends StatefulWidget> on State<T> {
  late AutoLockService _autoLockService;
  bool _activityDetectionEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      final container = ProviderScope.containerOf(context);
      _autoLockService = container.read(autoLockServiceProvider);
    }
  }

  /// Record user activity
  void recordActivity() {
    if (_activityDetectionEnabled) {
      _autoLockService.recordActivity();
    }
  }

  /// Enable activity detection
  void enableActivityDetection() {
    _activityDetectionEnabled = true;
  }

  /// Disable activity detection
  void disableActivityDetection() {
    _activityDetectionEnabled = false;
  }

  /// Wrap the build method with activity detection
  Widget buildWithActivityDetection(Widget child) {
    return ActivityDetector(
      enabled: _activityDetectionEnabled,
      child: child,
    );
  }
}

/// A wrapper for ConsumerStatefulWidget that automatically includes activity detection
abstract class ActivityAwareConsumerStatefulWidget extends ConsumerStatefulWidget {
  const ActivityAwareConsumerStatefulWidget({super.key});
}

abstract class ActivityAwareConsumerState<T extends ActivityAwareConsumerStatefulWidget>
    extends ConsumerState<T> {
  bool _activityDetectionEnabled = true;

  /// Record user activity
  void recordActivity() {
    if (_activityDetectionEnabled) {
      ref.read(autoLockServiceProvider).recordActivity();
    }
  }

  /// Enable activity detection
  void enableActivityDetection() {
    _activityDetectionEnabled = true;
  }

  /// Disable activity detection
  void disableActivityDetection() {
    _activityDetectionEnabled = false;
  }

  /// Build method that should be implemented by subclasses
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return ActivityDetector(
      enabled: _activityDetectionEnabled,
      child: buildContent(context),
    );
  }
}