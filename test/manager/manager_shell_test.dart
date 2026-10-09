import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracker_app/controller/login_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_access_controller.dart';
import 'package:location_tracker_app/view/manager/manager_shell.dart';
import 'package:location_tracker_app/view/manager/widgets/floating_nav_bar.dart';
import 'package:provider/provider.dart';

import 'mock_api.dart';

Future<void> _pumpShell(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // No sid stored: every API call fails fast as "session expired", which
  // lets us exercise navigation and error states without a network.
  FlutterSecureStorage.setMockInitialValues({'full_name': 'Meera Nair'});
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => ManagerAccessController()),
      ],
      child: const MaterialApp(home: ManagerShell()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in const [Size(320, 700), Size(412, 915)]) {
    testWidgets(
      'floating nav switches all six tabs; settings opens profile at ${size.width}px',
      (tester) async {
        await _pumpShell(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.text('Meera Nair'), findsOneWidget);

        Future<void> go(String label) async {
          await tester.tap(
            find.descendant(
              of: find.byType(FloatingNavBar),
              matching: find.bySemanticsLabel(label),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
        }

        await go('Attendance');
        expect(find.text('Daily check-ins across the team'), findsOneWidget);
        // No status filter on Attendance any more.
        expect(find.textContaining('All status'), findsNothing);
        // The previous tab must actually fade out, not stay painted beneath.
        final homeOpacity = tester.renderObject<RenderAnimatedOpacity>(
          find
              .ancestor(
                of: find.text('Quick access'),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        );
        expect(homeOpacity.opacity.value, 0);
        await go('Visits');
        expect(
          find.text('Field activity logged by salespersons'),
          findsOneWidget,
        );
        await go('Sales');
        expect(
          find.text('Orders, returns, invoices and collections'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Payments'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Payments'));
        await tester.pumpAndSettle();
        await go('Leaves');
        expect(find.text('Leave requests'), findsOneWidget);
        await go('Stock');
        expect(find.text('Inventory across warehouses'), findsOneWidget);

        // State is preserved: Sales re-opens on the Payments sub-tab.
        await go('Sales');
        final tabBar = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabBar.controller!.index, 3);

        // Back from a tab returns Home instead of leaving the app.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Quick access'), findsOneWidget);

        // Profile & settings opens from the Home header's settings button.
        await tester.tap(find.byTooltip('Profile & settings'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Sign out'), findsOneWidget);
        expect(find.text('Meera Nair'), findsWidgets);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Quick access'), findsOneWidget);
      },
    );
  }

  testWidgets('Leave Requests shortcut switches to the Leaves tab', (
    tester,
  ) async {
    await _pumpShell(tester, const Size(412, 915));
    await tester.ensureVisible(find.text('Leave Requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Leave requests'), findsOneWidget);
    expect(find.text('Session expired'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in const [320.0, 412.0]) {
    testWidgets(
      'pending badge shows on Leaves; labels never clip at ${width}px',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        FlutterSecureStorage.setMockInitialValues({});
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => LoginController()),
              ChangeNotifierProvider(create: (_) => ManagerAccessController()),
            ],
            child: MaterialApp(
              home: ManagerShell(
                service: mockService,
                leaveService: mockLeaveService,
                stockService: mockStockService,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Badge is ready on first screen, before Leaves was ever opened.
        expect(find.bySemanticsLabel('Leaves, 1 pending'), findsOneWidget);

        final bar = find.byType(FloatingNavBar);
        for (final label in ['Attendance', 'Leaves', 'Stock', 'Home']) {
          await tester.tap(
            find.descendant(
              of: bar,
              matching: find.bySemanticsLabel(RegExp('^$label')),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
          // Selected label is either fully shown or (if it can't fit) hidden;
          // never cut off.
          final text = find.descendant(of: bar, matching: find.text(label));
          if (text.evaluate().isNotEmpty) {
            final para = tester.renderObject<RenderParagraph>(text);
            expect(para.didExceedMaxLines, isFalse, reason: label);
            expect(
              para.size.width,
              greaterThanOrEqualTo(
                para.getMaxIntrinsicWidth(double.infinity) - 0.5,
              ),
              reason: label,
            );
          }
        }
      },
    );
  }
}
