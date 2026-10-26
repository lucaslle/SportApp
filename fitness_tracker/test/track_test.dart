import 'dart:typed_data';

import 'package:fitness_tracker/data/fit_reader.dart';
import 'package:fitness_tracker/data/trace_store.dart';
import 'package:fitness_tracker/utils/track_stats.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fichier FIT minimal : une définition « record » puis [count] points, un par seconde,
/// le second utilisant un en-tête à horodatage compressé.
Uint8List _fit(int count) {
  final body = BytesBuilder();
  // Définition locale 0 → message global 20 : timestamp, lat, lon, altitude, fc, distance.
  body.add([0x40, 0, 0, 20, 0, 6, 253, 4, 0x86, 0, 4, 0x85, 1, 4, 0x85, 2, 2, 0x84, 3, 1, 0x02, 5, 4, 0x86]);
  // Définition locale 1 sans timestamp, pour l'en-tête compressé.
  body.add([0x41, 0, 0, 20, 0, 5, 0, 4, 0x85, 1, 4, 0x85, 2, 2, 0x84, 3, 1, 0x02, 5, 4, 0x86]);
  const start = 1000000000;
  for (var i = 0; i < count; i++) {
    final data = ByteData(22);
    final lat = (45.75 * 2147483648 / 180).round() + i * 100;
    final lon = (4.85 * 2147483648 / 180).round();
    if (i == 1) {
      // En-tête compressé, local 1, décalage = (start + 1) & 0x1F.
      body.addByte(0x80 | (1 << 5) | ((start + 1) & 0x1F));
      data
        ..setInt32(0, lat, Endian.little)
        ..setInt32(4, lon, Endian.little)
        ..setUint16(8, (200 + 500) * 5, Endian.little)
        ..setUint8(10, 140)
        ..setUint32(11, i * 300, Endian.little);
      body.add(data.buffer.asUint8List(0, 15));
      continue;
    }
    body.addByte(0x00);
    data
      ..setUint32(0, start + i, Endian.little)
      ..setInt32(4, lat, Endian.little)
      ..setInt32(8, lon, Endian.little)
      ..setUint16(12, (200 + i + 500) * 5, Endian.little)
      ..setUint8(14, 140 + i)
      ..setUint32(15, i * 300, Endian.little);
    body.add(data.buffer.asUint8List(0, 19));
  }
  final bytes = body.toBytes();
  final header = ByteData(12)
    ..setUint8(0, 12)
    ..setUint32(4, bytes.length, Endian.little);
  return Uint8List.fromList([...header.buffer.asUint8List(), ...bytes, 0, 0]);
}

void main() {
  test('le lecteur FIT extrait les points GPS, y compris à horodatage compressé', () {
    final points = FitReader.records(_fit(4));

    expect(points, hasLength(4));
    expect(points[1].seconds, 1);
    expect(points[3].seconds, 3);
    expect(points.first.lat, closeTo(45.75, 1e-6));
    expect(points.first.lon, closeTo(4.85, 1e-6));
    expect(points[2].altitude, 202);
    expect(points[2].heartRate, 142);
    expect(points[3].distance, 9);
  });

  test('un fichier qui n\'est pas un ZIP est rendu tel quel', () {
    final fit = _fit(2);
    expect(FitReader.unzip(fit), same(fit));
  });

  test('la simplification garde un point toutes les 5 s et le dernier', () {
    final points = [
      for (var s = 0; s <= 23; s++) TrackPoint(seconds: s, lat: 45, lon: 4),
    ];
    expect(FitReader.simplify(points).map((p) => p.seconds), [0, 5, 10, 15, 20, 23]);
  });

  test('une trace survit à un aller-retour texte', () {
    const points = [
      TrackPoint(seconds: 0, lat: 45.123456, lon: 4.5, altitude: 210.4, heartRate: 130, distance: 0),
      TrackPoint(seconds: 5, lat: 45.12350, lon: 4.50005, distance: 14.6),
    ];
    final decoded = TraceStore.decode(TraceStore.encode(points));

    expect(decoded, hasLength(2));
    expect(decoded.first.lat, 45.12346);
    expect(decoded.first.altitude, 210);
    expect(decoded.last.heartRate, isNull);
    expect(decoded.last.distance, 15);
  });

  test('temps au km, dénivelé et fréquence cardiaque', () {
    // 2,5 km à 5′00/km, une montée de 10 m puis du bruit de ±0,5 m.
    final points = [
      for (var s = 0; s <= 750; s += 5)
        TrackPoint(
          seconds: s,
          lat: 45,
          lon: 4,
          distance: s * 1000 / 300,
          altitude: s < 300 ? 100 + s / 30 : 110 + (s % 10 == 0 ? .5 : -.5),
          heartRate: 150,
        ),
    ];
    final stats = TrackStats.of(points);

    expect(stats.splits.map((split) => split.index), [1, 2, 3]);
    expect(stats.splits.first.paceSeconds, closeTo(300, 1));
    expect(stats.splits.last.km, closeTo(.5, .01));
    expect(stats.elevationGain, inInclusiveRange(10, 13));
    expect(stats.averageHeartRate, 150);
  });
}
