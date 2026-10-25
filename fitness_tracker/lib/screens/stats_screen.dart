import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

const List<int> _weeklyLoad = [280, 320, 360, 210, 390, 420, 300, 450, 470, 340, 490, 412];

final _periodProvider = StateProvider<String>((ref) => '3 MOIS');

/// Écran 10 — Charge d'entraînement.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);

    return ScreenScroll(
      children: [
        const ScreenHeader(eyebrow: 'CHARGE D\'ENTRAÎNEMENT', title: '12 dernières semaines'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              for (final label in const ['4 SEM', '3 MOIS', '1 AN']) ...[
                if (label != '4 SEM') const SizedBox(width: 7),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref.read(_periodProvider.notifier).state = label,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: period == label ? AppColors.text : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderStrong),
                      ),
                      child: Text(
                        label,
                        style: AppText.mono(
                          size: 11,
                          color: period == label ? AppColors.onLight : AppColors.textFilter,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        AppCard(
          radius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Eyebrow('CHARGE HEBDO', color: AppColors.label, spacingEm: .18),
                  Text('unités arbitraires', style: AppText.mono(size: 10, color: AppColors.mutedDark)),
                ],
              ),
              const SizedBox(height: 16),
              BarColumnChart(
                height: 120,
                gap: 5,
                labelSize: 8,
                labelColor: AppColors.dim,
                items: [
                  for (var i = 0; i < _weeklyLoad.length; i++)
                    BarItem(
                      label: 'S${26 + i}',
                      fraction: _weeklyLoad[i] / 500,
                      color: i == _weeklyLoad.length - 1
                          ? AppColors.text
                          : i % 4 == 3
                              ? const Color(0xFF2D2D2D)
                              : const Color(0xFF4F4F4F),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const TileGrid(
          columns: 2,
          children: [
            StatTile(
              label: 'RATIO AIGU / CHRONIQUE',
              value: '1,12',
              sub: 'zone optimale',
              valueSize: 22,
              padding: EdgeInsets.all(14),
            ),
            StatTile(
              label: 'MONOTONIE',
              value: '1,4',
              sub: 'variation saine',
              valueSize: 22,
              padding: EdgeInsets.all(14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          radius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Eyebrow('RÉPARTITION PAR SPORT · 4 SEM.', color: AppColors.label, spacingEm: .18),
              ),
              for (final (label, value, fraction, color) in const [
                ('Course à pied', '11h40', .86, AppColors.text),
                ('Vélo / HT', '7h20', .54, AppColors.textPill),
                ('Trail', '5h10', .38, AppColors.label),
                ('Natation', '2h30', .19, Color(0xFF6F6F6F)),
                ('Muscu / renfo', '2h00', .15, AppColors.dimmer),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: AppText.mono(size: 11, color: AppColors.textSoft)),
                          Text(value, style: AppText.mono(size: 11, color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ProgressBar(fraction: fraction, color: color),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          radius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Eyebrow('TEMPS PAR ZONE FC', color: AppColors.label, spacingEm: .18),
              ),
              BarColumnChart(
                height: 70,
                gap: 4,
                items: [
                  for (final (label, fraction) in const [('Z1', .28), ('Z2', 1.0), ('Z3', .46), ('Z4', .34), ('Z5', .14)])
                    BarItem(
                      label: label,
                      fraction: fraction,
                      color: label == 'Z2' ? AppColors.text : const Color(0xFF454545),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(15),
          onTap: () => context.goTo(AppScreen.goals),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Objectifs & records', style: AppText.sans(size: 14, weight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Course cible, records personnels, série', style: AppText.mono(size: 10, color: AppColors.mutedDark)),
                ],
              ),
              Text('→', style: AppText.mono(size: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
