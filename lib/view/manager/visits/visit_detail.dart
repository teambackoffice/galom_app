import 'package:flutter/material.dart';
import 'package:location_tracker_app/config/api_constant.dart';
import 'package:location_tracker_app/modal/manager/manager_records_modal.dart';
import 'package:location_tracker_app/service/manager_service.dart';
import 'package:location_tracker_app/view/manager/theme/manager_format.dart';
import 'package:location_tracker_app/view/manager/theme/manager_theme.dart';
import 'package:location_tracker_app/view/manager/visits/visit_list.dart';
import 'package:location_tracker_app/view/manager/widgets/detail_scaffold.dart';
import 'package:location_tracker_app/view/manager/widgets/manager_common.dart';

/// Visit detail is built from the list row; the API has no detail endpoint.
class ManagerVisitDetailScreen extends StatelessWidget {
  const ManagerVisitDetailScreen({super.key, required this.visit});

  final CustomerVisit visit;

  @override
  Widget build(BuildContext context) {
    final v = visit;
    return Scaffold(
      appBar: AppBar(title: const Text('Customer visit')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MSpace.lg,
          MSpace.sm,
          MSpace.lg,
          MSpace.xxl,
        ),
        children: [
          DetailHeroCard(
            overline: v.visitType.isNotEmpty ? v.visitType : 'Customer visit',
            title: v.customerName.isNotEmpty
                ? v.customerName
                : 'Unnamed customer',
            subtitle: 'by ${v.salesPersonDisplay}',
            footer: Wrap(
              spacing: MSpace.lg,
              runSpacing: MSpace.sm,
              children: [
                _HeroMeta(Icons.event_rounded, MFormat.weekdayDate(v.date)),
                if (v.visitedAt != null)
                  _HeroMeta(Icons.schedule_rounded, MFormat.time(v.visitedAt)),
                if (v.locationName != null)
                  _HeroMeta(Icons.place_outlined, v.locationName!),
              ],
            ),
          ),
          if (v.isFirstCounter || v.isLastCounter || v.visitType.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: MSpace.md),
              child: VisitBadges(visit: v),
            ),
          if (v.visitPhoto != null) _VisitPhoto(path: v.visitPhoto!),
          SectionCard(
            title: 'Remarks',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  v.remarks.isNotEmpty
                      ? v.remarks
                      : 'No remarks were added for this visit.',
                  style: v.remarks.isNotEmpty ? MText.body : MText.meta,
                ),
              ),
            ],
          ),
          SectionCard(
            title: 'Visit details',
            children: [
              InfoRow('Visit ID', v.name, copyable: true),
              InfoRow('Salesperson', v.salesPersonDisplay),
              InfoRow('Date', MFormat.date(v.date)),
              if (v.visitedAt != null)
                InfoRow('Time', MFormat.time(v.visitedAt)),
              if (v.visitType.isNotEmpty) InfoRow('Visit type', v.visitType),
              if (v.isFirstCounter)
                const InfoRow('Counter', 'First counter of the day'),
              if (v.isLastCounter)
                const InfoRow('Counter', 'Last counter of the day'),
              if (v.creation != null)
                InfoRow('Logged at', MFormat.dateTime(v.creation)),
            ],
          ),
          SectionCard(
            title: 'Location',
            children: [
              if (v.locationName != null) InfoRow('Place', v.locationName!),
              if (v.hasLocation) ...[
                InfoRow(
                  'Latitude',
                  MFormat.coordinate(v.latitude!),
                  copyable: true,
                ),
                InfoRow(
                  'Longitude',
                  MFormat.coordinate(v.longitude!),
                  copyable: true,
                ),
              ],
              if (v.locationName == null && !v.hasLocation)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Location was not captured for this visit.',
                    style: MText.meta,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Private file: loaded with the session cookie, never displaying the sid.
class _VisitPhoto extends StatefulWidget {
  const _VisitPhoto({required this.path});
  final String path;

  @override
  State<_VisitPhoto> createState() => _VisitPhotoState();
}

class _VisitPhotoState extends State<_VisitPhoto> {
  late final Future<String?> _sid = ManagerService().readSid();

  String get _url =>
      Uri.parse(ApiConstants.host).resolve(widget.path).toString();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Visit photo',
      padding: const EdgeInsets.all(MSpace.md),
      children: [
        FutureBuilder<String?>(
          future: _sid,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _PhotoFrame(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            final headers = {'Cookie': 'sid=${snap.data ?? ''}'};
            final image = Image.network(
              _url,
              headers: headers,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const _PhotoFrame(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
              errorBuilder: (context, _, __) => const _PhotoFrame(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image_outlined, color: MColors.textMuted),
                    SizedBox(height: 6),
                    Text('Photo could not be loaded', style: MText.meta),
                  ],
                ),
              ),
            );
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _PhotoViewer(url: _url, headers: headers),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(MSpace.radiusSm),
                child: AspectRatio(aspectRatio: 4 / 3, child: image),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 4 / 3,
    child: Container(
      decoration: BoxDecoration(
        color: MColors.background,
        borderRadius: BorderRadius.circular(MSpace.radiusSm),
      ),
      alignment: Alignment.center,
      child: child,
    ),
  );
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.url, required this.headers});
  final String url;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Visit photo'),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.network(url, headers: headers, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
