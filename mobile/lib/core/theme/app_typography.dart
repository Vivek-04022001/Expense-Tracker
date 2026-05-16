import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTypography {
  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
    // display — hero balance
    displayLarge: GoogleFonts.inter(
      fontSize: 40,
      height: 48 / 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    // h1 — screen titles
    headlineLarge: GoogleFonts.inter(
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    // h2 — section headers
    headlineMedium: GoogleFonts.inter(
      fontSize: 22,
      height: 30 / 22,
      fontWeight: FontWeight.w600,
    ),
    // h3 — card titles
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      height: 26 / 18,
      fontWeight: FontWeight.w600,
    ),
    // body default
    bodyLarge: GoogleFonts.inter(
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w400,
    ),
    // body emphasis
    bodyMedium: GoogleFonts.inter(
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w600,
    ),
    // caption / metadata
    bodySmall: GoogleFonts.inter(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
    ),
    // micro — tags, pills
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      height: 16 / 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    ),
  );

  // Amount-specific styles (tabular nums for ₹ figures)
  static TextStyle amountLarge(Color color) => GoogleFonts.inter(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: -0.5,
  );

  static TextStyle amountMedium(Color color) => GoogleFonts.inter(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
