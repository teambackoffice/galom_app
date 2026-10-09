import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_nav_controller.dart';
import 'package:location_tracker_app/controller/manager/manager_profile_controller.dart';
import 'package:location_tracker_app/view/mainscreen/homepage.dart';
import 'package:location_tracker_app/view/manager/manager_session.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:provider/provider.dart';

/// Opens Profile & settings from the Home header. The page sits above the
/// shell, so the shell's controllers are handed to it explicitly.
Future<void> openManagerProfile(BuildContext context) {
  return pushManagerPage(
    context,
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: context.read<ManagerProfileController>(),
        ),
        ChangeNotifierProvider.value(
          value: context.read<ManagerNavController>(),
        ),
      ],
      child: const ManagerProfileScreen(),
    ),
  );
}

class ManagerProfileScreen extends StatelessWidget {
  const ManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ManagerProfileController>().profile;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Profile & settings'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : _body(context, p),
    );
  }

  Widget _body(BuildContext context, ManagerProfile p) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ProfileHeader(profile: p),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MSpace.lg,
            MSpace.lg,
            MSpace.lg,
            MSpace.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: 'Personal information',
                children: [
                  InfoRow('Full name', p.displayName),
                  if (p.employeeName != null && p.employeeName != p.displayName)
                    InfoRow('Employee name', p.employeeName!),
                  if (p.email != null)
                    InfoRow('Email', p.email!, copyable: true),
                  if (p.employeeId != null)
                    InfoRow('Employee ID', p.employeeId!, copyable: true),
                  if (p.branch != null) InfoRow('Branch', p.branch!),
                  if (p.roleProfile != null)
                    InfoRow('Role profile', p.roleProfile!),
                  if (p.salesPersonId != null)
                    InfoRow('Salesperson ID', p.salesPersonId!),
                ],
              ),
              _MenuCard(
                children: [
                  if (p.isAlsoSalesPerson)
                    _MenuTile(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Open salesperson app',
                      subtitle: 'Your own attendance, orders and invoices',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                      ),
                    ),
                  _MenuTile(
                    icon: Icons.event_note_outlined,
                    title: 'Leave requests',
                    subtitle: 'Review and approve team leave',
                    onTap: () {
                      // Back to the shell, then straight to the Leaves tab.
                      final nav = context.read<ManagerNavController>();
                      Navigator.of(context).pop();
                      nav.goTo(ManagerTab.leaves);
                    },
                  ),
                  _MenuTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Galom',
                    subtitle: 'App information and licences',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Galom',
                      applicationIcon: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/icon.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                      children: const [
                        Text('Sales team monitoring for Galom International.'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpace.md),
              _MenuCard(
                children: [
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    color: MColors.red,
                    onTap: () => confirmManagerSignOut(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final ManagerProfile profile;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final faded = Colors.white.withValues(alpha: 0.7);
    return Container(
      padding: EdgeInsets.fromLTRB(
        MSpace.xl,
        top + MSpace.xl,
        MSpace.xl,
        MSpace.xxl,
      ),
      decoration: const BoxDecoration(
        color: MColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ManagerAvatar(
              name: profile.displayName,
              size: 76,
              background: Colors.white,
              foreground: MColors.navy,
            ),
          ),
          const SizedBox(height: MSpace.md),
          Text(
            profile.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (profile.email != null) ...[
            const SizedBox(height: 3),
            Text(
              profile.email!,
              textAlign: TextAlign.center,
              style: TextStyle(color: faded, fontSize: 13.5),
            ),
          ],
          const SizedBox(height: MSpace.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: MSpace.sm,
            runSpacing: MSpace.sm,
            children: [
              const _HeaderPill(
                icon: Icons.verified_user_outlined,
                text: 'Manager',
                highlight: true,
              ),
              if (profile.employeeId != null)
                _HeaderPill(
                  icon: Icons.badge_outlined,
                  text: profile.employeeId!,
                ),
              if (profile.branch != null)
                _HeaderPill(
                  icon: Icons.apartment_rounded,
                  text: profile.branch!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.text,
    this.highlight = false,
  });
  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFAFC0FF).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? const Color(0xFFCFD8FF) : Colors.white70,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: highlight ? const Color(0xFFE3E8FF) : Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ManagerCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 60, color: MColors.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color = MColors.textPrimary,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color == MColors.textPrimary ? MColors.accent : color;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MSpace.lg,
        vertical: 2,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(MSpace.radiusSm),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!, style: MText.meta),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: MColors.textMuted,
      ),
    );
  }
}
