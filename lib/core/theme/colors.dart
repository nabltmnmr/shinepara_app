import 'package:flutter/material.dart';

/// Global Shine design tokens, matching the new luxury dark UI.
class AppColors {
  // Core brand colors
  // Updated to match latest provided palette.
  static const Color primary = Color(0xFFF95317); // Shine word / selected accents
  static const Color primaryLight = Color(0xFFED5F23); // View All
  static const Color viewAll = Color(0xFFED5F23);
  static const Color appBarBackground = Color(0xFF2B130F);
  static const Color bottomNavBackground = Color(0xFF2B1410);
  static const Color iconTint = Color(0xFF9E7B72);
  static const Color brandCircleBackground = Color(0xFF5D5D5D);

  // Background & surfaces
  static const Color background = Color(0xFF2D1714); // page background
  static const Color backgroundLight = Color(0xFFF8F6F6); // background-light (for optional light sections)
  // Optional slight variation for cards/elevation layers per spec
  static const Color surfaceDark = Color(0xFF2B1410); // bottom nav base / dark surfaces
  static const Color surfaceDarker = Color(0xFF2B1410);
  static const Color surfaceLight = Color(0xFF331A16);
  static const Color surfaceHighlight = Color(0xFF3A1E19);
  static const Color cardBottomPanel = Color(0xFF2D1F1A); // product card bottom section
  static const Color productDetailsTabsBg = Color(0xFF2D201C); // product details segmented background

  // Text
  /// Warm off-white (avoid pure white).
  static const Color textPrimary = Color(0xFFF5EEE9); // section titles
  static const Color textSecondary = Color(0xFFB9A49D);
  static const Color textMuted = Color(0xFF9E7B72); // icon-ish muted tone

  /// Explicit alias used by some widgets/specs.
  static const Color textOffWhite = textPrimary;

  // Utility colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color divider = Color(0x26FFFFFF); // white with low opacity
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);

  // Accents
  static const Color accentGold = Color(0xFFC6A87C);
  static const Color whatsappGreen = Color(0xFF25D366);

  // AI assistant/chat bubbles
  static const Color aiAssistant = Color(0xFF182026); // chat-bubble-ai
  static const Color aiAssistantUser = Color(0xFF382823); // chat-bubble-user

  // Legacy aliases kept for existing widgets (to avoid breaking references)
  static const Color sectionHeader = surfaceDark;
  static const Color primaryDark = primaryLight;
  static const Color accent = primary;
  static const Color textLight = textMuted;
  static const Color cardBackground = surfaceDark;
  static const Color aiAssistantLight = surfaceDark;
  static const Color userMessage = aiAssistantUser;
  static const Color aiMessage = aiAssistant;
}
