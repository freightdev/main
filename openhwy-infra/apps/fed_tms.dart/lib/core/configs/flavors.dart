enum FlavorType {
  development,
  staging,
  production,
}

class FlavorConfig {
  static FlavorType currentFlavor = FlavorType.development;

  static Map<String, dynamic> get config {
    switch (currentFlavor) {
      case FlavorType.development:
        return {
          'apiUrl': 'http://localhost:3000',
          'debug': true,
        };
      case FlavorType.staging:
        return {
          'apiUrl': 'https://staging.hwy-tms.com',
          'debug': false,
        };
      case FlavorType.production:
        return {
          'apiUrl': 'https://api.hwy-tms.com',
          'debug': false,
        };
    }
  }
}
