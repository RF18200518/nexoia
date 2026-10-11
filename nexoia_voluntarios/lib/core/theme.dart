import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const Color seed = Color(0xFF0E7C66);
  static const Color seedDark = Color(0xFF2DD4A3);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E7C66), Color(0xFF0B5D4E)],
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2DD4A3), Color(0xFF1BA87A)],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2F7F5), Color(0xFFE8F1EE)],
  );

  static const LinearGradient softGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F1E), Color(0xFF141817)],
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return _baseTheme(scheme, isDark: false);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedDark,
      brightness: Brightness.dark,
    );

    return _baseTheme(scheme, isDark: true);
  }

  static ThemeData _baseTheme(ColorScheme scheme, {required bool isDark}) {
    final surfaceColor = isDark ? const Color(0xFF121615) : const Color(0xFFF4F7F6);
    final cardColor = isDark ? const Color(0xFF1A1F1E) : Colors.white;
    final gradient = isDark ? heroGradientDark : heroGradient;
    final softGrad = isDark ? softGradientDark : softGradient;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaceColor,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyLarge: TextStyle(color: scheme.onSurface),
        bodyMedium: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 4 : 1,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: scheme.primaryContainer,
        elevation: 3,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: cardColor,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      extensions: [
        _CustomGradients(
          hero: gradient,
          soft: softGrad,
        ),
      ],
    );
  }
}

class _CustomGradients extends ThemeExtension<_CustomGradients> {
  final LinearGradient hero;
  final LinearGradient soft;

  const _CustomGradients({required this.hero, required this.soft});

  @override
  _CustomGradients copyWith({LinearGradient? hero, LinearGradient? soft}) {
    return _CustomGradients(hero: hero ?? this.hero, soft: soft ?? this.soft);
  }

  @override
  _CustomGradients lerp(ThemeExtension<_CustomGradients>? other, double t) {
    if (other is! _CustomGradients) return this;
    return _CustomGradients(
      hero: Gradient.lerp(hero, other.hero, t)! as LinearGradient,
      soft: Gradient.lerp(soft, other.soft, t)! as LinearGradient,
    );
  }
}

extension ThemeGradients on ThemeData {
  LinearGradient get heroGradient =>
      extension<_CustomGradients>()?.hero ?? AppTheme.heroGradient;
  LinearGradient get softGradient =>
      extension<_CustomGradients>()?.soft ?? AppTheme.softGradient;
}

class ThemeController extends ChangeNotifier {
  static const _key = 'is_dark_mode';
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeData get theme => _isDark ? AppTheme.dark() : AppTheme.light();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
    notifyListeners();
  }
}