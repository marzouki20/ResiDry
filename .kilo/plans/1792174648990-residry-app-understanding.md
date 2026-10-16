# ResiDry — RFID Laundry Tracking & Gestion des Commandes (Full Plan)

## Decisions Resolved (from interviews)
| Decision | Choice |
|----------|--------|
| RFID tag granularity | Per garment (1 tag per clothing item) |
| RFID read method | Hybrid — Flutter mobile NFC + dedicated RFID embedded IoT devices |
| Workflow stages | 12-stage RFID lifecycle |
| RFID data model | 3 tables: `garments`, `rfid_tags`, `rfid_read_events` |
| RFID scanning roles | Laundry company, smart locker (casiers), admin, delivery driver |
| Tracking map | GPS map with real-time location from RFID reads |
| RFID backend sync | Local-first SQLite, optional sync to Spring Boot when `RESIDRY_API_URL` set |
| Orders persistence | New `commandes` + `alertes_commandes` tables (replacing in-memory `demoManagedOrders`) |

## 12-Stage RFID Workflow

| # | Status | RFID Trigger | Actor | Location |
|---|--------|-------------|-------|----------|
| 1 | `Nouvelle` | Order created | Admin | — |
| 2 | `En attente` | Waiting | System | — |
| 3 | `Collectée` | Garment scan-out | Resident/Casier | Casier (smart locker) |
| 4 | `En transit collecte` | Garment scan-in | Delivery | Delivery van / casier |
| 5 | `En livraison vers blanchisserie` | — | Delivery | Route |
| 6 | `Arrivée blanchisserie` | Garment scan-in | Laundry co | Société de lavage intake |
| 7 | `En lavage` | Garment scan-in | Laundry co | Washing machine |
| 8 | `Lavage terminé` | Garment scan-out | Laundry co | Washing machine |
| 9 | `Prête` | Packaging complete | Laundry co | Packaging area |
| 10 | `En livraison retour` | Garment scan-in | Delivery | Delivery van |
| 11 | `Déposée casier` | Garment scan-in | Delivery | Casier (smart locker) |
| 12 | `Livrée` | Resident confirms | Resident | Casier |

**Rule:** An order cannot advance to the next stage unless ALL its garments have been scanned at the current checkpoint (except stage 5 which is transit-only).

## Database Schema Changes (residry.db — version 9 → 10)

### New tables

**`commandes`** — persists orders (replaces in-memory `demoManagedOrders`)
| Attribute | Type | Constraint |
|-----------|------|-----------|
| id | TEXT | PK |
| nom_resident | TEXT | NOT NULL |
| appartement | TEXT | NOT NULL |
| casier | TEXT | NOT NULL |
| societe_lavage | TEXT | NOT NULL |
| statut | TEXT | NOT NULL |
| type_linge | TEXT | NOT NULL |
| quantite | INTEGER | NOT NULL |
| poids | REAL | NOT NULL |
| date_creation | TEXT | NOT NULL |
| date_collecte | TEXT | NOT NULL |
| date_livraison | TEXT | NOT NULL |
| prix | REAL | NOT NULL |
| nom_livreur | TEXT | nullable |
| notes | TEXT | NOT NULL DEFAULT '' |
| date_collecte_terminee | TEXT | nullable |
| date_depart | TEXT | nullable |
| porte_fermee | INTEGER | NOT NULL DEFAULT 1 |
| iot_connecte | INTEGER | NOT NULL DEFAULT 1 |
| derniere_synchronisation | TEXT | NOT NULL |

**`garments`** — individual clothing items
| Attribute | Type | Constraint |
|-----------|------|-----------|
| id | TEXT | PK |
| commande_id | TEXT | NOT NULL → FK commandes(id) |
| resident_id | TEXT | nullable → FK residents(id) |
| type_vetement | TEXT | NOT NULL (chemise, pantalon, etc.) |
| taille | TEXT | nullable |
| couleur | TEXT | nullable |
| rfid_tag_id | TEXT | nullable → FK rfid_tags(tag_id) |
| statut | TEXT | NOT NULL DEFAULT 'En attente' |
| date_enregistrement | TEXT | NOT NULL |

**`rfid_tags`** — RFID tag metadata
| Attribute | Type | Constraint |
|-----------|------|-----------|
| tag_id | TEXT | PK (EPC) |
| garment_id | TEXT | nullable → FK garments(id) |
| commande_id | TEXT | nullable → FK commandes(id) |
| resident_id | TEXT | nullable |
| actif | INTEGER | NOT NULL DEFAULT 1 |
| date_enregistrement | TEXT | NOT NULL |

**`rfid_read_events`** — every RFID scan
| Attribute | Type | Constraint |
|-----------|------|-----------|
| id | INTEGER | PK AUTOINCREMENT |
| tag_id | TEXT | NOT NULL → FK rfid_tags(tag_id) |
| lecteur_id | TEXT | NOT NULL |
| type_lecteur | TEXT | NOT NULL (mobile / fixe) |
| localisation | TEXT | NOT NULL |
| latitude | REAL | nullable |
| longitude | REAL | nullable |
| type_evenement | TEXT | NOT NULL (scan_entree / scan_sortie) |
| lu_le | TEXT | NOT NULL |

**`alertes_commandes`** — alerts for dashboard
| Attribute | Type | Constraint |
|-----------|------|-----------|
| id | INTEGER | PK AUTOINCREMENT |
| commande_id | TEXT | NOT NULL → FK commandes(id) |
| titre | TEXT | NOT NULL |
| description | TEXT | NOT NULL |
| gravite | TEXT | NOT NULL CHECK (Élevée/Moyenne/Faible) |
| est_lue | INTEGER | NOT NULL DEFAULT 0 |
| date_creation | TEXT | NOT NULL |

### Migration
- Bump `AppDatabase` version from 9 → 10
- Add `onUpgrade` branch: `if (oldVersion < 10) { CREATE TABLE commandes, garments, rfid_tags, rfid_read_events, alertes_commandes }`
- Use `CREATE TABLE IF NOT EXISTS` + `INSERT ... ON CONFLICT IGNORE` for seed data

## Data Layer (new directory: `lib/features/orders/data/`)

**`order_repository.dart`** — abstract interface:
- `Future<List<Commande>> getAllCommandes()`
- `Future<Commande?> getCommandeById(String id)`
- `Future<int> insertCommande(Commande c)`
- `Future<int> updateCommande(Commande c)`
- `Future<int> deleteCommande(String id)`
- `Future<void> advanceStatus(String commandeId, String nextStatus)` — validates RFID completeness
- `Future<List<Garment>> getGarmentsByCommande(String commandeId)`
- `Future<List<Garment>> getUnscannedGarments(String commandeId, String checkpoint)`
- `Future<List<RfidReadEvent>> getReadEventsByTag(String tagId)`
- `Future<List<RfidReadEvent>> getReadEventsByCommande(String commandeId)`
- `Future<void> insertRfidReadEvent(RfidReadEvent e)`
- `Future<List<AlerteCommande>> getUnreadAlerts()`
- `Future<void> markAlertRead(int alertId)`

**`sqlite_order_repository.dart`** — SQLite implementation using `AppDatabase.instance`

## Models

### `lib/features/orders/data/models/`
- `commande.dart` — `Commande` class (updates `ManagedOrder` with `fromMap`/`toMap`, RFID fields)
- `garment.dart` — `Garment` class with RFID tag association
- `rfid_tag.dart` — `RfidTag` class
- `rfid_read_event.dart` — `RfidReadEvent` class
- `alerte_commande.dart` — `AlerteCommande` class

### `lib/models/` (updated)
- `delivery_order.dart` — add RFID fields or keep separate

## RFID Workflow Engine (`lib/core/rfid/`)

**`rfid_workflow.dart`** — validates status transitions:
- `Map<String, String> rfidNextStatus` — 12-stage transition map
- `bool canAdvance(String currentStatus, String nextStatus, List<Garment> garments)` — checks all garments scanned at checkpoint
- `List<String> requiredScanLocations(String status)` — where RFID must be read
- `String statusLabel(String status)` — French label

**`rfid_scan_validator.dart`** — business rules:
- Cannot scan same tag twice at same checkpoint within 5 minutes
- Cannot scan garment at wrong location (e.g., washing machine scan at casier)
- Alert generated on: missing tag, wrong location, delayed scan (>24h at same stage)

## UI Screens by Role

### Admin (`lib/features/orders/presentation/`)
1. **DashboardCommandes** — KPI cards + GPS map showing all orders with last RFID location
2. **ListeCommandes** — search/filter orders, filter by RFID status (scanned/unscanned)
3. **DetailsCommande** — garment-level RFID scan history timeline + map route
4. **AjouterCommande / ModifierCommande** — create order with garment list + RFID tag assignment
5. **AffecterLivreur** — assign driver, auto-set status to `Collecte prévue`
6. **AlertesCommandes** — RFID exception alerts (missing tags, wrong location, delays)
7. **StatistiquesCommandes** — stats with RFID scan compliance rate

### Delivery Driver (`lib/features/delivery_drivers/presentation/`)
8. **RfidScanScreen** — NFC scan garments at pickup/drop-off, shows scanned vs total count
9. **DriverInterface** — add RFID scan buttons to mission cards, map view of delivery route

### Laundry Company (`lib/features/laundry_companies/presentation/`)
10. **RfidScanScreen** — NFC scan garments at intake, washing machine load/unload, packaging
11. **SocieteInterface** — add RFID status to machine/order cards

### Resident (`lib/features/residents/presentation/`)
12. **ResidentOrderTrackingScreen** — track their garments through the 12 stages with map

### Smart Lockers / Casiers (`lib/features/casiers/presentation/`)
13. **CasierRfidScreen** — scan garments in/out of casier, link to resident's order

## Missing Features to Add (gestion des commandes)

1. **Order persistence** — `demoManagedOrders` → `commandes` table
2. **Garment management** — add/remove garments to an order with RFID tags
3. **RFID scan validation** — status can't advance without all garments scanned
4. **GPS tracking map** — show order location from last RFID read
5. **RFID exception alerts** — auto-generate alerts for scan anomalies
6. **Role-based RFID screens** — delivery, laundry, casier scanning interfaces
7. **Resident tracking** — resident can see their garments' location
8. **Scan history timeline** — visual timeline of all RFID scans per garment

## Implementation Tasks (ordered)

### Phase 1: Database
1. Bump `AppDatabase` schema version 9 → 10 in `lib/database/database.dart`
2. Add `_createCommandesTables(database)` — all 5 new tables
3. Add `onUpgrade` branch for version 10
4. Add repository methods to `AppDatabase` (CRUD for all 5 tables)

### Phase 2: Data Layer + Models
5. Create `lib/features/orders/data/` with `order_repository.dart` + `sqlite_order_repository.dart`
6. Create `lib/features/orders/data/models/` — `commande.dart`, `garment.dart`, `rfid_tag.dart`, `rfid_read_event.dart`, `alerte_commande.dart`
7. Update `ManagedOrder` in `order_data.dart` with `fromMap`/`toMap` and RFID fields
8. Create `lib/core/rfid/` — `rfid_workflow.dart`, `rfid_scan_validator.dart`

### Phase 3: Orders Module — Persistence Integration
9. Update `OrdersAdminModule` to inject `OrderRepository`, load from DB
10. Persist create/edit/assign/cancel via repository
11. Seed `commandes` table from `demoManagedOrders` on first launch (ON CONFLICT IGNORE)

### Phase 4: RFID Workflow + Validation
12. Implement status transition validation — order can't advance without all garments scanned at checkpoint
13. Implement RFID scan event recording with GPS, reader type, location
14. Implement alert generation for RFID exceptions

### Phase 5: UI — Role-Based RFID Screens
15. **Admin:** Update `DashboardCommandes` with GPS map, update `DetailsCommande` with garment RFID timeline
16. **Delivery:** Create `RfidScanScreen` in `delivery_drivers/presentation/`
17. **Laundry:** Create `RfidScanScreen` in `laundry_companies/presentation/`
18. **Casier:** Create `CasierRfidScreen` in `casiers/presentation/`
19. **Resident:** Create `ResidentOrderTrackingScreen` in `residents/presentation/`

### Phase 6: Alerts + Map
20. Update `AlertesCommandes` to show RFID exception alerts from DB
21. Create map widget showing order/garment location from last RFID read

### Phase 7: Tests + Validation
22. Add unit tests for `SqliteOrderRepository` (CRUD round-trip)
23. Add widget tests for RFID scan screens
24. Add integration test for full 12-stage RFID workflow
25. Run `flutter analyze`, `flutter test`
26. Run `flutter run` on emulator-5554 — verify orders persist across restart, RFID scans advance status

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Garment-level RFID = many tags per order (~20-50) | Bulk read support, batch scan UI, "scan all" button |
| NFC range limitations on Android | Fallback to manual tag ID entry, fixed RFID reader API |
| Offline RFID scans | Local SQLite first, sync when online (backend mode optional) |
| Status advancement without RFID scan | Enforce at repository layer, UI shows "waiting for scan" |
| Seed data duplication | `INSERT ... ON CONFLICT IGNORE`, check `COUNT(*)` before seeding |
| DateTime serialization | ISO-8601 UTC strings, `DateTime.parse()` on read |

## Validation Checklist
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes (existing + new RFID tests)
- [ ] Orders persist across app restart on emulator-5554
- [ ] RFID scan advances order status through all 12 stages
- [ ] Cannot advance status without all garments scanned at checkpoint
- [ ] GPS map shows last RFID read location per order
- [ ] RFID exception alerts generate correctly
- [ ] All 4 roles (admin, delivery, laundry, casier) have RFID scan screens