import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/fit_reader.dart';
import '../data/trace_store.dart';
import '../models/sport.dart';
import '../models/workout_session.dart';

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

  /// Nouvelles sorties Garmin (résumés seuls) : celles dont l'identifiant est
  /// dans [known] sont ignorées. Les activités arrivent de la plus récente à la
  /// plus ancienne ; on s'arrête à la première page qui contient une sortie
  /// connue. Un premier import tient en un appel pour 1 000 activités.
  Future<List<WorkoutSession>> importNew(String apiKey, {required Set<String> known}) => _guard((client) async {
        final token = await _token(client, apiKey);
        final pageSize = known.isEmpty ? 1000 : 50;
        final items = <Object?>[];
        for (var start = 0;; start += pageSize) {
          final page = jsonDecode(utf8.decode(await _send(
            client,
            'GET',
            Uri.https(_host, '/activitylist-service/activities/search/activities', {
              'start': '$start',
              'limit': '$pageSize',
            }),
            'Bearer $token',
          )));
          if (page is! List) break;
          items.addAll(page);
          final reachedKnown = page.whereType<Map>().any((item) => known.contains('${item['activityId']}'));
          if (page.length < pageSize || reachedKnown) break;
        }
        return sessionsFromJson(items).where((session) => !known.contains(session.garminId)).toList();
      });

  /// Télécharge le .FIT d'une activité et en garde la trace simplifiée :
  /// appelé seulement quand on ouvre une sortie qui n'a pas encore de trace.
  Future<List<TrackPoint>> fetchTrace(
    String apiKey,
    String garminId, {
    TraceStore traces = const TraceStore(),
  }) =>
      _guard((client) async {
        final token = await _token(client, apiKey);
        final zip = await _send(
          client,
          'GET',
          Uri.https(_host, '/download-service/files/activity/$garminId'),
          'Bearer $token',
        );
        final points = FitReader.simplify(FitReader.records(FitReader.unzip(Uint8List.fromList(zip))));
        if (points.isNotEmpty) await traces.write(garminId, points);
        return points;
      });

  /// Jeton gardé en mémoire tant qu'il reste valable plus d'une heure (il vaut 24 h).
  static String? _cachedToken;
  static DateTime _tokenExpiry = DateTime(0);

  Future<String> _token(HttpClient client, String apiKey) async {
    if (_cachedToken != null && DateTime.now().isBefore(_tokenExpiry.subtract(const Duration(hours: 1)))) {
      return _cachedToken!;
    }
    final token = utf8.decode(await _send(
      client,
      'POST',
      Uri.https(_host, '/personalapitoken-service/personal-api/personal-api-key/token'),
      'ApiKey ${apiKey.trim()}',
    )).trim();
    _cachedToken = token;
    _tokenExpiry = _jwtExpiry(token);
    return token;
  }

  /// Échéance (`exp`) d'un JWT, ou maintenant si elle est illisible.
  static DateTime _jwtExpiry(String token) {
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))));
      return DateTime.fromMillisecondsSinceEpoch((payload['exp'] as num).toInt() * 1000);
    } on Object {
      return DateTime.now();
    }
  }

  Future<T> _guard<T>(Future<T> Function(HttpClient client) run) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      return await run(client);
    } on SocketException {
      throw const GarminException('Pas de connexion à Garmin. Vérifiez votre réseau.');
    } on FormatException {
      throw const GarminException('Réponse de Garmin illisible.');
    } finally {
      client.close();
    }
  }

  /// Sports dont les sorties ont une trace GPS.
  static bool hasGps(WorkoutSession session) =>
      (session.distanceKm ?? 0) > 0 &&
      (session.sport == Sport.cap || session.sport == Sport.trail || session.sport == Sport.velo || session.sport == Sport.nat);

  Future<List<int>> _send(HttpClient client, String method, Uri uri, String authorization) async {
    final request = await client.openUrl(method, uri);
    request.headers
      ..set(HttpHeaders.authorizationHeader, authorization)
      ..set(HttpHeaders.acceptHeader, 'application/json, */*');
    final response = await request.close();
    final body = await response.fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
    if (response.statusCode == 401 || response.statusCode == 403) {
      _cachedToken = null;
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
        garminId: '${item['activityId'] ?? ''}',
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
