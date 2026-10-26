import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/sport.dart';
import '../models/workout_session.dart';
import '../utils/fr_date.dart';

/// Erreur d'import Garmin, avec un message affichable tel quel.
class GarminException implements Exception {
  const GarminException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Clé de l'API personnelle Garmin, gardée dans le stockage chiffré du téléphone.
class GarminKeyStore {
  const GarminKeyStore();

  static const _storage = FlutterSecureStorage();
  static const _key = 'garmin_personal_api_key';

  Future<String?> read() => _storage.read(key: _key);

  Future<void> write(String apiKey) => _storage.write(key: _key, value: apiKey.trim());

  Future<void> delete() => _storage.delete(key: _key);
}

/// Lecture des activités via l'API personnelle Garmin Connect.
class GarminService {
  const GarminService();

  static const String _host = 'personal.connectapi.garmin.com';

  /// Sorties Garmin des [days] derniers jours, prêtes à fusionner dans le plan.
  Future<List<WorkoutSession>> fetchActivities(String apiKey, {required DateTime today, int days = 30}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final token = await _send(
        client,
        'POST',
        Uri.https(_host, '/personalapitoken-service/personal-api/personal-api-key/token'),
        'ApiKey ${apiKey.trim()}',
      );
      final body = await _send(
        client,
        'GET',
        Uri.https(_host, '/activitylist-service/activities/search/activities', {
          'start': '0',
          'limit': '100',
          'startDate': FrDate.iso(today.subtract(Duration(days: days))),
          'endDate': FrDate.iso(today),
        }),
        'Bearer ${token.trim()}',
      );
      return sessionsFromJson(jsonDecode(body));
    } on SocketException {
      throw const GarminException('Pas de connexion à Garmin. Vérifiez votre réseau.');
    } on FormatException {
      throw const GarminException('Réponse de Garmin illisible.');
    } finally {
      client.close();
    }
  }

  Future<String> _send(HttpClient client, String method, Uri uri, String authorization) async {
    final request = await client.openUrl(method, uri);
    request.headers
      ..set(HttpHeaders.authorizationHeader, authorization)
      ..set(HttpHeaders.acceptHeader, 'application/json, */*');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const GarminException('Clé Garmin refusée : vérifiez-la ou créez-en une nouvelle.');
    }
    if (response.statusCode == 429) {
      throw const GarminException('Trop de requêtes vers Garmin, réessayez plus tard.');
    }
    if (response.statusCode >= 400) {
      throw GarminException('Garmin a répondu avec l\'erreur ${response.statusCode}.');
    }
    return body;
  }

  /// Convertit la réponse de recherche d'activités en sorties faites.
  /// Les activités d'un type sans équivalent (marche, yoga…) sont ignorées.
  static List<WorkoutSession> sessionsFromJson(Object? json) {
    final items = json is List ? json : json is Map && json['activities'] is List ? json['activities'] as List : const [];
    final sessions = <WorkoutSession>[];
    for (final item in items.whereType<Map>()) {
      final type = item['activityType'];
      final sport = sportFor(type is Map ? '${type['typeKey']}' : '');
      final start = DateTime.tryParse('${item['startTimeLocal']}');
      if (sport == null || start == null) continue;
      final meters = (item['distance'] as num?)?.toDouble() ?? 0;
      final seconds = (item['duration'] as num?)?.toDouble() ?? 0;
      final elevation = (item['elevationGain'] as num?)?.round();
      final heartRate = (item['averageHR'] as num?)?.round();
      sessions.add(WorkoutSession(
        id: WorkoutSession.newId(),
        date: start,
        sport: sport,
        title: '${item['activityName'] ?? sport.label}'.trim(),
        subtitle: [
          if (elevation != null && elevation > 0) 'D+ $elevation m',
          if (heartRate != null) 'FC moy. $heartRate',
        ].join(' · '),
        durationMin: (seconds / 60).round(),
        distanceKm: meters > 0 ? double.parse((meters / 1000).toStringAsFixed(2)) : null,
        time: '${start.hour}h${start.minute.toString().padLeft(2, '0')}',
        tags: const ['GARMIN'],
        done: true,
      ));
    }
    return sessions;
  }

  /// Sport de l'app correspondant à un `typeKey` Garmin.
  static Sport? sportFor(String typeKey) {
    final key = typeKey.toLowerCase();
    if (key.contains('trail')) return Sport.trail;
    if (key.contains('running')) return Sport.cap;
    if (key == 'indoor_cycling' || key == 'virtual_ride') return Sport.ht;
    if (key.contains('cycling') || key.contains('biking')) return Sport.velo;
    if (key.contains('swimming')) return Sport.nat;
    if (key.contains('strength') || key == 'hiit') return Sport.muscu;
    return null;
  }
}
