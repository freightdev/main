// lib/features/gamification/presentation/providers/hearts_provider.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/constants/app_constants.dart';

class HeartsProvider with ChangeNotifier {
  final LocalStorageService localStorage;

  HeartsProvider({required this.localStorage});

  // State
  int _hearts = AppConstants.maxHearts;
  DateTime? _lastHeartLost;
  Timer? _regenTimer;

  // Getters
  int get hearts => _hearts;
  int get maxHearts => AppConstants.maxHearts;
  bool get hasHearts => _hearts > 0;
  bool get isFull => _hearts >= maxHearts;

  Future<void> initialize() async {
    // Load hearts from storage
    _hearts = await localStorage.getInt('hearts') ?? maxHearts;
    final lastLostTimestamp = await localStorage.getInt('last_heart_lost');
    
    if (lastLostTimestamp != null) {
      _lastHeartLost = DateTime.fromMillisecondsSinceEpoch(lastLostTimestamp);
      _startRegenTimer();
    }
    
    notifyListeners();
  }

  void useHeart() {
    if (_hearts > 0) {
      _hearts--;
      _lastHeartLost = DateTime.now();
      _saveState();
      _startRegenTimer();
      notifyListeners();
    }
  }

  void addHeart() {
    if (_hearts < maxHearts) {
      _hearts++;
      _saveState();
      notifyListeners();
    }
  }

  void refillHearts() {
    _hearts = maxHearts;
    _lastHeartLost = null;
    _regenTimer?.cancel();
    _saveState();
    notifyListeners();
  }

  void _startRegenTimer() {
    _regenTimer?.cancel();
    
    _regenTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_hearts >= maxHearts) {
        timer.cancel();
        return;
      }

      if (_lastHeartLost != null) {
        final elapsed = DateTime.now().difference(_lastHeartLost!);
        if (elapsed >= AppConstants.heartRegenTime) {
          addHeart();
          _lastHeartLost = DateTime.now();
        }
      }
    });
  }

  Future<void> _saveState() async {
    await localStorage.setInt('hearts', _hearts);
    if (_lastHeartLost != null) {
      await localStorage.setInt(
        'last_heart_lost',
        _lastHeartLost!.millisecondsSinceEpoch,
      );
    }
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }
}
