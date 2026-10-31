import 'package:flutter/material.dart';
import 'package:location_tracker_app/service/manager_service.dart';
import 'package:location_tracker_app/view/manager/manager_session.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:shimmer/shimmer.dart';

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.actions = const [],
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: iconColor),
          ),
          const SizedBox(height: MSpace.lg),
          Text(title, textAlign: TextAlign.center, style: MText.section),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: MText.meta.copyWith(fontSize: 13.5, height: 1.4),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: MSpace.lg),
            Wrap(
              spacing: MSpace.sm,
              runSpacing: MSpace.sm,
              alignment: WrapAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class ManagerEmptyState extends StatelessWidget {
  const ManagerEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'No records found',
    this.filtered = false,
    this.onClearFilters,
  });

  final IconData icon;
  final String title;
  final bool filtered;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      iconColor: MColors.textMuted,
      title: title,
      message: filtered
          ? 'Try clearing filters or choosing a different date range.'
          : 'Records will appear here once your team adds them.',
      actions: [
        if (filtered && onClearFilters != null)
          OutlinedButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Clear filters'),
          ),
      ],
    );
  }
}

/// Error view. Session-expired and no-access errors offer sign-out instead
/// of a pointless retry.
class ManagerErrorState extends StatelessWidget {
  const ManagerErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final ManagerApiException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error.isSessionExpired || error.isForbidden) {
      return _StateLayout(
        icon: error.isSessionExpired
            ? Icons.lock_clock_outlined
            : Icons.lock_outline,
        iconColor: MColors.orange,
        title: error.isSessionExpired
            ? 'Session expired'
            : 'You do not have manager access',
        message: error.message,
        actions: [
          FilledButton(
            onPressed: () => managerSignOut(context),
            child: const Text('Sign in again'),
          ),
        ],
      );
    }
    return _StateLayout(
      icon: Icons.cloud_off_rounded,
      iconColor: MColors.red,
      title: 'Something went wrong',
      message: error.message,
      actions: [
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

/// Shimmering placeholder cards for list loading.
class ManagerSkeletonList extends StatelessWidget {
  const ManagerSkeletonList({super.key, this.count = 6, this.padding});

  final int count;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9EDF3),
      highlightColor: const Color(0xFFF7F9FC),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding ?? const EdgeInsets.all(MSpace.lg),
        itemCount: count,
        itemBuilder: (_, i) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: MSpace.md),
      padding: const EdgeInsets.all(MSpace.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(MSpace.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [bar(110, 10), const Spacer(), bar(70, 18)]),
          const SizedBox(height: 12),
          bar(190, 14),
          const SizedBox(height: 10),
          bar(150, 10),
          const SizedBox(height: 14),
          Row(children: [bar(80, 10), const Spacer(), bar(90, 14)]),
        ],
      ),
    );
  }
}

/// Footer of a paginated list: loader, inline retry, or end marker.
class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    super.key,
    required this.isLoading,
    required this.error,
    required this.hasMore,
    required this.onRetry,
    required this.shown,
  });

  final bool isLoading;
  final String? error;
  final bool hasMore;
  final VoidCallback onRetry;
  final int shown;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: MText.meta.copyWith(color: MColors.red),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (!hasMore && shown > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Showing all $shown',
            style: MText.meta.copyWith(color: MColors.textMuted),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}
