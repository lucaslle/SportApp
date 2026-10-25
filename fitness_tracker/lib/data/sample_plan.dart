import '../models/sport.dart';
import '../models/workout_session.dart';
import '../utils/fr_date.dart';

/// Plan d'exemple (la semaine de la maquette), calé sur la semaine de [today]
/// pour que l'application soit vivante au premier lancement. Les séances
/// antérieures à aujourd'hui sont marquées faites.
abstract final class SamplePlan {
  static List<WorkoutSession> build(DateTime today) {
    final monday = FrDate.mondayOf(today);
    final previousMonday = monday.subtract(const Duration(days: 7));
    final sessions = <WorkoutSession>[
      ..._week(previousMonday, today),
      ..._week(monday, today),
    ];
    return sessions;
  }

  static List<WorkoutSession> _week(DateTime monday, DateTime today) {
    WorkoutSession day(
      int offset, {
      required Sport sport,
      required String title,
      String subtitle = '',
      int durationMin = 0,
      double? distanceKm,
      String targetPace = '',
      String targetHr = '',
      int? rpe,
      String time = '',
      String location = '',
      List<String> tags = const [],
      List<SessionBlock> blocks = const [],
    }) {
      final date = monday.add(Duration(days: offset));
      return WorkoutSession(
        id: WorkoutSession.newId(),
        date: date,
        sport: sport,
        title: title,
        subtitle: subtitle,
        durationMin: durationMin,
        distanceKm: distanceKm,
        targetPace: targetPace,
        targetHr: targetHr,
        rpe: rpe,
        time: time,
        location: location,
        tags: tags,
        blocks: blocks,
        done: !sport.isRest && date.isBefore(FrDate.dateOnly(today)),
      );
    }

    return [
      day(
        0,
        sport: Sport.cap,
        title: 'Fractionné 8 × 400 m',
        subtitle: 'Piste · récup 90″ · objectif 3′20/km',
        durationMin: 55,
        distanceKm: 11,
        targetPace: '3′20 /km',
        targetHr: 'Z4 · 172',
        rpe: 8,
        time: '18h30',
        location: 'Stade Léo Lagrange',
        tags: const ['PISTE', 'VMA'],
        blocks: const [
          SessionBlock(
            title: 'Échauffement',
            detail: 'Footing souple + éducatifs',
            durationMin: 20,
          ),
          SessionBlock(
            title: '8 × 400 m',
            detail: '@ 3′20/km · récup 90″ trot',
            durationMin: 25,
            intensity: BlockIntensity.high,
          ),
          SessionBlock(
            title: 'Retour au calme',
            detail: 'Footing très lent',
            durationMin: 10,
          ),
          SessionBlock(
            title: 'Étirements',
            detail: 'Chaîne postérieure, 5 postures',
            durationMin: 8,
            intensity: BlockIntensity.low,
          ),
        ],
      ),
      day(
        1,
        sport: Sport.muscu,
        title: 'Renfo bas du corps + gainage',
        subtitle: '6 exercices · 3 séries',
        durationMin: 45,
        rpe: 6,
        time: '7h30',
        blocks: const [
          SessionBlock(title: 'Mobilité', detail: 'Hanches, chevilles', durationMin: 8, intensity: BlockIntensity.low),
          SessionBlock(title: 'Squats + fentes', detail: '3 × 10 · charge modérée', durationMin: 22, intensity: BlockIntensity.high),
          SessionBlock(title: 'Gainage', detail: 'Planche, latéral, dead bug', durationMin: 15),
        ],
      ),
      day(
        2,
        sport: Sport.velo,
        title: 'Endurance vallonnée',
        subtitle: 'Z2 · 220 W · cadence 90',
        durationMin: 90,
        distanceKm: 45,
        targetHr: 'Z2 · 140',
        rpe: 5,
        time: '17h45',
        tags: const ['ENDURANCE'],
      ),
      day(
        3,
        sport: Sport.repos,
        title: 'Mobilité 15′ optionnelle',
        subtitle: 'Repos complet ou mobilité douce',
      ),
      day(
        4,
        sport: Sport.cap,
        title: 'Footing + 6 lignes droites',
        subtitle: '4′50/km · lignes droites 80 m',
        durationMin: 50,
        distanceKm: 10,
        targetPace: '4′50 /km',
        targetHr: 'Z2 · 145',
        rpe: 4,
        time: '7h00',
      ),
      day(
        5,
        sport: Sport.nat,
        title: 'Technique 1 500 m',
        subtitle: 'Éducatifs crawl · pull-buoy',
        durationMin: 45,
        distanceKm: 1.5,
        rpe: 5,
        time: '12h30',
        location: 'Piscine du Rhône',
      ),
      day(
        6,
        sport: Sport.trail,
        title: 'Sortie longue D+ 700 m',
        subtitle: 'Z2 · ravito toutes les 45′',
        durationMin: 120,
        distanceKm: 18,
        targetHr: 'Z2 · 150',
        rpe: 6,
        time: '8h00',
        tags: const ['SORTIE LONGUE'],
      ),
    ];
  }
}
