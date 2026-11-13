import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Paleta da marca baseada nas variáveis CSS de santigrill.com.br
/// (`--color-primary #d10d0d`, rodapé `#ededef`, textos `#575663`), com
/// tons derivados para contraste AA nos temas claro e escuro.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.red,
    required this.darkRed,
    required this.redSoft,
    required this.ink,
    required this.muted,
    required this.canvas,
    required this.surface,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.info,
    required this.infoSoft,
    required this.purple,
    required this.neutralSoft,
    required this.border,
  });

  final Brightness brightness;
  final Color red;
  final Color darkRed;
  final Color redSoft;
  final Color ink;
  final Color muted;
  final Color canvas;
  final Color surface;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color info;
  final Color infoSoft;
  final Color purple;
  final Color neutralSoft;
  final Color border;

  static const light = AppPalette(
    brightness: Brightness.light,
    red: Color(0xFFD10D0D),
    darkRed: Color(0xFF9E0A0A),
    redSoft: Color(0xFFFBE3E3),
    ink: Color(0xFF2F2E36),
    muted: Color(0xFF65646F),
    canvas: Color(0xFFF4F4F6),
    surface: Color(0xFFFFFFFF),
    success: Color(0xFF1C7D33),
    successSoft: Color(0xFFE3F5E6),
    warning: Color(0xFFA35F00),
    warningSoft: Color(0xFFFFF0D9),
    info: Color(0xFF2F6495),
    infoSoft: Color(0xFFE7F1FA),
    purple: Color(0xFF6A55A5),
    neutralSoft: Color(0xFFEFEFF2),
    border: Color(0xFFE1E1E6),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    red: Color(0xFFFF5A52),
    darkRed: Color(0xFFFF8A80),
    redSoft: Color(0xFF4A1A1A),
    ink: Color(0xFFECECF1),
    muted: Color(0xFFA9A8B4),
    canvas: Color(0xFF131317),
    surface: Color(0xFF1E1E24),
    success: Color(0xFF6BD48A),
    successSoft: Color(0xFF173322),
    warning: Color(0xFFFFB95C),
    warningSoft: Color(0xFF3A2A12),
    info: Color(0xFF8CB8E8),
    infoSoft: Color(0xFF1B2A3A),
    purple: Color(0xFFB7A6EE),
    neutralSoft: Color(0xFF2A2A31),
    border: Color(0xFF34343C),
  );
}

/// Cores em uso. Acompanham o tema ativo (claro/escuro): o app troca a
/// paleta em [AppColors.usePalette] e reconstrói a árvore de widgets.
abstract final class AppColors {
  static AppPalette _palette = AppPalette.light;

  static AppPalette get palette => _palette;
  static bool get isDark => _palette.brightness == Brightness.dark;

  /// Devolve true se a paleta mudou.
  static bool usePalette(AppPalette palette) {
    if (identical(_palette, palette)) return false;
    _palette = palette;
    return true;
  }

  static Color get red => _palette.red;
  static Color get darkRed => _palette.darkRed;
  static Color get redSoft => _palette.redSoft;
  static Color get ink => _palette.ink;
  static Color get muted => _palette.muted;
  static Color get canvas => _palette.canvas;
  static Color get surface => _palette.surface;
  static Color get success => _palette.success;
  static Color get successSoft => _palette.successSoft;
  static Color get warning => _palette.warning;
  static Color get warningSoft => _palette.warningSoft;
  static Color get info => _palette.info;
  static Color get infoSoft => _palette.infoSoft;
  static Color get purple => _palette.purple;
  static Color get neutralSoft => _palette.neutralSoft;
  static Color get border => _palette.border;

  /// Vermelho da marca fixo (logo, botões sobre fundo vermelho).
  static const brandRed = Color(0xFFD10D0D);
}

abstract final class AppTheme {
  static ThemeData get light => build(AppPalette.light);
  static ThemeData get dark => build(AppPalette.dark);

  static ThemeData build(AppPalette p) {
    final isDark = p.brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandRed,
      brightness: p.brightness,
      surface: p.surface,
    );
    final buttonRed = isDark ? const Color(0xFFE5302A) : p.red;

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme.copyWith(
        primary: buttonRed,
        onPrimary: Colors.white,
        surface: p.surface,
        onSurface: p.ink,
        outline: p.border,
      ),
      scaffoldBackgroundColor: p.canvas,
      fontFamily: 'OpenSans',
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.red, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: buttonRed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.red,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: p.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'OpenSans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.red),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: p.surface,
        indicatorColor: p.redSoft,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.red : p.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'OpenSans',
            color: states.contains(WidgetState.selected) ? p.red : p.muted,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: p.border,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Reconstrói toda a árvore abaixo de [context] (usado ao trocar a paleta,
/// já que [AppColors] é lida diretamente pelos widgets).
void rebuildAllChildren(BuildContext context) {
  void rebuild(Element element) {
    element
      ..markNeedsBuild()
      ..visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}
