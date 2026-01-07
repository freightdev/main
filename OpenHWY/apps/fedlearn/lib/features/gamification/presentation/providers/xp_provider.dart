// lib/features/gamification/presentation/providers/xp_provider.dart
import 'package:flutter/foundation.dart';
import '../../../../core/services/local_storage_service.dart';

class XPProvider with ChangeNotifier {
  final LocalStorageService localStorage;

  XPProvider({required this.localStorage});

  // State
  int _xp = 0;
  int _level = 1;

  // Getters
  int get xp => _xp;
  int get level => _level;
  int get xpForNextLevel => _calculateXPForLevel(level + 1);
  int get xpProgress => _xp - _calculateXPForLevel(level);
  int get xpNeeded => xpForNextLevel - _xp;
  double get progressPercent => xpProgress / (xpForNextLevel - _calculateXPForLevel(level));

  Future<void> initialize() async {
    _xp = await localStorage.getInt('xp') ?? 0;
    _level = await localStorage.getInt('level') ?? 1;
    notifyListeners();
  }

  void addXP(int amount) {
    _xp += amount;
    _checkLevelUp();
    _saveState();
    notifyListeners();
  }

  void _checkLevelUp() {
    while (_xp >= xpForNextLevel) {
      _level++;
      // Could trigger level up animation/celebration here
    }
  }

  int _calculateXPForLevel(int targetLevel) {
    // XP required increases exponentially
    return (targetLevel * targetLevel * 100);
  }

  Future<void> _saveState() async {
    await localStorage.setInt('xp', _xp);
    await localStorage.setInt('level', _level);
  }
}
