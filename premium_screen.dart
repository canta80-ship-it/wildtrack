import 'package:flutter/material.dart';

ThemeData wildTrackTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? const Color(0xFFF0F4E8) : const Color(0xFF1C3527);
  final background = dark ? const Color(0xFF102B22) : const Color(0xFFF4F3EB);
  final surface = dark ? const Color(0xFF19392D) : const Color(0xFFFFFEF8);
  final line = dark ? const Color(0xFF315141) : const Color(0xFFDFE5D6);
  final primary = dark ? const Color(0xFFC4D4AE) : const Color(0xFF2A563C);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF173D30),
        brightness: brightness,
      ).copyWith(
        surface: background,
        surfaceContainerLow: surface,
        surfaceContainer: surface,
        primary: primary,
        onSurface: ink,
        outlineVariant: line,
        onSurfaceVariant: dark
            ? const Color(0xFFA9BD9F)
            : const Color(0xFF5E705C),
        primaryContainer: dark
            ? const Color(0xFF254936)
            : const Color(0xFFE6ECDC),
      );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(21),
    side: BorderSide(color: line),
  );
  return base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(
        fontFamily: 'WildTrackSerif',
        fontSize: 34,
        letterSpacing: -1.1,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontFamily: 'WildTrackSerif',
        fontSize: 28,
        letterSpacing: -.8,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontFamily: 'WildTrackSerif',
        fontSize: 24,
        letterSpacing: -.6,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -.4,
      ),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
      bodySmall: text.bodySmall?.copyWith(height: 1.5),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 1,
      shadowColor: const Color(0x15173D30),
      shape: rounded,
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
      height: 78,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: s.contains(WidgetState.selected)
              ? primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        backgroundColor: surface,
        foregroundColor: ink,
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: background,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF315141) : const Color(0xFF173D30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: BorderSide(color: line),
      selectedColor: scheme.primaryContainer,
      backgroundColor: surface,
    ),
    dividerTheme: DividerThemeData(color: line, space: 24),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PremiumPageTransitions(),
        TargetPlatform.iOS: PremiumPageTransitions(),
        TargetPlatform.linux: PremiumPageTransitions(),
      },
    ),
  );
}

class PremiumPageTransitions extends PageTransitionsBuilder {
  const PremiumPageTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curve = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: curve.drive(
          Tween(begin: const Offset(0, .025), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });
  final PreferredSizeWidget? appBar;
  final Widget? body, floatingActionButton, bottomNavigationBar;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      body: body == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: backgroundColor != null
                      ? [backgroundColor!, backgroundColor!]
                      : [
                          scheme.surface,
                          scheme.primaryContainer.withValues(alpha: .35),
                        ],
                ),
              ),
              child: body,
            ),
    );
  }
}

class PremiumHeading extends StatelessWidget {
  const PremiumHeading(this.title, {super.key, this.eyebrow = 'WILDTRACK'});
  final String title, eyebrow;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22, top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 9),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ],
    ),
  );
}

class PremiumFilledButton extends StatelessWidget {
  const PremiumFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });
  PremiumFilledButton.icon({
    super.key,
    required this.onPressed,
    required Widget icon,
    required Widget label,
    this.style,
  }) : child = Row(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           icon,
           const SizedBox(width: 8),
           Flexible(child: label),
         ],
       );
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final states = onPressed == null ? {WidgetState.disabled} : <WidgetState>{};
    final explicit = style?.backgroundColor?.resolve(states);
    final colors = explicit != null
        ? [explicit, explicit]
        : dark
        ? [const Color(0xFFC7D8AE), const Color(0xFF9FB982)]
        : [const Color(0xFF214E35), const Color(0xFF496E45)];
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: onPressed == null ? .45 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(colors: colors),
          boxShadow: onPressed == null
              ? []
              : [
                  const BoxShadow(
                    color: Color(0x16204428),
                    offset: Offset(0, 5),
                    blurRadius: 13,
                  ),
                ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: (style ?? const ButtonStyle()).copyWith(
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            foregroundColor:
                style?.foregroundColor ??
                WidgetStatePropertyAll(
                  dark ? const Color(0xFF193823) : const Color(0xFFF7F9EF),
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}
