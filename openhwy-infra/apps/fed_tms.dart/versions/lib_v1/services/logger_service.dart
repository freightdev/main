import 'dart:developer' as developer;
import '../configs/flavors.dart';

class LoggerService {
  static void debug(String message) {
    if (FlavorConfig.config['debug'] == true) {
      developer.log(message);
    }
  }

  static void info(String message) {
    if (FlavorConfig.config['debug'] == true) {
      developer.log('INFO: $message');
    }
  }

  static void warning(String message) {
    if (FlavorConfig.config['debug'] == true) {
      developer.log('WARNING: $message');
    }
  }

  static void error(String message) {
    if (FlavorConfig.config['debug'] == true) {
      developer.log('ERROR: $message');
    }
  }
}
