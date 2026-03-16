import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Palette (base color palette)
  static const _grey900 = Color(0xFF333333);
  static const _grey800 = Color(0xFF444444);
  static const _grey700 = Color(0xFF555555);
  static const _grey600 = Color(0xFF666666);
  static const _grey500 = Color(0xFF999999);
  static const _grey400 = Color(0xFFD9D9D9);
  static const _grey300 = Color(0xFFE0E0E0);
  static const _grey200 = Color(0xFFEEEEEE);
  static const _grey100 = Color(0xFFF7F7F7);
  static const _white = Color(0xFFFFFFFF);

  static const _red600 = Color(0xFFD32F2F);
  static const _red50 = Color(0xFFFFF3F3);

  // Text & Icon (content)
  static const textPrimary = _grey900;
  static const textSecondary = _grey700;
  static const textCaption = _grey600;
  static const textHint = _grey500;
  static const textError = _red600;

  static const iconPrimary = _grey800;

  // Surface / Background (containers)
  static const pageBackground = _white;
  static const scaffoldBackground = _grey100;
  static const surface = _white;
  static const surfaceMuted = _grey200;
  static const errorSurface = _red50;

  // Border / Divider (separators)
  static const border = _grey400;
  static const divider = _grey300;
}
