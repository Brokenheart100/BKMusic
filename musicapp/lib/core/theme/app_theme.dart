import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 提取自截图的配色
  static const Color background = Color(0xFF1D2123); // 极深灰背景
  static const Color surface = Color(0xFF1A1E1F); // 侧边栏/底栏背景
  static const Color cardColor = Color(0xFF303437); // 歌曲卡片背景 (稍亮)
  static const Color primary = Color(0xFFFACD66); // 金黄色强调色
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA4C7C6); // 灰调文字

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,

      textTheme:
          GoogleFonts.quicksandTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        surface: surface,
        surfaceContainerHighest: cardColor, // 用于卡片背景
        onSurface: textPrimary,
        primary: primary,
        secondary: const Color(0xFFEFEEE0),
      ),

      // 图标主题
      iconTheme: const IconThemeData(color: textSecondary),

      // 滑块主题 (适配截图底部的黄色进度条)
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        thumbColor: primary,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: SliderComponentShape.noOverlay,
      ),
    );
  }
}
