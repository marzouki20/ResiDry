# Gestion intelligente du linge — ResiDry

Le module gère les demandes, les vêtements, leur traitement et les réclamations.
Il ne remplace pas le module de gestion des sociétés de pressing.

## Une base commune, un seul modèle User

Le module utilise `AppDatabase.instance.database` dans `lib/database/database.dart`,
donc le fichier commun **residry.db**, version **14**. `lib/models/user.dart` est
réutilisé sans modification. Aucun compte, table d'utilisateurs, mot de passe ou
rôle propre au module n'est créé. Les autres tables de l'équipe restent présentes.
L'ancien helper `lib/database/laundry_database.dart` a été retiré.

```text
residry.db
  users.id ───────────< laundry_items.resident_id
  users.id ───────────< laundry_complaints.resident_id
  users.id ───────────< laundry_events.actor_id
  laundry_items.id ───< laundry_complaints.laundry_id
  laundry_items.id ───< laundry_events.laundry_id
  laundry_complaints.(id, laundry_id)
                    └< laundry_events.(complaint_id, laundry_id)

  laundry_items.lines_json : vêtements, devis figés et informations de tri
  laundry_services.pricing_rules_json : versions des tarifs
```

`residentId` signifie l'identifiant du compte résident dans **users** ; il ne
signifie jamais `residents.id`, dont la numérotation est indépendante.
`laundryId` désigne une demande de linge, pas un utilisateur. Un utilisateur peut
posséder plusieurs demandes et effectuer plusieurs changements de statut.

Les relations du diagramme sont des clés étrangères du même fichier SQLite. Une
demande sans réclamation peut être supprimée avec son historique ; une réclamation
bloque sa suppression. Un compte référencé par ces clés étrangères ne peut pas
être supprimé directement (`ON DELETE RESTRICT`). Les clés étrangères sont
activées sur la connexion commune. Les colonnes existantes de `users` restent
`id`, `name`, `email`, `password`, `role`, `phone` : phone provient de main.

## Quatre tables métier

| Table | Contenu |
| --- | --- |
| `laundry_items` | Demande, résident associé, statut, prix confirmé ou à valider, dates, échéance, urgence, révision et `lines_json`. |
| `laundry_services` | Identifiant du service, libellés français/anglais/arabe, activation, date de création et `pricing_rules_json`. |
| `laundry_complaints` | Demande et résident concernés, vêtement signalé, motif, description, statut, décision, dates, révisions de lecture et trois emplacements de photos avec métadonnées JSON. |
| `laundry_events` | Type d'événement, identifiant historique conservé, demande/réclamation, anciens/nouveaux statuts, auteur réel, commentaire, révision et date. |

Les lots de vêtements conservent quantité, poids, service, instructions, montant
calculé, référence du tarif utilisé et observations de tri. Les tarifs conservent
leur unité pièce/kg, prix en millimes, durée estimée éventuelle, période de validité
et auteur. Ce regroupement réduit le nombre de tables sans supprimer ces données.
Les relations internes aux listes JSON sont contrôlées par Dart ; elles ne sont
plus des clés étrangères SQL distinctes.

## Conservation des anciennes données et migrations

La migration **14** regroupe les huit anciennes tables Laundry dans les quatre
tables ci-dessus, dans une transaction SQLite. Elle compare les données copiées
avant de retirer les anciennes tables Laundry : demandes, vêtements, prix,
versions tarifaires, informations de tri, photos et deux historiques sont
conservés, y compris leurs identifiants historiques. Les tables des collègues et
la définition de `users` ne sont pas modifiées par cette conversion.

Une erreur annule toute la conversion, même après le retrait des tables sources.
Une dépendance externe incompatible, un schéma inattendu ou plus de trois photos
sur une ancienne réclamation provoque un refus de conversion plutôt qu'une perte
de données. Les anciennes définitions SQL restent dans `laundry_schema.dart`
pour permettre les mises à niveau ; la base finale contient quatre tables Laundry.

### Import historique de l'ancienne base séparée

La migration historique vers la version 10 conserve les migrations de main et ajoute les tables Laundry absentes. À la
création d'une base commune neuve, les mêmes tables sont créées directement.
Si un ancien `laundry.db` existe, il est ouvert **en lecture seule**, sans upgrade.
Les demandes et événements sont copiés dans la transaction de migration.

- Les identifiants des demandes et des événements, noms historiques, services,
  statuts, montants, confirmations de tarifs et dates sont conservés.
- Les anciens identifiants numériques de résident et d'auteur ne sont pas
  considérés comme des liens prouvés vers les comptes communs. Dans la copie,
  `resident_id` et l'auteur historique restent donc NULL (`actor_id` dans le
  schéma actuel).
- **Le fichier original reste intact**, avec tous ses identifiants originaux.
  Il sert d'archive de rapprochement ; il n'est ni supprimé ni utilisé pour les
  nouvelles opérations. Ne pas le supprimer avant réconciliation de l'équipe.
- Les anciennes demandes restent visibles aux administrateurs ; aucun résident
  ne les reçoit simplement parce qu'un numéro correspond à son compte.
- Un administrateur peut associer explicitement une demande importée en
  sélectionnant un compte résident existant. Le nom historique reste conservé.
- L'historique ancien est affiché avec « Auteur historique non associé ».
  Aucun auteur n'est inventé. Les nouvelles actions utilisent le compte connecté.
- Les anciens schémas Laundry 1, 2 et 3 sont pris en charge. Un ancien schéma 1
  sans confirmation de prix est importé avec un tarif à valider.
- Une erreur d'import annule la migration, sans reset destructif ni import partiel.

Aucune colonne `resident_link_verified` ou `actor_verified` n'est nécessaire dans
la nouvelle base. La migration n'essaie jamais de créer ou recopier des comptes.
Après mise à jour du code, arrêter puis relancer complètement l'application pour
que SQLite exécute sa migration ; un simple hot reload ne suffit pas.

## Identité et autorisations

L'authentification conserve le `User` trouvé lors du login. Lors d'une inscription,
elle récupère l'ID retourné par la création du compte existante. Cet objet suit la
navigation, y compris l'onboarding livreur. Les règles de login sont conservées.

`LaundryRepository(currentUser: user)` représente cet acteur. Chaque opération
relit son compte dans `users` et vérifie son rôle dans la même transaction que
l'opération. Une identité absente, supprimée ou un rôle inconnu est refusé.
L'injection d'une base de test ne désactive jamais ces contrôles.

`LaundryUserDirectory` effectue seulement des lectures de la table existante. Il
retourne le modèle central `User`, sans nouveau modèle ni compte propre au linge.
`LaundryRole` sert uniquement à interpréter les chaînes officielles :

| User.role enregistré | Enum |
| --- | --- |
| Résident | resident |
| Livreur | driver |
| Société de lavage | pressing |
| Administrateur | admin |

« Société de pressing » reste un libellé d'interface, pas une nouvelle chaîne
acceptée pour accorder des permissions. Les rôles des écrans ne remplacent jamais
le rôle du compte. Les anciens paramètres publics d'ID restent compatibles, mais
ne permettent pas de choisir un autre auteur ou d'obtenir des droits.

Pour un compte associé, `residentName` est résolu depuis `User.name` à chaque
lecture. `residentNameSnapshot` conserve l'ancien texte de `resident_name` ; il
n'est pas une autre identité utilisateur et n'est pas réécrit lors d'une lecture.
Les informations d'authentification ne sont jamais enregistrées dans les tables
Laundry. Toute nouvelle ligne d'historique utilise l'ID de l'acteur validé.

## Rôles et interface

- **Résident** : crée une demande avec ses vêtements, quantités, poids et services
  sans saisir son identité ni un prix ;
  consulte seulement ses demandes ; modifie/supprime uniquement ses dépôts.
  Les lectures qui lui sont destinées masquent également les montants. Il peut
  déposer une réclamation sur sa demande et suivre la réponse.
- **Pressing** : consulte les demandes et leur historique ; passe de Déposé à En
  traitement, puis à Prêt ; consulte les priorités et les suggestions de tri.
  Aucun CRUD administrateur ni modification du prix.
- **Livreur** : consulte uniquement les demandes Prêt/Livré, sans prix ; confirme
  une livraison Prêt → Livré. Pas de création, suppression ou retour arrière.
- **Administrateur** : gère les demandes, les tarifs, les filtres et les détails.
  La création demande un compte résident existant via une liste ; pas de nom/ID
  saisis indépendamment. Les demandes détaillées utilisent les tarifs configurés ;
  un tarif manquant reste à valider. Les anciens formulaires restent compatibles.
  Il examine aussi les réclamations et motive les décisions.

Les changements de statut relisent le statut sauvegardé et écrivent le nouveau
statut et l'événement dans une même transaction. Un échec annule les deux.
La collecte chez le résident reste une évolution future : aucun nouveau statut
ou lien d'affectation à une société/livreur n'est inventé.

## Fonctionnalités métier connectées

- **Tarification automatique** : tarifs configurés par pièce ou kilogramme,
  calcul en millimes entiers, conservation des anciennes versions et des devis
  enregistrés. Aucun tarif fictif n'est ajouté pour remplacer une donnée manquante.
- **Priorisation et retards** : classement expliqué à partir de l'urgence, de
  l'ancienneté, de l'échéance réelle et des durées disponibles. Une durée ou une
  échéance absente reste inconnue ; aucune capacité de pressing n'est inventée.
- **Statistiques** : demandes, retards, services utilisés, valeur des prestations
  livrées avec prix confirmé et durée de traitement lorsque l'historique le permet.
  Les données proviennent du repository et respectent les droits du compte.
- **Tri intelligent** : propositions selon couleur, tissu, cycle, température
  maximale de l'étiquette, risque de décoloration et lavage séparé. Le pressing
  ou l'administrateur vérifie les observations. Les informations ambiguës exigent
  un examen humain ; les demandes de résidents différents ne sont pas mélangées.
  Ce sont des règles explicables, sans machine learning.
- **Réclamations** : description, motif, vêtement concerné et jusqu'à trois photos
  locales de 2 Mio maximum chacune. Parcours Envoyée → En cours d'examen → Résolue
  ou Refusée, avec motif de décision et historique des auteurs authentifiés.
  Un indicateur dans l'application signale les réponses non lues ; il ne s'agit
  pas d'une notification push du système. Avoirs, codes promo et fidélité ne sont
  pas implémentés.

Les formulaires valident les saisies et gèrent chargement, erreurs et écritures
en cours. Les pages réutilisent `AppTheme.light` et la localisation commune
français/anglais/arabe, avec sélection de langue et affichage RTL en arabe.

## Navigation et fichiers

- Modèles : `lib/models/laundry_item.dart`, `laundry_role.dart`,
  `laundry_status_change.dart`, avec le `User` commun inchangé.
- Base : `lib/database/database.dart` ; repository et annuaire sous
  `lib/features/laundry/data/repositories/`.
- Schéma : `data/laundry_schema.dart` pour les migrations historiques,
  `data/laundry_compact_schema.dart` pour la version 14 ; `data/laundry_storage.dart`
  pour les lectures/écritures des quatre tables et les listes JSON.
- Services métier : `domain/services/` pour tarification, planification, suivi,
  statistiques, tri et règles des réclamations. Les structures spécifiques à ces
  calculs sont dans `domain/models/`, les mappings SQLite dans `data/models/`.
- Pages : `presentation/laundry_page.dart` et `presentation/pages/`.
- Routes : `presentation/navigation/laundry_routes.dart` ; les quatre destinations
  transmettent le compte et évitent les Scaffolds imbriqués.
- Widgets : `presentation/widgets/` pour formulaires, historique, état asynchrone,
  statistiques et accès de navigation.
- L'administrateur conserve son entrée existante dans le menu commun. Les accueils
  résident et livreur ont un accès Laundry qui transmet leur compte.
- Pour le pressing, un widget Laundry enveloppe l'accueil existant et ajoute un
  bouton « Gestion du linge ». Aucun fichier de Laundry Companies n'est modifié.
  Les commandes de démonstration des autres modules restent distinctes.

Un clic suit : page → repository → validation du compte/rôle → transaction SQLite
→ actualisation de la liste. Attente, erreurs, réessai et blocage pendant écriture
sont gérés par `LaundryAsyncState`. Les contrôleurs appartiennent aux dialogues
et sont libérés dans leur `dispose()`.

## Lancement et validation

```powershell
& C:\src\flutter\bin\flutter.bat run --no-dds -d emulator-5554 -t lib/features/laundry/laundry_dev_main.dart
& C:\src\flutter\bin\flutter.bat analyze --no-pub lib test
& C:\src\flutter\bin\flutter.bat test --no-pub test/laundry --concurrency=1
& C:\src\flutter\bin\flutter.bat test --no-pub
python -B -m unittest discover -s test/laundry -p schema_test.py -v
```

Le lanceur indépendant conserve `AppTheme.light` et masque la bannière debug.
Il ouvre le login réel de l'équipe. Utiliser un compte existant pour chaque rôle ;
aucun Ahmed/ID 1 n'est imposé et aucun sélecteur de rôle n'accorde des droits.
Les comptes prédéfinis dans `test/laundry/support/` sont uniquement des fixtures.

Les tests repository utilisent SQLite natif en mémoire via la dépendance FFI déjà
présente. Ils vérifient comptes, rôles, propriété, noms courants, historique,
rollback réel, clés étrangères et import d'archives intactes. Les tests widgets
vérifient formulaires, rôles et routes ; les tests Python exécutent le SQL extrait
du helper commun, notamment la conservation des comptes et la réouverture.

À vérifier sur Android : login des quatre comptes, création sans prix côté résident,
sélection administrateur, traitement pressing, livraison, refus d'accès croisé,
association explicite d'une ancienne demande et persistance après arrêt complet.
Ne pas désinstaller ni effacer les données pour ce test.

Le stockage est local à l'appareil : aucune synchronisation multi-appareils.
Flutter Web/Chrome n'est pas pris en charge par la persistance actuelle
(`dart:io`, sqflite natif, aucun adaptateur Web). Les tests ne prouvent pas un
fonctionnement Web ni un parcours Android complet.

## Validation — 29 octobre 2026

- Tests Laundry : **204 réussites**, un aperçu graphique facultatif ignoré.
- SQLite Python : **19 réussites**.
- Couverture : comptes, rôles, propriété, CRUD, contrôles de saisie, devis,
  priorités, retards, statistiques, tri, réclamations, photos, décisions,
  historique, routes, traductions, import d'archives et migrations.
- Migration 14 : conservation des données et des identifiants, quatre tables
  finales, données des collègues inchangées, réouverture et rollback après erreur.
- Suite Flutter complète : **250 réussites, 9 échecs, 4 tests ignorés**. Les neuf
  échecs ont les mêmes noms que lors de l'exécution précédente et concernent
  les tests des interfaces partagées, hors `test/laundry/`.
- Analyse `lib test` : aucune erreur ni warning ; **18 remarques informatives**
  hors Laundry.
- Parcours Android/caméra et compilation APK de cette version : non vérifiés.
  Les tests automatisés ne constituent pas une validation sur appareil.

## Compatibilité avec main

La chaîne de migrations conserve les migrations livreur de main (versions 7 à 9).
Si les tables linge existent deja (ancienne version 6), elles sont conservees
sans reimporter les archives. Le login local transmet le User authentifie,
y compris son ID et son telephone.

Le login backend conserve son fonctionnement existant. Les identifiants serveur
ne sont jamais assimiles aux identifiants SQLite locaux. Le linge local exige
un compte local authentifie ; sa synchronisation backend reste a integrer.
