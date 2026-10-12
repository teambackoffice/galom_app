import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/login_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_access_controller.dart';
import 'package:location_tracker_app/service/login_service.dart';
import 'package:location_tracker_app/view/login/login_page.dart';
import 'package:provider/provider.dart';

/// Ends the session using the app's existing logout mechanism (clearing
/// secure storage and the login flag), resets manager access, and returns
/// to the login screen with the back stack removed.
Future<void> managerSignOut(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final access = context.read<ManagerAccessController>();
  final login = context.read<LoginController>();

  await LoginService().logout();
  await login.logout();
  access.reset();

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (_) => false,
  );
}

Future<void> confirmManagerSignOut(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Sign out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) await managerSignOut(context);
}
