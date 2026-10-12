import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _graphite = Color(0xFF1B2026);
const _orange = Color(0xFFFF5A1F);
const _deepOrange = Color(0xFFD9430D);
const _paper = Color(0xFFF2F3F1);
const _line = Color(0xFFE2E5E3);
const _muted = Color(0xFF69737C);

ThemeData buildTheme() {
  final headline = GoogleFonts.plusJakartaSansTextTheme();

  final scheme = ColorScheme.fromSeed(
    seedColor: _graphite,
    brightness: Brightness.light,
    primary: _graphite,
    secondary: _orange,
    tertiary: _deepOrange,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: _graphite,
    primaryContainer: const Color(0xFFF3F5F4),
    secondaryContainer: const Color(0xFFFFEDE4),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _paper,
    textTheme: headline,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: _paper,
      foregroundColor: _graphite,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: _graphite,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _line),
      ),
      shadowColor: const Color(0x1215181C),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _graphite, width: 1.5),
      ),
      hintStyle: const TextStyle(color: _muted),
      labelStyle: const TextStyle(color: _muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _graphite,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18))),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: _graphite,
      disabledColor: const Color(0xFFF2F3F1),
      side: const BorderSide(color: _line),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: const TextStyle(
        color: _graphite,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _orange,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFFFEDE4),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? _graphite : _muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? _graphite : _muted,
          )),
    ),
  );
}
