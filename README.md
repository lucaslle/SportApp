# SportApp

Application mobile Flutter (nom affiché : **Athlète**) pour planifier et suivre ses séances d'entraînement multisport : course à pied, trail, vélo, home trainer, natation, renforcement et repos.

Le plan d'entraînement est saisi dans l'application ou importé depuis un fichier CSV, et peut être réexporté au même format.

## Fonctionnalités

- **Aujourd'hui**, **Plan de la semaine** et **Détail de séance** : séances avec durée, distance, allure et FC cibles, RPE, structure par blocs et case « faite ».
- Création et édition d'une séance via un formulaire.
- **Import / export CSV** du plan complet ou de la semaine affichée.
- Écrans de maquette (données fictives pour l'instant) : calendrier et courses, poids et composition, historique des sorties, détail GPS, charge d'entraînement, objectifs et records, connexion Strava, export montre / Garmin.

Au premier lancement, un plan d'exemple sur deux semaines est chargé. Le plan est ensuite enregistré sur l'appareil au format CSV. Sur le web, il reste en mémoire et disparaît au rechargement de la page.

## Démarrer

Le code se trouve dans [`fitness_tracker/`](fitness_tracker). Il faut le SDK Flutter, avec Dart 3.6 ou plus.

```bash
cd fitness_tracker
flutter pub get
flutter run
```

Pour lancer les tests :

```bash
flutter test
```

## Format CSV

Un fichier contient une ligne d'en-tête, puis une séance par ligne. Le code correspondant est dans [`session_csv_codec.dart`](fitness_tracker/lib/data/session_csv_codec.dart).

### Règles générales

- **Séparateur** : `;` à l'export. À l'import, le séparateur (`;`, `,` ou tabulation) est détecté à partir de la première ligne.
- **Encodage** : UTF-8. L'export ajoute un BOM et utilise des fins de ligne CRLF pour qu'Excel l'ouvre correctement.
- **Guillemets** : selon la RFC 4180. Un champ qui contient le séparateur, un guillemet ou un retour à la ligne est entouré de `"`, et ses guillemets sont doublés (`""`).
- **En-tête** : obligatoire. Les colonnes peuvent être dans n'importe quel ordre, et les colonnes inconnues sont ignorées. Les noms de colonnes ne tiennent compte ni de la casse ni des accents. Plusieurs alias sont acceptés (voir ci-dessous).
- Les lignes vides sont ignorées.

### Colonnes

| Colonne | Obligatoire | Contenu | Alias acceptés à l'import |
|---|---|---|---|
| `date` | oui | `AAAA-MM-JJ` (export) ; `JJ/MM/AAAA` accepté à l'import | `jour`, `day` |
| `sport` | oui | `CAP`, `TRAIL`, `VÉLO`, `HT`, `NAT`, `MUSCU`, `REPOS` (voir ci-dessous) | `discipline`, `type` |
| `titre` | oui | Nom de la séance | `title`, `seance`, `nom`, `name` |
| `sous_titre` | | Ligne de détail courte | `subtitle`, `detail`, `description` |
| `duree_min` | | Durée en minutes ; à l'import : `55`, `55 min`, `1h30`, `1h`, `01:30` | `duree`, `duration`, `duration_min`, `minutes` |
| `distance_km` | | Nombre, avec un point ou une virgule (`1.5` ou `1,5`) | `distance`, `km`, `volume` |
| `allure_cible` | | Texte libre, ex. `4′50 /km` | `allure`, `pace`, `target_pace` |
| `fc_cible` | | Texte libre, ex. `Z2 · 145` | `fc`, `hr`, `target_hr`, `zone` |
| `rpe` | | Entier de 1 à 10 | `effort` |
| `heure` | | Texte libre, ex. `18h30` | `time`, `hour` |
| `lieu` | | Texte libre | `location`, `place` |
| `tags` | | Séparés par `\|` (la virgule est aussi acceptée à l'import), mis en majuscules | `tag`, `etiquettes` |
| `structure` | | Blocs de la séance (voir ci-dessous) | `blocs`, `blocks` |
| `faite` | | `oui` / `non` à l'export ; à l'import, `oui`, `o`, `yes`, `y`, `true`, `1`, `x`, `fait`, `faite` valent « faite » et toute autre valeur vaut « non faite » | `fait`, `done`, `realisee`, `completed` |
| `notes` | | Texte libre | `note`, `commentaire`, `comment` |

**Sports** : le code n'est sensible ni à la casse ni à l'accent (`VELO` est accepté). Les équivalents suivants sont aussi reconnus :

- `RUN`, `RUNNING`, `COURSE` → `CAP`
- `BIKE`, `CYCLING` → `VÉLO`
- `SWIM`, `NATATION` → `NAT`
- `STRENGTH`, `RENFO`, `MUSCULATION` → `MUSCU`
- `REST` → `REPOS`

**Structure** : les blocs sont séparés par `|`. Chaque bloc a la forme `titre~détail~durée_min~intensité`, où l'intensité vaut `L` (basse), `M` (moyenne, la valeur par défaut) ou `H` (haute). À l'export, les caractères `|` et `~` présents dans le titre ou le détail d'un bloc sont remplacés par `/` et `-`.

### Exemple

```csv
date;sport;titre;sous_titre;duree_min;distance_km;allure_cible;fc_cible;rpe;heure;lieu;tags;structure;faite;notes
2026-10-26;CAP;Fractionné 8 × 400 m;Piste · récup 90″;55;11;3′20 /km;Z4 · 172;8;18h30;Stade Léo Lagrange;PISTE|VMA;Échauffement~Footing souple~20~M | 8 × 400 m~@ 3′20/km~25~H | Retour au calme~Footing lent~10~L;non;
2026-10-27;MUSCU;Renfo bas du corps;6 exercices · 3 séries;45;;;;6;7h30;;;;oui;"Squats lourds; genou OK"
2026-10-29;REPOS;Mobilité 15′ optionnelle;;;;;;;;;;;non;
```

### Import

L'import valide tout le fichier avant de modifier quoi que ce soit. À la première erreur, il s'arrête et indique le numéro de ligne. Les erreurs possibles sont : colonne obligatoire absente, date invalide, sport inconnu, titre vide, durée ou distance illisible, RPE en dehors de 1 à 10.

Deux modes d'import :

- **Fusionner** : une séance existante qui a la même date et le même titre (sans tenir compte de la casse) est remplacée. Les autres séances sont conservées.
- **Remplacer** : tout le plan est remplacé par le contenu du fichier.
