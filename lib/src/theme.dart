import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'types.dart';

/// Styling for root toasts, installed through [ThemeData.extensions].
///
/// Every field is optional. Unset fields fall back to values derived from
/// the ambient Material 3 [ColorScheme] and [TextTheme].
@immutable
class RootToastTheme extends ThemeExtension<RootToastTheme> {
  /// Creates a toast theme. Unset fields use the defaults.
  const RootToastTheme({
    this.successBackground,
    this.successForeground,
    this.errorBackground,
    this.errorForeground,
    this.infoBackground,
    this.infoForeground,
    this.warningBackground,
    this.warningForeground,
    this.textStyle,
    this.borderRadius,
    this.padding,
    this.elevation,
    this.maxWidth,
  });

  /// Default green used for success toasts (Material green 800).
  static const Color defaultSuccessBackground = Color(0xFF2E7D32);

  /// Default amber used for warning toasts.
  static const Color defaultWarningBackground = Color(0xFFB45309);

  /// Background of success toasts.
  final Color? successBackground;

  /// Text and icon colour of success toasts.
  final Color? successForeground;

  /// Background of error toasts. Defaults to [ColorScheme.error].
  final Color? errorBackground;

  /// Text and icon colour of error toasts. Defaults to [ColorScheme.onError].
  final Color? errorForeground;

  /// Background of info toasts. Defaults to [ColorScheme.inverseSurface].
  final Color? infoBackground;

  /// Text and icon colour of info toasts.
  /// Defaults to [ColorScheme.onInverseSurface].
  final Color? infoForeground;

  /// Background of warning toasts.
  final Color? warningBackground;

  /// Text and icon colour of warning toasts.
  final Color? warningForeground;

  /// Message text style. The colour is replaced by the type's foreground.
  final TextStyle? textStyle;

  /// Corner radius of the card.
  final BorderRadiusGeometry? borderRadius;

  /// Padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Card elevation.
  final double? elevation;

  /// Maximum card width, useful on tablets and desktop.
  final double? maxWidth;

  /// The theme from [context], with every unset field filled from the
  /// ambient [ColorScheme] and [TextTheme].
  static RootToastTheme resolve(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final defaults = RootToastTheme(
      successBackground: defaultSuccessBackground,
      successForeground: Colors.white,
      errorBackground: scheme.error,
      errorForeground: scheme.onError,
      infoBackground: scheme.inverseSurface,
      infoForeground: scheme.onInverseSurface,
      warningBackground: defaultWarningBackground,
      warningForeground: Colors.white,
      textStyle: theme.textTheme.bodyMedium
          ?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      elevation: 6,
      maxWidth: 560,
    );
    final custom = theme.extension<RootToastTheme>();
    return custom == null ? defaults : defaults._merge(custom);
  }

  /// The background colour for [type].
  Color? backgroundFor(RootToastType type) => switch (type) {
        RootToastType.success => successBackground,
        RootToastType.error => errorBackground,
        RootToastType.info => infoBackground,
        RootToastType.warning => warningBackground,
      };

  /// The text and icon colour for [type].
  Color? foregroundFor(RootToastType type) => switch (type) {
        RootToastType.success => successForeground,
        RootToastType.error => errorForeground,
        RootToastType.info => infoForeground,
        RootToastType.warning => warningForeground,
      };

  RootToastTheme _merge(RootToastTheme o) => copyWith(
        successBackground: o.successBackground,
        successForeground: o.successForeground,
        errorBackground: o.errorBackground,
        errorForeground: o.errorForeground,
        infoBackground: o.infoBackground,
        infoForeground: o.infoForeground,
        warningBackground: o.warningBackground,
        warningForeground: o.warningForeground,
        textStyle: textStyle?.merge(o.textStyle) ?? o.textStyle,
        borderRadius: o.borderRadius,
        padding: o.padding,
        elevation: o.elevation,
        maxWidth: o.maxWidth,
      );

  @override
  RootToastTheme copyWith({
    Color? successBackground,
    Color? successForeground,
    Color? errorBackground,
    Color? errorForeground,
    Color? infoBackground,
    Color? infoForeground,
    Color? warningBackground,
    Color? warningForeground,
    TextStyle? textStyle,
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry? padding,
    double? elevation,
    double? maxWidth,
  }) {
    return RootToastTheme(
      successBackground: successBackground ?? this.successBackground,
      successForeground: successForeground ?? this.successForeground,
      errorBackground: errorBackground ?? this.errorBackground,
      errorForeground: errorForeground ?? this.errorForeground,
      infoBackground: infoBackground ?? this.infoBackground,
      infoForeground: infoForeground ?? this.infoForeground,
      warningBackground: warningBackground ?? this.warningBackground,
      warningForeground: warningForeground ?? this.warningForeground,
      textStyle: textStyle ?? this.textStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      elevation: elevation ?? this.elevation,
      maxWidth: maxWidth ?? this.maxWidth,
    );
  }

  @override
  RootToastTheme lerp(covariant RootToastTheme? other, double t) {
    if (other == null) return this;
    return RootToastTheme(
      successBackground:
          Color.lerp(successBackground, other.successBackground, t),
      successForeground:
          Color.lerp(successForeground, other.successForeground, t),
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t),
      errorForeground: Color.lerp(errorForeground, other.errorForeground, t),
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t),
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t),
      warningBackground:
          Color.lerp(warningBackground, other.warningBackground, t),
      warningForeground:
          Color.lerp(warningForeground, other.warningForeground, t),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      borderRadius:
          BorderRadiusGeometry.lerp(borderRadius, other.borderRadius, t),
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t),
      elevation: lerpDouble(elevation, other.elevation, t),
      maxWidth: lerpDouble(maxWidth, other.maxWidth, t),
    );
  }
}
