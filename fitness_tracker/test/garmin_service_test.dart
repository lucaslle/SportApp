import 'package:fitness_tracker/models/sport.dart';
import 'package:fitness_tracker/services/garmin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('une activité Garmin devient une sortie faite', () {
    final sessions = GarminService.sessionsFromJson([
      {
        'activityId': 1,
        'activityName': 'Lyon Course',
        'startTimeLocal': '2026-10-20 07:12:00',
        'activityType': {'typeKey': 'running'},
        'distance': 10234.5,
        'duration': 2910.0,
        'elevationGain': 58.0,
        'averageHR': 148.0,
      },
      {
        'activityName': 'Promenade',
        'startTimeLocal': '2026-10-21 12:00:00',
        'activityType': {'typeKey': 'walking'},
      },
    ]);

    final run = sessions.single;
    expect(run.sport, Sport.cap);
    expect(run.title, 'Lyon Course');
    expect(run.date, DateTime(2026, 10, 20));
    expect(run.time, '7h12');
    expect(run.distanceKm, 10.23);
    expect(run.durationMin, 49);
    expect(run.subtitle, 'D+ 58 m · FC moy. 148');
    expect(run.done, isTrue);
    expect(run.tags, ['GARMIN']);
  });

  test('les types Garmin sont rangés dans le bon sport', () {
    expect(GarminService.sportFor('trail_running'), Sport.trail);
    expect(GarminService.sportFor('treadmill_running'), Sport.cap);
    expect(GarminService.sportFor('road_biking'), Sport.velo);
    expect(GarminService.sportFor('indoor_cycling'), Sport.ht);
    expect(GarminService.sportFor('lap_swimming'), Sport.nat);
    expect(GarminService.sportFor('strength_training'), Sport.muscu);
    expect(GarminService.sportFor('yoga'), isNull);
  });

  test('une réponse inattendue ne plante pas', () {
    expect(GarminService.sessionsFromJson({'error': 'x'}), isEmpty);
    expect(GarminService.sessionsFromJson(null), isEmpty);
  });
}
