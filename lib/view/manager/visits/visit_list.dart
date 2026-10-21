import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/manager/manager_list_controller.dart';
import 'package:location_tracker_app/modal/manager/manager_common_modal.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/visits/visit_detail.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';
import 'package:location_tracker_app/view/manager/widgets/module_list_view.dart';
import 'package:location_tracker_app/view/manager/widgets/status_chip.dart';
import 'package:provider/provider.dart';

/// Customer visit list (body of the Team → Visits tab).
class VisitListView extends StatelessWidget {
  const VisitListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagerModuleList<CustomerVisit>(
      controller: context.read<ManagerListController<CustomerVisit>>(),
      searchHint: 'Search customer or remarks',
      statuses: const [],
      emptyIcon: Icons.storefront_outlined,
      emptyTitle: 'No customer visits',
      summaryBuilder: (c) => [countItem(c.totalCount, 'Visits')],
      itemBuilder: (context, v) => VisitCard(
        visit: v,
        onTap: () =>
            pushManagerPage(context, ManagerVisitDetailScreen(visit: v)),
      ),
    );
  }
}

class VisitCard extends StatelessWidget {
  const VisitCard({super.key, required this.visit, this.onTap});

  final CustomerVisit visit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = visit;
    final when = v.visitedAt != null
        ? '${MFormat.shortDate(v.date)}, ${MFormat.time(v.visitedAt)}'
        : MFormat.date(v.date);
    final hasBadges =
        v.visitType.isNotEmpty || v.isFirstCounter || v.isLastCounter;

    return ManagerCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  v.customerName.isNotEmpty
                      ? v.customerName
                      : 'Unnamed customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MText.cardTitle,
                ),
              ),
              if (v.visitPhoto != null)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 16,
                    color: MColors.textMuted,
                    semanticLabel: 'Has photo',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${v.salesPersonDisplay}  ·  $when',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MText.meta,
          ),
          if (v.locationName != null) ...[
            const SizedBox(height: 4),
            MetaItem(
              Icons.place_outlined,
              v.locationName!,
              color: MColors.textSecondary,
            ),
          ],
          if (v.remarks.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              v.remarks,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MText.body.copyWith(
                fontSize: 13,
                color: MColors.textSecondary,
              ),
            ),
          ],
          if (hasBadges) ...[const SizedBox(height: 8), VisitBadges(visit: v)],
        ],
      ),
    );
  }
}

class VisitBadges extends StatelessWidget {
  const VisitBadges({super.key, required this.visit});
  final CustomerVisit visit;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (visit.visitType.isNotEmpty)
          MBadge(
            visit.visitType,
            icon: Icons.label_outline_rounded,
            color: ManagerModule.visits.tint,
          ),
        if (visit.isFirstCounter)
          const MBadge(
            'First Counter',
            icon: Icons.flag_outlined,
            color: MColors.green,
          ),
        if (visit.isLastCounter)
          const MBadge(
            'Last Counter',
            icon: Icons.sports_score_rounded,
            color: MColors.orange,
          ),
      ],
    );
  }
}
