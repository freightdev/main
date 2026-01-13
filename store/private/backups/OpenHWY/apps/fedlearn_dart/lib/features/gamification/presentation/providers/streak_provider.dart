
// lib/features/gamification/presentation/providers/streak_provider.dart
import 'package:flutter/foundation.dart';
import '../../../../core/services/local_storage_service.dart';

class StreakProvider with ChangeNotifier {
  final LocalStorageService localStorage;

  StreakProvider({required this.localStorage});

  // State
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActivity;

  // Getters
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  bool get hasStreakToday => _lastActivity != null && 
      _isToday(_lastActivity!);

  Future<void> initialize() async {
    _currentStreak = await localStorage.getInt('current_streak') ?? 0;
    _longestStreak = await localStorage.getInt('longest_streak') ?? 0;
    
    final lastActivityTimestamp = await localStorage.getInt('last_activity');
    if (lastActivityTimestamp != null) {
      _lastActivity = DateTime.fromMillisecondsSinceEpoch(lastActivityTimestamp);
      _checkStreakStatus();
    }
    
    notifyListeners();
  }

  void recordActivity() {
    final now = DateTime.now();

    if (_lastActivity == null) {
      // First activity ever
      _currentStreak = 1;
    } else if (_isToday(_lastActivity!)) {
      // Already recorded today, do nothing
      return;
    } else if (_isYesterday(_lastActivity!)) {
      // Consecutive day
      _currentStreak++;
    } else {
      // Streak broken
      _currentStreak = 1;
    }

    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    _lastActivity = now;
    _saveState();
    notifyListeners();
  }

  void _checkStreakStatus() {
    if (_lastActivity == null) return;

    if (!_isToday(_lastActivity!) && !_isYesterday(_lastActivity!)) {
      // Streak broken - was more than a day ago
      _currentStreak = 0;
      _saveState();
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  Future<void> _saveState() async {
    await localStorage.setInt('current_streak', _currentStreak);
    await localStorage.setInt('longest_streak', _longestStreak);
    if (_lastActivity != null) {
      await localStorage.setInt(
        'last_activity',
        _lastActivity!.millisecondsSinceEpoch,
      );
    }
  }
}
