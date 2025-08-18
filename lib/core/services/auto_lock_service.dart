import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiny_password/core/providers/providers.dart';

class AutoLockService {
  Timer? _autoLockTimer;
  DateTime? _lastActivityTime;
  final Ref _ref;
  bool _isEnabled = true;

  AutoLockService(this._ref) {
    _lastActivityTime = DateTime.now();
    _startTimer();
  }

  /// Start the auto-lock timer
  void _startTimer() {
    _cancelTimer();
    
    if (!_isEnabled) return;
    
    final duration = _ref.read(autoLockDurationProvider);
    
    _autoLockTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForAutoLock();
    });
  }

  /// Check if the app should be auto-locked
  void _checkForAutoLock() {
    if (_lastActivityTime == null || !_isEnabled) return;
    
    final duration = _ref.read(autoLockDurationProvider);
    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivityTime!);
    
    if (timeSinceLastActivity >= duration) {
      _triggerAutoLock();
    }
  }

  /// Trigger the auto-lock
  void _triggerAutoLock() {
    print('Auto-lock timer expired - logging out user');
    
    // Set authentication state to false
    _ref.read(isAuthenticatedProvider.notifier).state = false;
    
    // Navigate to unlock screen
    _ref.read(navigationServiceProvider).navigateToUnlock();
    
    // Cancel the timer since we're now locked
    _cancelTimer();
  }

  /// Record user activity to reset the timer
  void recordActivity() {
    _lastActivityTime = DateTime.now();
    
    // Restart timer if it's not running and we're authenticated
    if (_autoLockTimer == null && _isEnabled) {
      final isAuthenticated = _ref.read(isAuthenticatedProvider);
      if (isAuthenticated) {
        _startTimer();
      }
    }
  }

  /// Enable auto-lock functionality
  void enable() {
    _isEnabled = true;
    final isAuthenticated = _ref.read(isAuthenticatedProvider);
    if (isAuthenticated) {
      recordActivity(); // This will start the timer
    }
  }

  /// Disable auto-lock functionality
  void disable() {
    _isEnabled = false;
    _cancelTimer();
  }

  /// Start auto-lock when user authenticates
  void onAuthenticated() {
    if (_isEnabled) {
      recordActivity();
    }
  }

  /// Stop auto-lock when user logs out
  void onLoggedOut() {
    _cancelTimer();
    _lastActivityTime = null;
  }

  /// Update the auto-lock duration
  void updateDuration(Duration newDuration) {
    // The timer will pick up the new duration on next check
    // No need to restart timer immediately
  }

  /// Cancel the current timer
  void _cancelTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  /// Get time remaining until auto-lock
  Duration? getTimeRemaining() {
    if (_lastActivityTime == null || !_isEnabled) return null;
    
    final duration = _ref.read(autoLockDurationProvider);
    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivityTime!);
    final remaining = duration - timeSinceLastActivity;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if auto-lock is currently active
  bool get isActive => _autoLockTimer != null && _isEnabled;

  /// Dispose of the service
  void dispose() {
    _cancelTimer();
  }
}

/// Provider for the auto-lock service
final autoLockServiceProvider = Provider<AutoLockService>((ref) {
  final service = AutoLockService(ref);
  
  // Listen to authentication state changes
  ref.listen(isAuthenticatedProvider, (previous, next) {
    if (next) {
      service.onAuthenticated();
    } else {
      service.onLoggedOut();
    }
  });
  
  // Listen to auto-lock duration changes
  ref.listen(autoLockDurationProvider, (previous, next) {
    service.updateDuration(next);
  });
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});