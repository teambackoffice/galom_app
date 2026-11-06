import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_detail_controller.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/widgets/state_views.dart';

/// Scaffold for API-backed detail screens: owns a [ManagerDetailController],
/// loads once, and renders loading / error / content states.
class ManagerDetailScaffold<T> extends StatefulWidget {
  const ManagerDetailScaffold({
    super.key,
    required this.title,
    required this.loader,
    required this.builder,
  });

  final String title;
  final Future<T> Function() loader;
  final List<Widget> Function(BuildContext context, T data) builder;

  @override
  State<ManagerDetailScaffold<T>> createState() =>
      _ManagerDetailScaffoldState<T>();
}

class _ManagerDetailScaffoldState<T> extends State<ManagerDetailScaffold<T>> {
  late final ManagerDetailController<T> _controller =
      ManagerDetailController<T>(widget.loader)..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final c = _controller;
          if (c.isLoading && c.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (c.error != null && c.data == null) {
            return Center(
              child: SingleChildScrollView(
                child: ManagerErrorState(error: c.error!, onRetry: c.load),
              ),
            );
          }
          final data = c.data;
          if (data == null) return const SizedBox.shrink();
          return RefreshIndicator(
            onRefresh: c.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                MSpace.lg,
                MSpace.sm,
                MSpace.lg,
                MSpace.xxl,
              ),
              children: widget.builder(context, data),
            ),
          );
        },
      ),
    );
  }
}

/// Navy hero card at the top of a detail screen.
class DetailHeroCard extends StatelessWidget {
  const DetailHeroCard({
    super.key,
    required this.overline,
    required this.title,
    this.subtitle,
    this.status,
    this.amountLabel,
    this.amount,
    this.footer,
  });

  final String overline;
  final String title;
  final String? subtitle;
  final Widget? status;
  final String? amountLabel;
  final String? amount;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final faded = Colors.white.withValues(alpha: 0.68);
    return Container(
      margin: const EdgeInsets.only(bottom: MSpace.md),
      padding: const EdgeInsets.all(MSpace.xl),
      decoration: BoxDecoration(
        color: MColors.navy,
        borderRadius: BorderRadius.circular(MSpace.radius + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overline.toUpperCase(),
                      style: TextStyle(
                        color: faded,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(color: faded, fontSize: 13.5),
                      ),
                    ],
                  ],
                ),
              ),
              if (status != null) ...[
                const SizedBox(width: MSpace.sm),
                status!,
              ],
            ],
          ),
          if (amount != null) ...[
            const SizedBox(height: MSpace.lg),
            if (amountLabel != null)
              Text(amountLabel!, style: TextStyle(color: faded, fontSize: 12)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
          if (footer != null) ...[const SizedBox(height: MSpace.md), footer!],
        ],
      ),
    );
  }
}
