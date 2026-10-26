import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../data/fit_reader.dart';
import '../data/trace_store.dart';
import '../models/workout_session.dart';
import '../services/garmin_service.dart';
import '../state/session_providers.dart';
import '../theme/app_theme.dart';
import '../utils/fr_date.dart';
import '../utils/track_stats.dart';
import '../widgets/ui.dart';
import 'history_screen.dart';

/// Trace GPS simplifiée d'une sortie Garmin : lue sur le téléphone, ou
/// téléchargée une seule fois à la première ouverture (vide si indisponible).
/// Clé : (identifiant Garmin, la sortie a-t-elle du GPS).
final traceProvider = FutureProvider.family<List<TrackPoint>, (String, bool)>((ref, key) async {
  final (garminId, hasGps) = key;
  if (kIsWeb || garminId.isEmpty) return const [];
  final stored = await const TraceStore().read(garminId);
  if (stored.isNotEmpty || !hasGps) return stored;
  final apiKey = await const GarminKeyStore().read();
  if (apiKey == null) return const [];
  try {
    return await const GarminService().fetchTrace(apiKey, garminId);
  } on GarminException catch (error) {
    debugPrint('Trace $garminId indisponible : $error');
    return const [];
  }
});

/// Écran 08 — Détail d'une sortie GPS.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key, required this.sessionId});

  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? const <WorkoutSession>[];
    final session = sessions.where((candidate) => candidate.id == sessionId).firstOrNull;
    if (session == null) {
      return const ScreenScroll(
        children: [
          BackLink('HISTORIQUE'),
          EmptyState(title: 'Sortie introuvable', message: 'Elle a peut-être été supprimée'),
        ],
      );
    }
    final trace = ref.watch(traceProvider((session.garminId, GarminService.hasGps(session))));
    final points = trace.valueOrNull ?? const <TrackPoint>[];
    final stats = TrackStats.of(points);
    final km = session.distanceKm;

    return ScreenScroll(
      children: [
        const BackLink('HISTORIQUE'),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 230,
            decoration: BoxDecoration(
              color: AppColors.cardDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: points.length > 1
                ? CustomPaint(painter: _RoutePainter(points), size: Size.infinite)
                : Center(
                    child: Text(
                      trace.isLoading ? 'CHARGEMENT DE LA TRACE…' : 'PAS DE TRACE GPS',
                      style: AppText.mono(size: 11, color: AppColors.dim, letterSpacingEm: .18),
                    ),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [TagPill(session.sport.code), for (final tag in session.tags) TagPill(tag)],
          ),
        ),
        Text(session.title, style: AppText.screenTitle()),
        const SizedBox(height: 5),
        Text(
          [FrDate.longDayShortMonth(session.date), if (session.time.isNotEmpty) session.time].join(' · '),
          style: AppText.sans(size: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: AppColors.border,
            child: Row(
              children: [
                for (final (label, value) in [
                  ('DIST', km == null ? '—' : formatKm(km)),
                  ('TEMPS', session.durationLabel),
                  ('ALLURE', formatPace(session)),
                  ('D+', points.isEmpty ? '—' : '${stats.elevationGain}'),
                ])
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                      color: AppColors.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(label, size: 8, spacingEm: .1),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(value, style: AppText.mono(size: 15, weight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (points.any((p) => p.altitude != null)) ...[
          const SizedBox(height: 12),
          AppCard(
            radius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('PROFIL ALTIMÉTRIQUE', color: AppColors.label, spacingEm: .18),
                const SizedBox(height: 12),
                SizedBox(
                  height: 84,
                  width: double.infinity,
                  child: CustomPaint(painter: _ElevationPainter(points)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final label in ['0 km', if (km != null) '${formatKm(km / 2)} km', if (km != null) '${formatKm(km)} km'])
                      Text(label, style: AppText.mono(size: 9, color: AppColors.dim)),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (stats.averageHeartRate != null) ...[
          const SizedBox(height: 12),
          TileGrid(
            columns: 2,
            children: [
              StatTile(label: 'FC MOY', value: '${stats.averageHeartRate}', valueSize: 17),
              StatTile(label: 'FC MAX', value: '${stats.maxHeartRate}', valueSize: 17),
            ],
          ),
        ],
        if (stats.splits.isNotEmpty) ..._splitRows(stats.splits),
        const SizedBox(height: 16),
        OutlineButton(
          height: 46,
          borderColor: AppColors.borderStrong,
          onTap: () => context.goTo(AppScreen.session, arguments: session.id),
          child: Text('Modifier ou supprimer', style: AppText.sans(size: 14, weight: FontWeight.w500)),
        ),
      ],
    );
  }

  List<Widget> _splitRows(List<KmSplit> splits) {
    final paces = splits.map((split) => split.paceSeconds);
    final fastest = paces.reduce((a, b) => math.min(a, b));
    final slowest = paces.reduce((a, b) => math.max(a, b));
    String pace(double seconds) => '${seconds ~/ 60}′${(seconds.round() % 60).toString().padLeft(2, '0')}';

    return [
      const SectionLabel('TEMPS AU KM', top: 20, bottom: 8),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
        child: const Row(
          children: [
            SizedBox(width: 40, child: Eyebrow('KM', size: 9, color: AppColors.dim, spacingEm: .1)),
            Expanded(child: Eyebrow('ALLURE', size: 9, color: AppColors.dim, spacingEm: .1)),
            SizedBox(width: 58, child: Eyebrow('DÉNIV.', size: 9, color: AppColors.dim, spacingEm: .1, align: TextAlign.right)),
            SizedBox(width: 44, child: Eyebrow('FC', size: 9, color: AppColors.dim, spacingEm: .1, align: TextAlign.right)),
          ],
        ),
      ),
      for (final split in splits)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  split.km < 1 ? formatKm(split.index - 1 + split.km) : '${split.index}',
                  style: AppText.mono(size: 12, color: AppColors.label),
                ),
              ),
              SizedBox(width: 50, child: Text(pace(split.paceSeconds), style: AppText.mono(size: 12, weight: FontWeight.w700))),
              const SizedBox(width: 8),
              Expanded(
                // Barre pleine pour le kilomètre le plus rapide.
                child: ProgressBar(
                  fraction: slowest == fastest ? 1 : .35 + .65 * (slowest - split.paceSeconds) / (slowest - fastest),
                  height: 5,
                  color: const Color(0xFFE8E8E8),
                ),
              ),
              SizedBox(
                width: 58,
                child: Text(
                  '${split.climb > 0 ? '+' : split.climb < 0 ? '−' : ''}${split.climb.abs()} m',
                  textAlign: TextAlign.right,
                  style: AppText.mono(size: 12, color: AppColors.label),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text('${split.heartRate ?? '—'}', textAlign: TextAlign.right, style: AppText.mono(size: 12)),
              ),
            ],
          ),
        ),
    ];
  }
}

/// Tracé du parcours, projeté à plat et centré, sans fond de carte.
class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.points);

  final List<TrackPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final meanLat = points.map((p) => p.lat).reduce((a, b) => a + b) / points.length;
    final scaleX = math.cos(meanLat * math.pi / 180);
    final xs = points.map((p) => p.lon * scaleX).toList();
    final ys = points.map((p) => p.lat).toList();
    final minX = xs.reduce((a, b) => math.min(a, b)), maxX = xs.reduce((a, b) => math.max(a, b));
    final minY = ys.reduce((a, b) => math.min(a, b)), maxY = ys.reduce((a, b) => math.max(a, b));
    const padding = 22.0;
    final scale = math.min(
      (size.width - 2 * padding) / math.max(maxX - minX, 1e-9),
      (size.height - 2 * padding) / math.max(maxY - minY, 1e-9),
    );
    final offsetX = (size.width - (maxX - minX) * scale) / 2;
    final offsetY = (size.height - (maxY - minY) * scale) / 2;
    Offset at(int i) => Offset(offsetX + (xs[i] - minX) * scale, size.height - offsetY - (ys[i] - minY) * scale);

    final route = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      route.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.text
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(at(0), 5, Paint()..color = AppColors.text);
    canvas.drawCircle(
      at(points.length - 1),
      5,
      Paint()
        ..color = AppColors.text
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.points != points;
}

class _ElevationPainter extends CustomPainter {
  const _ElevationPainter(this.points);

  final List<TrackPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final profile = points.where((p) => p.altitude != null).toList();
    if (profile.length < 2) return;
    final altitudes = profile.map((p) => p.altitude!).toList();
    final low = altitudes.reduce((a, b) => math.min(a, b));
    final range = math.max(altitudes.reduce((a, b) => math.max(a, b)) - low, 20);
    final total = profile.last.distance ?? 0;
    double xOf(int i) => total > 0
        ? (profile[i].distance ?? 0) / total * size.width
        : i * size.width / (profile.length - 1);
    double yOf(int i) => size.height * (1 - (altitudes[i] - low) / range * .9);

    final area = Path()..moveTo(0, size.height);
    final line = Path()..moveTo(xOf(0), yOf(0));
    for (var i = 0; i < profile.length; i++) {
      area.lineTo(xOf(i), yOf(i));
      if (i > 0) line.lineTo(xOf(i), yOf(i));
    }
    area
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = AppColors.blockLow);
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.text
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_ElevationPainter old) => old.points != points;
}
