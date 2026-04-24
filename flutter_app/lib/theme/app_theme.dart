import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimary,
        primary: kPrimary,
        surface: kSurface,
        onSurface: kOnSurface,
        surfaceContainerHighest: kSurfaceVariant,
        onSurfaceVariant: kOnSurfaceVariant,
      ),
      scaffoldBackgroundColor: kSurface,
      
      // Using Inter for smooth, premium typography
      textTheme: GoogleFonts.interTextTheme(),
      
      appBarTheme: AppBarTheme(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: kOnSurface,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        iconTheme: const IconThemeData(color: kOnSurface),
      ),
      
      // Bottom Navigation: NO pill indicator, transparent background
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kSurface,
        indicatorColor: Colors.transparent, // NO pill indicator — matches prototype
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kOnSurface,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: kOnSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: kOnSurface, size: 26);
          }
          return const IconThemeData(color: kOnSurfaceVariant, size: 26);
        }),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(kSurfaceVariant),
        elevation: WidgetStateProperty.all(0),
        hintStyle: WidgetStateProperty.all(
          GoogleFonts.inter(color: kOnSurfaceVariant, fontSize: 14),
        ),
        textStyle: WidgetStateProperty.all(
          GoogleFonts.inter(color: kOnSurface, fontSize: 15),
        ),
      ),
      
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 0.5,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimaryDark,
        primary: kPrimaryDark,
        surface: kSurfaceDark,
        onSurface: kOnSurfaceDark,
        surfaceContainerHighest: kSurfaceVariantDark,
        onSurfaceVariant: kOnSurfaceVariantDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: kSurfaceDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: kSurfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: kOnSurfaceDark,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        iconTheme: const IconThemeData(color: kOnSurfaceDark),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kSurfaceDark,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kOnSurfaceDark,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: kOnSurfaceVariantDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: kOnSurfaceDark, size: 26);
          }
          return const IconThemeData(color: kOnSurfaceVariantDark, size: 26);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(kSurfaceVariantDark),
        elevation: WidgetStateProperty.all(0),
        hintStyle: WidgetStateProperty.all(
          GoogleFonts.inter(color: kOnSurfaceVariantDark, fontSize: 14),
        ),
        textStyle: WidgetStateProperty.all(
          GoogleFonts.inter(color: kOnSurfaceDark, fontSize: 15),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 0.5,
      ),
    );
  }
}
