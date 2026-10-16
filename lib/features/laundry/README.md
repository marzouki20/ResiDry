# Gestion du linge — intégration aux comptes de l'équipe

## Une base commune, un seul modèle User

Le module utilise `AppDatabase.instance.database` dans `lib/database/database.dart`,
donc le fichier commun **residry.db**, version **10**. `lib/models/user.dart` est
réutilisé sans modification. Aucun compte, table d'utilisateurs, mot de passe ou
rôle propre au module n'est créé. Les autres tables de l'équipe restent présentes.
L'ancien helper `lib/database/laundry_database.dart` a été retiré.

```text
residry.db
  users.id ──────────< laundry_items.resident_id
  users.id ──────────< laundry_status_history.changed_by_user_id
  laundry_items.id ─< laundry_status_history.laundry_id
```

`residentId` signifie l'identifiant du compte résident dans **users** ; il ne
signifie jamais `residents.id`, dont la numérotation est indépendante.
`laundryId` désigne une demande de linge, pas un utilisateur. Un utilisateur peut
posséder plusieurs demandes et effectuer plusieurs changements de statut.

Les trois relations sont des clés étrangères du même fichier SQLite. Une demande
supprimée entraîne la suppression de son historique. Un compte référencé ne peut
pas être supprimé directement (`ON DELETE RESTRICT`). Les clés étrangères sont
activées sur la connexion commune. Les colonnes existantes de `users` restent
`id`, `name`, `email`, `password`, `role`, `phone` : phone provient de main.

## Conservation des anciennes données

La migration vers la version 10 conserve les migrations de main et ajoute les tables Laundry absentes. A la
création d'une base commune neuve, les mêmes tables sont créées directement.
Si un ancien `laundry.db` existe, il est ouvert **en lecture seule**, sans upgrade.
Les demandes et événements sont copiés dans la transaction de migration.

- Les identifiants des demandes et des événements, noms historiques, services,
  statuts, montants, confirmations de tarifs et dates sont conservés.
- Les anciens identifiants numériques de résident et d'auteur ne sont pas
  considérés comme des liens prouvés vers les comptes communs. Dans la copie,
  `resident_id` et `changed_by_user_id` restent donc NULL.
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

- **Résident** : crée une demande de service sans saisir son identité ni un prix ;
  consulte seulement ses demandes ; modifie/supprime uniquement ses dépôts.
  Les lectures qui lui sont destinées masquent également les montants.
- **Pressing** : consulte les demandes et leur historique ; passe de Déposé à En
  traitement, puis à Prêt. Aucun CRUD administrateur ni modification du prix.
- **Livreur** : consulte uniquement les demandes Prêt/Livré, sans prix ; confirme
  une livraison Prêt → Livré. Pas de création, suppression ou retour arrière.
- **Administrateur** : gère les demandes, les tarifs, les filtres et les détails.
  La création demande un compte résident existant via une liste ; pas de nom/ID
  saisis indépendamment. Un prix vide reste à valider ; 0 explicite est gratuit.

Les changements de statut relisent le statut sauvegardé et écrivent le nouveau
statut et l'événement dans une même transaction. Un échec annule les deux.
La collecte chez le résident reste une évolution future : aucun nouveau statut
ou lien d'affectation à une société/livreur n'est inventé.

## Navigation et fichiers

- Modèles : `lib/models/laundry_item.dart`, `laundry_role.dart`,
  `laundry_status_change.dart`, avec le `User` commun inchangé.
- Base : `lib/database/database.dart` ; repository et annuaire sous
  `lib/features/laundry/data/repositories/`.
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

## Validation des conflits - 16 octobre 2026

- Tests Laundry : **45 tests passes** : comptes, roles, propriete, historique,
  imports et migrations 5/6/9 vers 10.
- SQLite Python : **8 tests passes**.
- Suite complete : neuf echecs, egalement reproduits sur une copie isolee
  de main (`914c91e`) : formulaire compact et navigation administrateur.
- Analyse lib/test : aucune erreur ni warning ; 18 remarques de lint
  preexistantes dans main. Les tests backend sans serveur restent ignores.
- Compilation APK et parcours Android : non verifies pendant cette resolution.
- Conflits resolus et indexes localement ; aucun nouveau commit ni push.

## Compatibilite avec main

La version 10 conserve les migrations livreur de main (versions 7 a 9).
Si les tables linge existent deja (ancienne version 6), elles sont conservees
sans reimporter les archives. Le login local transmet le User authentifie,
y compris son ID et son telephone.

Le login backend conserve son fonctionnement existant. Les identifiants serveur
ne sont jamais assimiles aux identifiants SQLite locaux. Le linge local exige
un compte local authentifie ; sa synchronisation backend reste a integrer.
