# Gestion du linge — guide de présentation et de validation

## 1. Base de données indépendante

Fichier créé : `lib/database/laundry_database.dart`.

`LaundryDatabase.instance` est un singleton : les repositories utilisent le même accès à `laundry.db`. Le fichier est placé dans le répertoire SQLite de l'application Android. Il est distinct de `residry.db`. Le champ `_opening` partage une initialisation en cours entre plusieurs appels. `initialize()` permet une ouverture explicite ; sinon le premier appel au repository ouvre la base. `close()` attend une ouverture éventuelle puis ferme la connexion. Ne fermer la connexion qu'après la fin des opérations en cours, par exemple dans un outil de développement ; ne pas la fermer à chaque changement de rôle.

La version initiale était 1. La version actuelle est **2** : `onUpgrade` ajoute uniquement la colonne `price_confirmed` aux installations existantes. Les demandes, montants et historiques sont conservés ; les anciens montants nécessitent une validation administrateur car la version précédente permettait leur saisie par un résident. `onConfigure` active les clés étrangères sur la connexion. `onCreate` crée directement le schéma actuel et ses trois index pour une nouvelle installation. Aucune suppression de fichier et aucun réensemencement automatique ne sont effectués au lancement.

- `laundry_items` contient une ligne par demande. `id` est sa clé primaire texte. `created_at` conserve la date de création UTC au format ISO 8601.
- `laundry_status_history` contient une ligne par création ou changement de statut. Sa clé étrangère référence une demande ; `ON DELETE CASCADE` efface son historique si elle est supprimée.
- `resident_id` et `changed_by_user_id` sont des références applicatives facultatives. Les utilisateurs appartiennent à une autre base : aucune fausse clé étrangère entre bases n'est créée.
- Les index accélèrent les recherches par résident, statut et demande dans l'historique.

Dépendances : `sqflite` était déjà déclaré ; `path: ^1.9.1` a été ajouté directement pour construire le chemin sans concaténation manuelle. Le verrouillage des versions existantes est conservé.

## 2. Modèles et repository

Fichier déplacé : `lib/models/laundry_item.dart`. `LaundryItem.toMap()` transforme les propriétés Dart en colonnes SQLite. `fromMap()` effectue l'opération inverse. `createdAt` est facultatif dans le constructeur pour préserver les appels existants ; `copyWith()` conserve cette date. Les quatre statuts existants restent identiques. Leur propriété `label` fournit le texte français.

Fichier déplacé : `lib/models/laundry_status_change.dart`. `LaundryStatusChange` représente une ligne d'historique, avec ancien statut facultatif, nouveau statut, date et auteur facultatif.

Fichier modifié : `data/repositories/laundry_repository.dart`. Le repository ne contient plus de liste ni de demandes fictives. `getAll()`, `getByResidentId()`, `getById()`, `add()`, `update()` et `delete()` sont asynchrones. Les requêtes utilisent des paramètres `?` et `whereArgs`, ou les méthodes structurées `insert/update` ; les valeurs utilisateur ne sont pas concaténées au SQL.

`add()` insère la demande et un premier historique. `update()` est la méthode CRUD administrateur ; un changement de statut ajoute un historique. Les opérations sont regroupées dans une transaction : si l'historique échoue, la modification est annulée aussi. Un simple changement de service/prix n'ajoute pas de changement de statut.

`addForResident()`, `updateForResident()` et `deleteForResident()` servent à l'espace résident. La création ignore tout montant et toute confirmation de tarif fournis. L'édition et la suppression relisent la ligne dans une transaction et contrôlent son propriétaire et son statut `deposited`. L'édition résident écrit uniquement le service ; si ce service change, elle invalide l'ancien tarif sans changer son montant. Le résident ne peut modifier ni prix, ni identité, ni statut. `getByResidentId()` exclut les valeurs financières de ses objets de retour ; le modèle compatible utilise 0 comme valeur interne, jamais affichée comme un prix au résident. `getStatusHistory(..., residentId: ...)` contrôle également le propriétaire.

`transitionStatus()` accepte uniquement :

| Rôle | Ancien statut | Nouveau statut |
| --- | --- | --- |
| Société de pressing | deposited | processing |
| Société de pressing | processing | ready |
| Livreur | ready | delivered |

La méthode vérifie le rôle et la transition, puis relit le statut SQLite dans la transaction. Une action utilisant un ancien affichage échoue si le statut a changé entre-temps. La mise à jour et l'historique réussissent ensemble. Les méthodes administrateur restent distinctes pour permettre le CRUD demandé, y compris la correction d'un statut.

`databaseProvider` est une injection facultative pour tester les règles sans plugin Android. Les tests Dart utilisent un double en mémoire ; l'application utilise toujours SQLite par défaut. Les rôles transmis ne remplacent pas une authentification serveur : lors de l'intégration, le code appelant doit choisir la destination d'après l'utilisateur authentifié.

## 3. Interfaces et actions asynchrones

### Responsabilités métier

| Rôle | Consultation | Actions |
| --- | --- | --- |
| Résident | Ses demandes et leur historique, sans information financière | Demander un service, le modifier ou supprimer sa demande avant prise en charge |
| Société de pressing | Les demandes, leur historique et le tarif validé en lecture seule | Commencer le traitement et marquer prêt |
| Livreur | Demandes prêtes et livrées, sans information financière | Confirmer la remise effective au résident |
| Administrateur | Toutes les demandes, tarifs et états de traitement | CRUD, association d'un résident, validation des tarifs et suivi global |

Le parcours reste : demande déposée par le résident → traitement par le pressing → demande prête → livraison confirmée par le livreur. L'administrateur supervise ce parcours et valide les tarifs indépendamment du traitement. Le prix n'est pas une information demandée au résident. Une demande non tarifée peut continuer son parcours, conformément aux transitions initiales ; aucun système de paiement n'est ajouté.

Fichiers : `presentation/laundry_page.dart`, `presentation/pages/resident_laundry_page.dart`, `presentation/pages/pressing_laundry_page.dart`.

- Le résident voit uniquement les demandes de son identifiant reçu par constructeur, leur service, date, statut, prochaine étape et historique. **Il ne voit et ne saisit aucun prix**, dans les cartes comme dans les dialogues. Il peut choisir un service suggéré ou décrire son besoin. Ses demandes en cours et livrées sont séparées. Modifier/supprimer disparaissent après le dépôt. Aucun identifiant résident de test n'est fixé dans cet écran.
- Le pressing consulte et filtre les demandes ; il peut commencer le traitement puis marquer le linge prêt. Il n'a aucun formulaire de prix/résident, ni création ou suppression.
- L'administrateur conserve le titre, les cartes et les filtres existants. Il est le seul rôle avec un formulaire de tarification. Un champ tarif vide laisse la demande à valider ; saisir explicitement 0 confirme un service gratuit. Le filtre « Tarifs à valider » et le total des tarifs validés facilitent le suivi. Ce total ne représente pas des paiements encaissés. Le repository facultatif est réellement utilisé et `const LaundryPage()` reste valide. L'identifiant résident facultatif permet d'associer une demande au bon compte ; il reste en lecture seule une fois lié, mais une demande sans compte peut être associée ultérieurement.

Fichier : `presentation/pages/driver_laundry_page.dart`. `DriverLaundryPage` expose uniquement les demandes prêtes et livrées, sans prix ; il s'ouvre sur la file des demandes prêtes. La livraison demande une confirmation de remise au résident puis affiche la catégorie livrée. Le pressing voit le tarif confirmé en lecture seule, ou une indication de validation à effectuer par l'administrateur. Les deux écrans proposent recherche et historique, et classent leurs demandes par étape puis par ancienneté. Le composant partagé `LaundryWorkflowView` ne construit jamais l'écran administrateur.

Fichiers :

- `presentation/widgets/laundry_async_state.dart` : petit mixin partagé pour charger les listes hors de `build()`, afficher attente/erreurs, réessayer, actualiser après une écriture et désactiver les actions pendant l'enregistrement. Un compteur empêche une ancienne réponse de remplacer un chargement plus récent. Les retours asynchrones vérifient `mounted` avant de modifier l'écran.
- `presentation/widgets/laundry_admin_dialog.dart` : formulaire administrateur avec validation des champs et du prix fini positif ou nul. Le dialogue possède ses contrôleurs et les libère dans `dispose()`.
- `presentation/widgets/laundry_history_dialog.dart` : lit et affiche l'historique en français, avec dates locales et auteur lorsqu'il est connu.
- `presentation/widgets/laundry_insights.dart` : calcule les compteurs adaptés au rôle, la prochaine étape lisible par le résident, les dates françaises et la recherche. Ces aides suivent des règles locales explicites ; elles ne font pas appel à un modèle d'IA ou à un service distant.

Chemin d'une action : bouton → dialogue éventuel → validation → méthode du repository attendue avec `await` → transaction SQLite → rechargement de la liste. Une erreur produit un message français ; un échec de lecture propose « Réessayer ».

## 4. Navigation de développement

Fichiers : `presentation/navigation/laundry_routes.dart`, `laundry_dev_main.dart`.

`LaundryRoutes` définit quatre chemins et quatre builders `MaterialPageRoute` : `residentPage`, `driverPage`, `pressingPage`, `adminPage`. Les builders retournent des routes à transmettre à `Navigator.of(context).push(...)` ; les constantes seules ne sont pas automatiquement enregistrées dans `MaterialApp.routes`. La route résident utilise son propre Scaffold ; les trois autres routes enveloppent leur contenu une seule fois.

Le lanceur possède un menu à quatre rôles. Il injecte le même repository dans tous les écrans et conserve `AppTheme.light` et `debugShowCheckedModeBanner: false`. Seul ce lanceur utilise Ahmed, identifiant 1. L'option `embedded: true` évite un second Scaffold résident dans ce lanceur et peut être utilisée plus tard dans une interface de navigation partagée.

Dans PowerShell :

```powershell
& C:\src\flutter\bin\flutter.bat run --no-dds -d emulator-5554 -t lib/features/laundry/laundry_dev_main.dart
```

Dans Git Bash :

```bash
/c/src/flutter/bin/flutter.bat run --no-dds -d emulator-5554 -t lib/features/laundry/laundry_dev_main.dart
```

La sélection de rôle simule plusieurs utilisateurs sur UN appareil et UN fichier SQLite. Elle ne synchronise pas différents téléphones. Une synchronisation réelle demanderait un backend, hors du périmètre actuel.

L'option `--no-dds` contourne le problème de connexion DDS rencontré sur ce poste. Si votre émulateur utilise un autre identifiant, adapter `-d`. Après le passage du schéma 1 au schéma 2, effectuer un **hot restart** (`R` majuscule dans le terminal Flutter) ou un arrêt/relancement ; un simple hot reload ne réinitialise pas la connexion SQLite déjà ouverte.

## 5. Intégration équipe après fusion de main

La fusion autorisée conserve les nouveaux écrans de l'équipe. La navigation administrateur utilise le module SQLite ; les autres espaces restent à raccorder explicitement à ce module.

| Fichier existant | Intégration proposée | Informations requises |
| --- | --- | --- |
| `lib/features/auth/presentation/auth_screen.dart` | `_signIn()` possède le `User` complet mais `_openHome(name, role, email: ...)` ne transmet pas son identifiant. Transmettre aussi `user.id` aux écrans d'accueil ; conserver les règles d'authentification existantes. | `User.id` non nul, `User.name`, `User.role` |
| `lib/features/residents/presentation/residents_home_page.dart` | Relier « Mes demandes de linge » à `LaundryRoutes.residentPage(...)`, ou intégrer `ResidentLaundryPage(embedded: true, ...)`. Les pages résidentes entrantes utilisent encore leurs propres données de démonstration, distinctes de `laundry.db`. | Identifiant et nom authentifiés ; repository partagé |
| `lib/features/casiers/presentation/admin/admin_interface.dart` | Le menu 10 ouvre le contenu 7 de l'IndexedStack : `LaundryPage(showAppBar: false)`, sans second Scaffold. Le paramètre facultatif `laundryRepository` permet une injection pour les tests. | Identité administrateur facultative pour une future attribution de toutes ses actions |
| `lib/features/casiers/presentation/navigation/admin_navigation_bar.dart` | L'entrée « Gestion du linge » existe déjà ; aucun remplacement nécessaire. | Aucun changement obligatoire |
| `lib/features/delivery_drivers/presentation/driver_interface.dart` | L'authentification ouvre d'abord `driver_onboarding_page.dart`. Ajouter « Livraison du linge » ouvrant `LaundryRoutes.driverPage(repository: ..., userId: ...)`. | Identifiant authentifié du livreur pour l'historique |
| `lib/features/laundry_companies/presentation/company_interface.dart` | Ajouter « Gestion du linge » ouvrant `LaundryRoutes.pressingPage(...)`. Le repository des sociétés et son modèle `LavageOrder` restent distincts des demandes SQLite du module linge. | Rôle authentifié et identifiant du pressing |

Tous les repositories par défaut pointent vers `LaundryDatabase.instance`, donc vers le même `laundry.db`. Il est aussi possible de partager explicitement une instance de `LaundryRepository`. Ne pas relier ce helper à `AppDatabase` et ne pas modifier `lib/database/database.dart`. Les écrans de rôle n'ont pas à recréer les utilisateurs.

## 6. Tests et limites de validation

Tests Dart : `test/laundry/laundry_repository_test.dart`, `laundry_widgets_test.dart` et le double `support/memory_database.dart`. Ils vérifient les règles métier, les refus d'accès, les transitions obsolètes/interdites, l'historique, le rollback simulé, les formulaires, les écrans, les routes, le sélecteur de rôles et la récupération après erreur. Le double ne prouve pas le comportement du plugin Android ni la durabilité sur un téléphone.

Tests SQLite : `test/laundry/schema_test.py` utilise la bibliothèque standard Python et le SQL extrait du helper Dart. Il vérifie le schéma réel, la persistance après fermeture/réouverture, les index, la clé étrangère, la cascade et le rollback réel. Il ne lance pas `sqflite` sur Android.

Commandes :

```powershell
& C:\src\flutter\bin\flutter.bat analyze lib/features/laundry
& C:\src\flutter\bin\flutter.bat test --no-pub test/laundry
python -B -m unittest discover -s test/laundry -p schema_test.py -v
```

## 7. Scénarios Android à exécuter manuellement

Démarrer un émulateur Android, puis lancer l'entrée indépendante ci-dessus. Ne pas désinstaller l'application ou effacer ses données pendant les vérifications de persistance.

1. **A — Résident** : choisir Résident, créer Lavage sans aucun champ de prix ; vérifier qu'aucun montant n'est affiché. Modifier le service en Repassage. Depuis l'administrateur valider un tarif, puis revenir au résident : aucun prix ne doit être visible, même dans l'historique. Modifier à nouveau le service avant traitement : le tarif doit repasser à valider côté administrateur. Créer une seconde demande puis la supprimer après confirmation.
2. **B — Pressing** : garder une demande déposée, choisir Société de pressing, vérifier service/résident/prix/ID, commencer le traitement, puis marquer prêt. Vérifier les filtres et l'absence de création/modification/suppression. Revenir au résident et ouvrir l'historique ; modifier/supprimer ne doivent plus être proposés.
3. **C — Livreur** : choisir Livreur ; la file Prêt apparaît sans prix. Cliquer sur la livraison, l'annuler et vérifier que le statut reste prêt. Confirmer ensuite la remise ; vérifier le filtre Livré, l'historique et la disparition du bouton. Aucun traitement, CRUD administrateur ou retour arrière ne doit être proposé.
4. **D — Administrateur** : vérifier les mêmes statuts ; créer une demande avec l'identifiant résident 1 pour la retrouver dans l'espace Ahmed. Laisser le tarif vide puis vérifier « À tarifer ». Valider un tarif de 15 DT puis un service gratuit de 0 DT : ils doivent être distincts d'une demande non tarifée. Tester le filtre des tarifs à valider, la recherche et le total (seuls les tarifs confirmés comptent). Créer et associer une demande sans identifiant, puis vérifier les détails et supprimer une demande de test.
5. **E — Persistance** : créer une demande identifiable, faire un hot restart puis vérifier sa présence. Arrêter entièrement l'application et la relancer avec la même entrée ; vérifier service, statut et historique, puis le tarif dans l'espace administrateur uniquement. Changer de rôle pour vérifier les mêmes demandes. La vérification Python de réouverture ne remplace pas cette vérification Android.
6. **F — Navigation et isolation** : parcourir les quatre rôles. Vérifier qu'aucun contrôle administrateur n'apparaît pour le livreur. Depuis l'administrateur créer une demande pour l'identifiant résident 2 ; Ahmed (identifiant 1) ne doit pas la voir. Tester les quatre builders via la navigation Flutter lors de l'intégration ; les tests widgets les ouvrent déjà indépendamment.

Les scénarios Android de bout en bout restent à confirmer manuellement. Aucun succès Android ne doit être déduit des seuls tests Dart ou Python.
## 8. Validation initiale du 15 octobre 2026 (avant la révision des tarifs)

- Suite Flutter complète : **26 tests réussis**, dont 23 tests du module linge et 3 tests existants du projet.
- Tests SQLite Python : **4 tests réussis**.
- Aucun émulateur/appareil Android n'était connecté (`adb devices` vide) ; les scénarios Android ci-dessus restent à effectuer.
- Aucun commit, push, changement de branche ou modification des écrans partagés n'a été effectué. Seuls `pubspec.yaml` et son lockfile ont été ajustés hors du module et de ses tests pour déclarer directement `path`.

## 9. Validation de la révision métier du 15 octobre 2026

- Analyse du module et de ses tests : **aucun problème détecté**.
- Suite Flutter complète : **36 tests réussis** (33 tests du module linge et les 3 tests existants).
- SQLite réel via Python : **6 tests réussis**, dont migration 1 → 2 conservant demandes, montants et historique.
- Les nouveaux tests couvrent l'absence de prix dans l'écran, le formulaire et l'historique résident ; l'absence de tarif réel dans ses lectures ; les tentatives de modification de prix ; l'invalidation d'un tarif après changement de service ; le service gratuit confirmé ; la confirmation/annulation d'une livraison ; les filtres et totaux administrateur.
- Aucun paquet supplémentaire ni modification des fichiers partagés n'a été nécessaire pour cette révision. Les opérations de versionnement restent à la main de l'étudiant.
- Le rechargement de la session Android déjà ouverte a rencontré un ancien modèle en cache ; effectuer un arrêt puis un lancement complet avec la commande ci-dessus. Le chargement Android de cette révision et les parcours manuels restent à vérifier ; les 36 tests Flutter et 6 tests SQLite sont les résultats automatisés effectivement exécutés.

## 10. Vérification de la fusion de main du 15 octobre 2026

- Les sept conflits concernent la navigation administrateur, le modèle, le repository, le lanceur, la page administrateur et les dépendances. Le modèle et le repository SQLite du module sont conservés ; les nouvelles destinations du menu de main sont préservées.
- `showAppBar: false` permet à la page administrateur de réutiliser le Scaffold de son parent ; `const LaundryPage()` reste autonome. Le dialogue de statut s'adapte aussi aux écrans de 360 pixels de large.
- Le test administrateur crée explicitement sa demande dans un repository injecté ; aucune donnée fictive n'est ajoutée à la base de production.
- Analyse du projet complet : aucun problème détecté. Suite Flutter complète : **50 tests réussis**. SQLite Python : **6 tests réussis**.
- Le test compact entrant émet des avertissements de clics masqués dans son parcours d'onboarding livreur et dans sa dernière étape linge. Il réussit, mais ces clics ne prouvent pas le parcours complet. Les nouveaux tests linge ouvrent directement le formulaire autonome et le formulaire intégré et vérifient leur fonctionnement.
- Le contrôle Git des espaces signale une ligne avec espace final déjà présente dans `company_interface.dart` de main ; elle n'a pas été modifiée pour cette fusion.
- Ces vérifications ne remplacent pas les scénarios Android manuels. La collecte chez le résident reste une évolution proposée : cette fusion ne modifie pas les quatre statuts existants.
