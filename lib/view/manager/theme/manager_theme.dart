import 'package:flutter/material.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';

/// Colour, spacing and type tokens for the Manager experience.
/// Keeps the Galom navy brand, paired with a calmer indigo accent.
class MColors {
  static const navy = Color(0xFF0D1B3E);
  static const navySoft = Color(0xFF1A2B55);
  static const accent = Color(0xFF0F766E);
  static const accentSoft = Color(0xFFE6F2F0);

  static const background = Color(0xFFF4F6FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE4E8F0);
  static const divider = Color(0xFFEEF1F5);

  static const textPrimary = Color(0xFF101828);
  static const textSecondary = Color(0xFF526070);
  static const textMuted = Color(0xFF8590A2);

  static const green = Color(0xFF15803D);
  static const greenBg = Color(0xFFE7F6EC);
  static const orange = Color(0xFFB45309);
  static const orangeBg = Color(0xFFFEF3E2);
  static const red = Color(0xFFC62828);
  static const redBg = Color(0xFFFDECEC);
  static const purple = Color(0xFF6D28D9);
  static const purpleBg = Color(0xFFF1EBFE);
  static const grey = Color(0xFF5B6779);
  static const greyBg = Color(0xFFEEF1F5);
}

class MSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const radius = 16.0;
  static const radiusSm = 12.0;
}

class MText {
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: MColors.textPrimary,
    letterSpacing: -0.3,
  );
  static const section = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: MColors.textPrimary,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: MColors.textPrimary,
    height: 1.25,
  );
  static const body = TextStyle(
    fontSize: 14,
    color: MColors.textPrimary,
    height: 1.35,
  );
  static const meta = TextStyle(fontSize: 12.5, color: MColors.textSecondary);
  static const label = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: MColors.textMuted,
    letterSpacing: 0.3,
  );
  static const docNo = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: MColors.textMuted,
    letterSpacing: 0.2,
  );
  static const amount = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: MColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

class ManagerTheme {
  static ThemeData of(BuildContext context) {
    final base = Theme.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: MColors.accent,
      primary: MColors.accent,
      surface: MColors.surface,
      brightness: Brightness.light,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: MColors.background,
      dividerColor: MColors.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: MColors.background,
        foregroundColor: MColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: MColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: MColors.textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MSpace.radiusSm),
          borderSide: const BorderSide(color: MColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MSpace.radiusSm),
          borderSide: const BorderSide(color: MColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MSpace.radiusSm),
          borderSide: const BorderSide(color: MColors.accent, width: 1.4),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: MColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: MColors.navy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MSpace.radiusSm),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MColors.accent,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: MColors.accent,
        unselectedLabelColor: MColors.textSecondary,
        indicatorColor: MColors.accent,
        dividerColor: MColors.border,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabAlignment: TabAlignment.start,
      ),
    );
  }
}

/// Visual identity for each module (icon + tint).
extension ManagerModuleStyle on ManagerModule {
  IconData get icon => switch (this) {
    ManagerModule.attendance => Icons.how_to_reg_rounded,
    ManagerModule.visits => Icons.storefront_rounded,
    ManagerModule.salesOrders => Icons.shopping_bag_outlined,
    ManagerModule.salesReturns => Icons.assignment_return_outlined,
    ManagerModule.salesInvoices => Icons.receipt_long_rounded,
    ManagerModule.payments => Icons.payments_outlined,
  };

  Color get tint => switch (this) {
    ManagerModule.attendance => MColors.accent,
    ManagerModule.visits => const Color(0xFF2563EB),
    ManagerModule.salesOrders => const Color(0xFF4F46E5),
    ManagerModule.salesReturns => MColors.purple,
    ManagerModule.salesInvoices => const Color(0xFFB45309),
    ManagerModule.payments => MColors.green,
  };

  String get tagline => switch (this) {
    ManagerModule.attendance => 'Track team attendance',
    ManagerModule.visits => 'Review field activities',
    ManagerModule.salesOrders => 'Monitor customer orders',
    ManagerModule.salesReturns => 'Review returned transactions',
    ManagerModule.salesInvoices => 'Billing and outstanding',
    ManagerModule.payments => 'Customer collections',
  };

  String get shortTitle => switch (this) {
    ManagerModule.attendance => 'Attendance',
    ManagerModule.visits => 'Visits',
    ManagerModule.salesOrders => 'Orders',
    ManagerModule.salesReturns => 'Returns',
    ManagerModule.salesInvoices => 'Invoices',
    ManagerModule.payments => 'Payments',
  };
}

/// Opens a manager page on the root navigator with the manager theme applied.
Future<T?> pushManagerPage<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (ctx) => Theme(data: ManagerTheme.of(ctx), child: page),
    ),
  );
}
