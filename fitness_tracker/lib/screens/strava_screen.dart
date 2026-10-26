import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_screen.dart';
import '../state/connections_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

const List<String> _scopes = [
  'Traces GPS & profil altimétrique',
  'Distance, temps, allure, vitesse',
  'Fréquence cardiaque & cadence',
  'Matériel utilisé (chaussures, vélo)',
  'Segments & records personnels',
];

/// Écran 09 — Connexion Strava et autres sources.
class StravaScreen extends ConsumerWidget {
  const StravaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(stravaConnectedProvider);

    return ScreenScroll(
      children: [
        ScreenHeader(eyebrow: 'CONNEXIONS', title: 'Sources de données'),
        SizedBox(height: 18),
        Container(
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(12)),
                    child: Text('S', style: AppText.mono(size: 15, weight: FontWeight.w700, color: AppColors.onLight)),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Strava', style: AppText.sans(size: 16, weight: FontWeight.w600)),
                        SizedBox(height: 3),
                        Text(
                          connected ? 'Connecté · synchro il y a 12 min' : 'Non connecté',
                          style: AppText.mono(size: 10, color: connected ? AppColors.label : AppColors.dim),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref.read(stravaConnectedProvider.notifier).state = !connected,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: connected ? Colors.transparent : AppColors.text,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderDashed),
                      ),
                      child: Text(
                        connected ? 'Déconnecter' : 'Connecter',
                        style: AppText.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: connected ? AppColors.text : AppColors.onLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              HairLine(vertical: 18),
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Eyebrow('DONNÉES RÉCUPÉRÉES', spacingEm: .18),
              ),
              for (final scope in _scopes)
                Padding(
                  padding: EdgeInsets.only(bottom: 11),
                  child: Row(
                    children: [
                      Text(
                        connected ? '●' : '○',
                        style: AppText.mono(size: 11, color: connected ? AppColors.text : AppColors.dimmer),
                      ),
                      SizedBox(width: 11),
                      Text(
                        scope,
                        style: AppText.sans(size: 13, color: connected ? AppColors.textSoft : AppColors.mutedDark),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (connected) ...[
          SizedBox(height: 12),
          AppCard(
            radius: 16,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _ToggleRow(label: 'Import automatique', detail: 'Nouvelle activité rapatriée en 2 min'),
                HairLine(vertical: 14),
                _ToggleRow(label: 'Rapprocher plan / réalisé', detail: 'Coche la séance prévue du jour'),
              ],
            ),
          ),
          SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.all(15),
            onTap: () => context.switchTab(AppTab.history),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('14 sorties importées', style: AppText.sans(size: 14, weight: FontWeight.w500)),
                Text('→', style: AppText.mono(size: 14)),
              ],
            ),
          ),
        ],
        SectionLabel('AUTRES SOURCES'),
        for (final (name, detail, state) in [
          ('Montre GPS (Garmin)', 'Séances, FC, sommeil', 'CONNECTÉ'),
          ('Balance connectée', 'Poids, masse grasse, eau', 'CONNECTÉ'),
          ('Apple Santé', 'Pas, FC repos, VO₂ max', 'INACTIF'),
        ])
          AppCard(
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppText.sans(size: 14, weight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text(detail, style: AppText.mono(size: 10, color: AppColors.mutedDark)),
                    ],
                  ),
                ),
                TagPill(
                  state,
                  size: 10,
                  color: AppColors.label,
                  spacingEm: 0,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ],
            ),
          ),
        SizedBox(height: 10),
        Text(
          'Aucune donnée n\'est repartagée. Les traces restent\nconsultables hors ligne après import.',
          style: AppText.mono(size: 10, color: AppColors.dim, height: 1.7),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.sans(size: 14, weight: FontWeight.w500)),
              SizedBox(height: 4),
              Text(detail, style: AppText.mono(size: 10, color: AppColors.mutedDark)),
            ],
          ),
        ),
        AppToggle(value: true),
      ],
    );
  }
}
