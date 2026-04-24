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
}
