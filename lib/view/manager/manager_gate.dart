import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_access_controller.dart';
import 'package:location_tracker_app/view/mainscreen/homepage.dart';
import 'package:location_tracker_app/view/manager/manager_shell.dart';
import 'package:provider/provider.dart';

/// Post-login landing point. Asks the server (`get_manager_access`) whether
/// the user is a manager and shows the Manager experience if so; everyone
/// else gets the existing salesperson [MainScreen], unchanged.
class HomeGate extends StatefulWidget {
  const HomeGate({super.key});

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> {
  late final Future<bool> _isManager = context
      .read<ManagerAccessController>()
      .refresh();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isManager,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D1B3E),
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }
        return snap.data == true ? const ManagerShell() : const MainScreen();
      },
    );
  }
}
