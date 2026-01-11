// lib/features/training/presentation/providers/training_provider.dart
import 'package:flutter/foundation.dart';
import '../../../../core/services/local_storage_service.dart';

class TrainingProvider with ChangeNotifier {
  final LocalStorageService localStorage;

  TrainingProvider({required this.localStorage});

  // State
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Methods
  Future<void> initialize() async {
    // TODO: Load training data from storage
    notifyListeners();
  }
}
