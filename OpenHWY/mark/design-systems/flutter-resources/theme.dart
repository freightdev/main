// lib/design_system/theme.dart
import 'package:flutter/material.dart';

class HWYTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color primaryDark = Color(0xFF1E293B);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color accentRed = Color(0xFFDC2626);
  static const Color accentYellow = Color(0xFFF59E0B);
  
  // Neutrals
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);
  
  // Status Colors
  static const Color statusActive = Color(0xFF16A34A);
  static const Color statusInactive = Color(0xFF94A3B8);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusDanger = Color(0xFFDC2626);
  static const Color statusInfo = Color(0xFF3B82F6);
  
  // Spacing System (8px base)
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;
  
  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusFull = 9999.0;
  
  // Typography
  static const String fontFamily = 'Inter';
  
  static TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      color: neutral900,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: neutral900,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: neutral900,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: neutral900,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: neutral900,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: neutral900,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: neutral900,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: neutral900,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: neutral900,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: neutral800,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: neutral800,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: neutral700,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: neutral900,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: neutral900,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: neutral900,
    ),
  );
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentOrange,
        surface: neutral50,
        error: accentRed,
      ),
      scaffoldBackgroundColor: neutral50,
      fontFamily: fontFamily,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentOrange,
        surface: neutral800,
        error: accentRed,
      ),
      scaffoldBackgroundColor: neutral900,
      fontFamily: fontFamily,
      textTheme: textTheme.apply(
        bodyColor: neutral100,
        displayColor: neutral100,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: neutral900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

// lib/design_system/atoms/hwy_button.dart
enum HWYButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

enum HWYButtonSize {
  small,
  medium,
  large,
}

class HWYButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final HWYButtonVariant variant;
  final HWYButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const HWYButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = HWYButtonVariant.primary,
    this.size = HWYButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    
    double height;
    double fontSize;
    double iconSize;
    double horizontalPadding;
    
    switch (size) {
      case HWYButtonSize.small:
        height = 32;
        fontSize = 12;
        iconSize = 16;
        horizontalPadding = HWYTheme.space3;
        break;
      case HWYButtonSize.medium:
        height = 40;
        fontSize = 14;
        iconSize = 18;
        horizontalPadding = HWYTheme.space4;
        break;
      case HWYButtonSize.large:
        height = 48;
        fontSize = 16;
        iconSize = 20;
        horizontalPadding = HWYTheme.space6;
        break;
    }
    
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    
    switch (variant) {
      case HWYButtonVariant.primary:
        backgroundColor = disabled ? HWYTheme.neutral300 : HWYTheme.primaryBlue;
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
        break;
      case HWYButtonVariant.secondary:
        backgroundColor = disabled ? HWYTheme.neutral200 : HWYTheme.neutral700;
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
        break;
      case HWYButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = disabled ? HWYTheme.neutral400 : HWYTheme.primaryBlue;
        borderColor = disabled ? HWYTheme.neutral300 : HWYTheme.primaryBlue;
        break;
      case HWYButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = disabled ? HWYTheme.neutral400 : HWYTheme.primaryBlue;
        borderColor = Colors.transparent;
        break;
      case HWYButtonVariant.danger:
        backgroundColor = disabled ? HWYTheme.neutral300 : HWYTheme.accentRed;
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
        break;
    }
    
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
            side: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: iconSize),
                    SizedBox(width: HWYTheme.space2),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// lib/design_system/atoms/hwy_input.dart
enum HWYInputVariant {
  text,
  email,
  password,
  number,
  multiline,
}

class HWYInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final HWYInputVariant variant;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final Function(String)? onChanged;
  final bool disabled;
  final int? maxLines;

  const HWYInput({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.controller,
    this.variant = HWYInputVariant.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.onChanged,
    this.disabled = false,
    this.maxLines = 1,
  });

  @override
  State<HWYInput> createState() => _HWYInputState();
}

class _HWYInputState extends State<HWYInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    bool isPassword = widget.variant == HWYInputVariant.password;
    bool hasError = widget.errorText != null;
    
    TextInputType keyboardType;
    switch (widget.variant) {
      case HWYInputVariant.email:
        keyboardType = TextInputType.emailAddress;
        break;
      case HWYInputVariant.number:
        keyboardType = TextInputType.number;
        break;
      case HWYInputVariant.multiline:
        keyboardType = TextInputType.multiline;
        break;
      default:
        keyboardType = TextInputType.text;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: HWYTheme.textTheme.labelMedium?.copyWith(
              color: HWYTheme.neutral700,
            ),
          ),
          const SizedBox(height: HWYTheme.space2),
        ],
        TextField(
          controller: widget.controller,
          enabled: !widget.disabled,
          obscureText: isPassword && _obscureText,
          keyboardType: keyboardType,
          maxLines: isPassword ? 1 : widget.maxLines,
          onChanged: widget.onChanged,
          style: HWYTheme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: HWYTheme.textTheme.bodyMedium?.copyWith(
              color: HWYTheme.neutral400,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: HWYTheme.neutral500, size: 20)
                : null,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: HWYTheme.neutral500,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixIcon != null
                    ? IconButton(
                        icon: Icon(widget.suffixIcon, color: HWYTheme.neutral500, size: 20),
                        onPressed: widget.onSuffixIconTap,
                      )
                    : null,
            filled: true,
            fillColor: widget.disabled ? HWYTheme.neutral100 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: HWYTheme.space4,
              vertical: HWYTheme.space3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
              borderSide: BorderSide(
                color: hasError ? HWYTheme.accentRed : HWYTheme.neutral300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
              borderSide: BorderSide(
                color: hasError ? HWYTheme.accentRed : HWYTheme.neutral300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
              borderSide: BorderSide(
                color: hasError ? HWYTheme.accentRed : HWYTheme.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
              borderSide: const BorderSide(
                color: HWYTheme.accentRed,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
              borderSide: const BorderSide(
                color: HWYTheme.accentRed,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
              borderSide: const BorderSide(
                color: HWYTheme.neutral200,
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: HWYTheme.space1),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: HWYTheme.accentRed),
              const SizedBox(width: HWYTheme.space1),
              Text(
                widget.errorText!,
                style: HWYTheme.textTheme.bodySmall?.copyWith(
                  color: HWYTheme.accentRed,
                ),
              ),
            ],
          ),
        ],
        if (widget.helperText != null && widget.errorText == null) ...[
          const SizedBox(height: HWYTheme.space1),
          Text(
            widget.helperText!,
            style: HWYTheme.textTheme.bodySmall?.copyWith(
              color: HWYTheme.neutral500,
            ),
          ),
        ],
      ],
    );
  }
}

// lib/design_system/atoms/hwy_badge.dart
enum HWYBadgeVariant {
  primary,
  success,
  warning,
  danger,
  info,
  neutral,
}

enum HWYBadgeSize {
  small,
  medium,
  large,
}

class HWYBadge extends StatelessWidget {
  final String label;
  final HWYBadgeVariant variant;
  final HWYBadgeSize size;
  final IconData? icon;

  const HWYBadge({
    super.key,
    required this.label,
    this.variant = HWYBadgeVariant.neutral,
    this.size = HWYBadgeSize.medium,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    
    switch (variant) {
      case HWYBadgeVariant.primary:
        backgroundColor = HWYTheme.primaryBlue.withOpacity(0.1);
        textColor = HWYTheme.primaryBlue;
        break;
      case HWYBadgeVariant.success:
        backgroundColor = HWYTheme.statusActive.withOpacity(0.1);
        textColor = HWYTheme.statusActive;
        break;
      case HWYBadgeVariant.warning:
        backgroundColor = HWYTheme.statusWarning.withOpacity(0.1);
        textColor = HWYTheme.statusWarning;
        break;
      case HWYBadgeVariant.danger:
        backgroundColor = HWYTheme.statusDanger.withOpacity(0.1);
        textColor = HWYTheme.statusDanger;
        break;
      case HWYBadgeVariant.info:
        backgroundColor = HWYTheme.statusInfo.withOpacity(0.1);
        textColor = HWYTheme.statusInfo;
        break;
      case HWYBadgeVariant.neutral:
        backgroundColor = HWYTheme.neutral200;
        textColor = HWYTheme.neutral700;
        break;
    }
    
    double fontSize;
    double iconSize;
    double horizontalPadding;
    double verticalPadding;
    
    switch (size) {
      case HWYBadgeSize.small:
        fontSize = 11;
        iconSize = 12;
        horizontalPadding = HWYTheme.space2;
        verticalPadding = HWYTheme.space1;
        break;
      case HWYBadgeSize.medium:
        fontSize = 12;
        iconSize = 14;
        horizontalPadding = HWYTheme.space3;
        verticalPadding = HWYTheme.space1;
        break;
      case HWYBadgeSize.large:
        fontSize = 14;
        iconSize = 16;
        horizontalPadding = HWYTheme.space4;
        verticalPadding = HWYTheme.space2;
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(HWYTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: textColor),
            const SizedBox(width: HWYTheme.space1),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// lib/design_system/atoms/hwy_card.dart
class HWYCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool hasShadow;
  final Color? backgroundColor;

  const HWYCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.hasShadow = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(HWYTheme.space4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(HWYTheme.radiusLarge),
        border: Border.all(color: HWYTheme.neutral200),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: HWYTheme.neutral900.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HWYTheme.radiusLarge),
        child: card,
      );
    }

    return card;
  }
}

// lib/design_system/atoms/hwy_icon_button.dart
enum HWYIconButtonVariant {
  primary,
  secondary,
  ghost,
  danger,
}

enum HWYIconButtonSize {
  small,
  medium,
  large,
}

class HWYIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final HWYIconButtonVariant variant;
  final HWYIconButtonSize size;
  final String? tooltip;

  const HWYIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = HWYIconButtonVariant.primary,
    this.size = HWYIconButtonSize.medium,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    
    double buttonSize;
    double iconSize;
    
    switch (size) {
      case HWYIconButtonSize.small:
        buttonSize = 32;
        iconSize = 16;
        break;
      case HWYIconButtonSize.medium:
        buttonSize = 40;
        iconSize = 20;
        break;
      case HWYIconButtonSize.large:
        buttonSize = 48;
        iconSize = 24;
        break;
    }
    
    Color backgroundColor;
    Color iconColor;
    
    switch (variant) {
      case HWYIconButtonVariant.primary:
        backgroundColor = disabled ? HWYTheme.neutral300 : HWYTheme.primaryBlue;
        iconColor = Colors.white;
        break;
      case HWYIconButtonVariant.secondary:
        backgroundColor = disabled ? HWYTheme.neutral200 : HWYTheme.neutral700;
        iconColor = Colors.white;
        break;
      case HWYIconButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        iconColor = disabled ? HWYTheme.neutral400 : HWYTheme.primaryBlue;
        break;
      case HWYIconButtonVariant.danger:
        backgroundColor = disabled ? HWYTheme.neutral300 : HWYTheme.accentRed;
        iconColor = Colors.white;
        break;
    }
    
    final button = SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: IconButton(
        onPressed: disabled ? null : onPressed,
        icon: Icon(icon, size: iconSize),
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: iconColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: iconColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

// lib/design_system/atoms/hwy_divider.dart
class HWYDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;

  const HWYDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? HWYTheme.space4,
      thickness: thickness ?? 1,
      color: color ?? HWYTheme.neutral200,
    );
  }
}

// lib/design_system/atoms/hwy_avatar.dart
enum HWYAvatarSize {
  small,
  medium,
  large,
  xlarge,
}

class HWYAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final HWYAvatarSize size;
  final Color? backgroundColor;

  const HWYAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = HWYAvatarSize.medium,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    double avatarSize;
    double fontSize;
    
    switch (size) {
      case HWYAvatarSize.small:
        avatarSize = 32;
        fontSize = 14;
        break;
      case HWYAvatarSize.medium:
        avatarSize = 40;
        fontSize = 16;
        break;
      case HWYAvatarSize.large:
        avatarSize = 56;
        fontSize = 20;
        break;
      case HWYAvatarSize.xlarge:
        avatarSize = 80;
        fontSize = 28;
        break;
    }
    
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? HWYTheme.primaryBlue,
        shape: BoxShape.circle,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initials ?? '?',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}

// lib/design_system/atoms/hwy_chip.dart
class HWYChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const HWYChip({
    super.key,
    required this.label,
    this.icon,
    this.onDelete,
    this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HWYTheme.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HWYTheme.space3,
          vertical: HWYTheme.space2,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? HWYTheme.neutral200,
          borderRadius: BorderRadius.circular(HWYTheme.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: textColor ?? HWYTheme.neutral700,
              ),
              const SizedBox(width: HWYTheme.space2),
            ],
            Text(
              label,
              style: HWYTheme.textTheme.bodySmall?.copyWith(
                color: textColor ?? HWYTheme.neutral700,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: HWYTheme.space2),
                InkWell(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: textColor ?? HWYTheme.neutral700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// lib/design_system/atoms/hwy_checkbox.dart
class HWYCheckbox extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;
  final String? label;
  final bool disabled;

  const HWYCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: disabled ? null : (val) => onChanged(val ?? false),
              activeColor: HWYTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HWYTheme.radiusSmall),
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: HWYTheme.space2),
            Text(
              label!,
              style: HWYTheme.textTheme.bodyMedium?.copyWith(
                color: disabled ? HWYTheme.neutral400 : HWYTheme.neutral800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// lib/design_system/atoms/hwy_radio.dart
class HWYRadio<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final Function(T) onChanged;
  final String? label;
  final bool disabled;

  const HWYRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: disabled ? null : (val) => onChanged(val as T),
              activeColor: HWYTheme.primaryBlue,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: HWYTheme.space2),
            Text(
              label!,
              style: HWYTheme.textTheme.bodyMedium?.copyWith(
                color: disabled ? HWYTheme.neutral400 : HWYTheme.neutral800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// lib/design_system/atoms/hwy_switch.dart
class HWYSwitch extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;
  final String? label;
  final bool disabled;

  const HWYSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: HWYTheme.textTheme.bodyMedium?.copyWith(
              color: disabled ? HWYTheme.neutral400 : HWYTheme.neutral800,
            ),
          ),
          const SizedBox(width: HWYTheme.space3),
        ],
        SizedBox(
          height: 24,
          child: Switch(
            value: value,
            onChanged: disabled ? null : onChanged,
            activeColor: HWYTheme.primaryBlue,
          ),
        ),
      ],
    );
  }
}

// lib/design_system/atoms/hwy_dropdown.dart
class HWYDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final String? label;
  final String? hint;
  final String Function(T) itemLabel;
  final bool disabled;

  const HWYDropdown({
    super.key,
    this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    required this.itemLabel,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: HWYTheme.textTheme.labelMedium?.copyWith(
              color: HWYTheme.neutral700,
            ),
          ),
          const SizedBox(height: HWYTheme.space2),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: HWYTheme.space4),
          decoration: BoxDecoration(
            color: disabled ? HWYTheme.neutral100 : Colors.white,
            border: Border.all(color: HWYTheme.neutral300),
            borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
          ),
          child: DropdownButton<T>(
            value: value,
            hint: hint != null
                ? Text(
                    hint!,
                    style: HWYTheme.textTheme.bodyMedium?.copyWith(
                      color: HWYTheme.neutral400,
                    ),
                  )
                : null,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.keyboard_arrow_down, color: HWYTheme.neutral500),
            style: HWYTheme.textTheme.bodyMedium,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              );
            }).toList(),
            onChanged: disabled ? null : onChanged,
          ),
        ),
      ],
    );
  }
}

// lib/design_system/atoms/hwy_loading_spinner.dart
enum HWYLoadingSize {
  small,
  medium,
  large,
}

class HWYLoadingSpinner extends StatelessWidget {
  final HWYLoadingSize size;
  final Color? color;

  const HWYLoadingSpinner({
    super.key,
    this.size = HWYLoadingSize.medium,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    double spinnerSize;
    double strokeWidth;
    
    switch (size) {
      case HWYLoadingSize.small:
        spinnerSize = 16;
        strokeWidth = 2;
        break;
      case HWYLoadingSize.medium:
        spinnerSize = 24;
        strokeWidth = 3;
        break;
      case HWYLoadingSize.large:
        spinnerSize = 40;
        strokeWidth = 4;
        break;
    }
    
    return SizedBox(
      width: spinnerSize,
      height: spinnerSize,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? HWYTheme.primaryBlue,
        ),
      ),
    );
  }
}

// lib/design_system/atoms/hwy_progress_bar.dart
class HWYProgressBar extends StatelessWidget {
  final double value;
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;
  final bool showLabel;

  const HWYProgressBar({
    super.key,
    required this.value,
    this.backgroundColor,
    this.progressColor,
    this.height = 8,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? HWYTheme.neutral200,
            borderRadius: BorderRadius.circular(HWYTheme.radiusFull),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedValue,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor ?? HWYTheme.primaryBlue,
                borderRadius: BorderRadius.circular(HWYTheme.radiusFull),
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: HWYTheme.space2),
          Text(
            '${(clampedValue * 100).toStringAsFixed(0)}%',
            style: HWYTheme.textTheme.bodySmall?.copyWith(
              color: HWYTheme.neutral600,
            ),
          ),
        ],
      ],
    );
  }
}

// lib/design_system/atoms/hwy_alert.dart
enum HWYAlertVariant {
  info,
  success,
  warning,
  danger,
}

class HWYAlert extends StatelessWidget {
  final String title;
  final String? description;
  final HWYAlertVariant variant;
  final VoidCallback? onDismiss;

  const HWYAlert({
    super.key,
    required this.title,
    this.description,
    this.variant = HWYAlertVariant.info,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData icon;
    
    switch (variant) {
      case HWYAlertVariant.info:
        backgroundColor = HWYTheme.statusInfo.withOpacity(0.1);
        borderColor = HWYTheme.statusInfo;
        iconColor = HWYTheme.statusInfo;
        icon = Icons.info_outline;
        break;
      case HWYAlertVariant.success:
        backgroundColor = HWYTheme.statusActive.withOpacity(0.1);
        borderColor = HWYTheme.statusActive;
        iconColor = HWYTheme.statusActive;
        icon = Icons.check_circle_outline;
        break;
      case HWYAlertVariant.warning:
        backgroundColor = HWYTheme.statusWarning.withOpacity(0.1);
        borderColor = HWYTheme.statusWarning;
        iconColor = HWYTheme.statusWarning;
        icon = Icons.warning_amber_outlined;
        break;
      case HWYAlertVariant.danger:
        backgroundColor = HWYTheme.statusDanger.withOpacity(0.1);
        borderColor = HWYTheme.statusDanger;
        iconColor = HWYTheme.statusDanger;
        icon = Icons.error_outline;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(HWYTheme.space4),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: HWYTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HWYTheme.textTheme.titleSmall?.copyWith(
                    color: iconColor,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: HWYTheme.space1),
                  Text(
                    description!,
                    style: HWYTheme.textTheme.bodySmall?.copyWith(
                      color: HWYTheme.neutral700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: HWYTheme.space2),
            HWYIconButton(
              icon: Icons.close,
              onPressed: onDismiss,
              variant: HWYIconButtonVariant.ghost,
              size: HWYIconButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }
}

// lib/design_system/atoms/hwy_tooltip.dart
class HWYTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const HWYTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      padding: const EdgeInsets.symmetric(
        horizontal: HWYTheme.space3,
        vertical: HWYTheme.space2,
      ),
      decoration: BoxDecoration(
        color: HWYTheme.neutral900,
        borderRadius: BorderRadius.circular(HWYTheme.radiusSmall),
      ),
      textStyle: HWYTheme.textTheme.bodySmall?.copyWith(
        color: Colors.white,
      ),
      child: child,
    );
  }
}

// lib/design_system/atoms/hwy_empty_state.dart
class HWYEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HWYEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HWYTheme.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: HWYTheme.neutral400,
            ),
            const SizedBox(height: HWYTheme.space4),
            Text(
              title,
              style: HWYTheme.textTheme.titleLarge?.copyWith(
                color: HWYTheme.neutral700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HWYTheme.space2),
            Text(
              description,
              style: HWYTheme.textTheme.bodyMedium?.copyWith(
                color: HWYTheme.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: HWYTheme.space6),
              HWYButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}