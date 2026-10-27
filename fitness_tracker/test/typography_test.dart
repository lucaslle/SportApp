import 'package:fitness_tracker/utils/typography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les libellés en majuscules passent en casse de phrase, sigles gardés', () {
    expect(sentenceCase('RÉPARTITION PAR SPORT · 4 SEM.'), 'Répartition par sport · 4 sem.');
    expect(sentenceCase('FC MOY'), 'FC moy');
    expect(sentenceCase('PLAN · SEMAINE 44'), 'Plan · semaine 44');
    expect(sentenceCase('Déjà écrit'), 'Déjà écrit');
    expect(sentenceCase('S44'), 'S44');
  });

  test('les signes ′ et ″ deviennent des apostrophes', () {
    expect(typographic('10 × 1′ · récup 90″'), '10 × 1’ · récup 90”');
  });
}
