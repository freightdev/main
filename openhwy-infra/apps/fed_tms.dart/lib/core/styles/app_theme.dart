import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Highway Journey Theme
  static const roadBlack = Color(0xFF0A0A0F);
  static const asphaltGray = Color(0xFF1A1A2E);
  static const concreteGray = Color(0xFF2A2A3E);
  static const yellowLine = Color(0xFFFBBF24);
  static const warningOrange = Color(0xFFF97316);
  static const truckRed = Color(0xFFEF4444);
  static const highwayBlue = Color(0xFF3B82F6);
  static const forestGreen = Color(0xFF10B981);
  static const skyBlue = Color(0xFF60A5FA);
  static const sunrisePurple = Color(0xFFA855F7);
  static const dawnPink = Color(0xFFEC4899);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF9FAFB);
  static const textGray = Color(0xFF9CA3AF);

  // Legacy colors for compatibility
  static const Color primary = highwayBlue;
  static const Color secondary = skyBlue;
  static const Color accent = warningOrange;
  static const Color background = roadBlack;
  static const Color backgroundDark = asphaltGray;
  static const Color surface = concreteGray;
  static const Color surfaceDark = asphaltGray;
  static const Color textPrimary = white;
  static const Color textSecondary = textGray;
  static const Color textHint = Color(0xFF6B7280);
  static const Color success = forestGreen;
  static const Color warning = warningOrange;
  static const Color error = truckRed;
  static const Color info = highwayBlue;
  static const Color purple = sunrisePurple;
  static const Color purplePrimary = Color(0xFF7B1FA2);
  static const Color teal = Color(0xFF009688);
  static const Color indigo = Color(0xFF3F51B5);
  static const Color pink = dawnPink;
  static const Color amber = yellowLine;
  static const Color blueGrey = Color(0xFF607D8B);

  // Individual color access
  static const Color orange = warningOrange;
  static const Color blue = highwayBlue;
  static const Color green = forestGreen;

  // Gradients
  static const gradientSunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [yellowLine, warningOrange, truckRed],
  );

  static const gradientHighway = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [highwayBlue, sunrisePurple],
  );

  static const gradientForest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forestGreen, Color(0xFF059669)],
  );

  static const gradientNight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [asphaltGray, roadBlack],
  );

  // Status Colors
  static const statusSuccess = forestGreen;
  static const statusWarning = warningOrange;
  static const statusError = truckRed;
  static const statusInfo = highwayBlue;

  // Border Colors
  static final borderGray = white.withOpacity(0.1);
  static final borderLight = white.withOpacity(0.05);

  // Purple shades
  static const purplePrimaryGradient = Color(0xFFD946EF);
  static const purpleLight = Color(0xFFF0ABFC);
  static const purpleDark = Color(0xFFA21CAF);

  // Orange shades
  static const orangePrimary = Color(0xFFFB923C);
  static const orangeLight = Color(0xFFFDBA74);
  static const orangeDark = Color(0xFFEA580C);

  // Blue shades
  static const bluePrimary = Color(0xFF3B82F6);
  static const blueLight = Color(0xFF60A5FA);
  static const blueDark = Color(0xFF1D4ED8);

  // Green shades
  static const greenPrimary = Color(0xFF10B981);
  static const greenLight = Color(0xFF34D399);
  static const greenDark = Color(0xFF059669);

  // Red/Error shades
  static const errorPrimary = Color(0xFFEF4444);
  static const errorLight = Color(0xFFF87171);
  static const errorDark = Color(0xFFDC2626);

  // Background gradients
  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A24),
      Color(0xFF0F0F16),
    ],
  );

  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD946EF),
      Color(0xFFA855F7),
    ],
  );

  static const orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFB923C),
      Color(0xFFF59E0B),
    ],
  );

  static const blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF2563EB),
    ],
  );
}

class AppTheme {
  // Gradients for easy access
  static LinearGradient get surfaceGradient => AppColors.surfaceGradient;
  static LinearGradient get purpleGradient => AppColors.purpleGradient;
  static LinearGradient get orangeGradient => AppColors.orangeGradient;
  static LinearGradient get blueGradient => AppColors.blueGradient;

  // Color getters
  static Color get purplePrimary => AppColors.purplePrimary;
  static Color get purpleSecondary => AppColors.dawnPink;
  static Color get textTertiary => AppColors.textHint;

  // Status colors
  static Color get success => AppColors.success;
  static Color get warning => AppColors.warning;
  static Color get error => AppColors.error;
  static Color get info => AppColors.info;

  // Surface colors
  static Color get surface => AppColors.surface;
  static Color get background => AppColors.background;

  // Text colors
  static Color get textPrimary => AppColors.textPrimary;
  static Color get textSecondary => AppColors.textSecondary;

  // Primary colors
  static Color get primary => AppColors.primary;

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary),
          displayMedium: TextStyle(color: AppColors.textPrimary),
          displaySmall: TextStyle(color: AppColors.textPrimary),
          headlineLarge: TextStyle(color: AppColors.textPrimary),
          headlineMedium: TextStyle(color: AppColors.textPrimary),
          headlineSmall: TextStyle(color: AppColors.textPrimary),
          titleLarge: TextStyle(color: AppColors.textPrimary),
          titleMedium: TextStyle(color: AppColors.textPrimary),
          titleSmall: TextStyle(color: AppColors.textPrimary),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
          labelLarge: TextStyle(color: AppColors.textPrimary),
          labelMedium: TextStyle(color: AppColors.textSecondary),
          labelSmall: TextStyle(color: AppColors.textHint),
        ),
      );
}

extension GradientText on Text {
  Widget withGradient(Gradient gradient) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: this,
    );
  }
}
