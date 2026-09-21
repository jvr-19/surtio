import 'package:flutter/material.dart';

abstract final class AppColors {
  // Fondos
  static const background = Color(0xFF03141D);
  static const backgroundDeep = Color(0xFF021018);

  // Superficies / tarjetas
  static const surface = Color(0xFF071820);
  static const surfaceElevated = Color(0xFF102630);
  static const surfaceSoft = Color(0xFF142B35);

  // Surtio
  static const primary = Color(0xFF32F5A6);
  static const primaryStrong = Color(0xFF19E895);
  static const secondary = Color(0xFF20DCC4);

  // Texto
  static const textPrimary = Color(0xFFF6FAFC);
  static const textSecondary = Color(0xFFA7BAC3);
  static const textMuted = Color(0xFF718791);

  // Bordes
  static const border = Color(0xFF203B47);
  static const borderStrong = Color(0xFF2A5362);

  // Estados
  static const warning = Color(0xFFFFE600);
  static const danger = Color(0xFFFF5C67);

  // Elementos sobre mapa
  static const mapMarker = Color(0xFF0B1B24);
  static const mapMarkerSelected = primary;
}
