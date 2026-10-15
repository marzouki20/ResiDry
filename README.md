# ResiDry

### Smart Laundry Service for Residential Buildings

ResiDry is a Flutter mobile application concept for managing laundry services and
smart lockers in residential buildings. It brings residents, administrators,
delivery, and laundry operations into one mobile experience.

The current application includes authentication screens and role-specific
administrator, resident, and delivery interfaces. Delivery drivers and missions
are persisted locally in SQLite with validated assignment and mission-status
transitions. Locker readings and management actions still use demonstration
data; live IoT devices and a remote service are not connected yet.

---

## Project Information

| Item | Details |
| --- | --- |
| Project | ResiDry |
| Class | 4IET_I4 |
| Team | Ethivon |
| Platform | Mobile application |
| Framework | Flutter |
| Language | Dart |

---

## Getting Started

Install Flutter, then run the following commands from the repository root:

```bash
flutter pub get
flutter run
```

Run the relevant checks:

```bash
flutter analyze
flutter test
```

The app opens on the authentication screen. After signing in, the selected
account role determines the destination:

| Role | Destination |
| --- | --- |
| Résident | Resident smart-locker interface |
| Administrateur | Administrator smart-locker interface |
| Livreur | Delivery/order interface |
| Other roles | Generic locker placeholder |

Authentication currently uses a local SQLite database. The administrator and
resident casier screens use in-memory sample records and are intended as a UI
prototype.

On first launch, the app asks the user to choose French, English, or Arabic and stores
the preference locally. Authentication, administrator, resident, delivery-driver,
and laundry screens use the shared locale immediately, including menus, forms,
notifications, and status labels. The globe button changes language without
signing out. Arabic uses right-to-left layout.

Display translations live in `lib/core/localization/translation_catalog.dart`.
Use `LocalizedText` for catalog-backed UI labels and `context.localize` for
tooltips, input decorations, and validation errors. `context.tr` also uses the
catalog for Arabic when an inline Arabic translation is not supplied. Keep
user-authored names in ordinary `Text` widgets and keep database status codes
unchanged; translate their display labels only. Tests verify Arabic coverage,
language switching after sign-in, RTL layout, and translated forms and menus.

---

## Repository Structure

### Driver governorates and Back navigation

Driver setup includes all 24 Tunisian governorates. Drivers can select one,
several, or all governorates; selecting none prevents continuing. Governorate
names appear in French/English and Arabic, while stable ISO 3166-2 suffixes are
stored in `driver_service_zones`. SQLite migrations preserve existing databases
without clearing accounts or missions. Vehicle capacity is now persisted too.
The governorate list is based on Tunisia's [INS administrative classification](https://www.ins.tn/publication/classification-nationale-des-unites-administratives).

Existing drivers can open **My profile → Edit delivery profile** to update
their vehicle, capacity, and governorates. Signing in after an interrupted new
driver setup resumes onboarding if no driver profile has been saved. Account
email identifies the driver, rather than a partial name match.

Admin, resident, and driver headers include a Back button alongside the menu.
Back retraces previously visited sections. At the dashboard, it asks before
signing out. Android Back uses the same behavior and closes an open drawer first.
During onboarding, Back returns to the previous step and keeps selections;
leaving the initial setup asks before signing out. Editing an existing profile
can return directly to that profile. The laundry and order home screens also
include an explicit Back button.

Selected governorates are coverage preferences at this stage. Missions do not
yet store destination governorates or delivery deadlines, so geographic
assignment restrictions and late-delivery consequences are not active.
The agreed future lateness policy is: the first administrator-confirmed,
driver-responsible late delivery produces a warning; subsequent confirmed
delays reduce the rating. Before enabling it, add promised delivery deadlines,
actual arrival timestamps, an incident audit trail, administrator review, and
exception handling for locker faults, customer delays, and service outages.
The rating reduction amount and repeated-delay time window remain to be defined.

### AI-assisted vehicle capacity evidence

Driver setup step 1 accepts camera or gallery photos of a load plate or
manufacturer specification, plus brand, model/variant, year and occupants/equipment
weight. `google_mlkit_text_recognition` 0.14.0 performs on-device Latin-script OCR;
the Android model is bundled. This is pretrained AI text recognition followed
by deterministic capacity checks, not vehicle recognition or an AI agent.
Interface localization remains the normal offline French/English/Arabic feature.

The parser accepts explicit `Payload`, `Maximum payload`, `Charge utile` or
`Cargo capacity` labels with kg units. Bare numbers, gross mass, axle limits,
unsupported units and conflicting payloads require review. It deliberately does
not estimate payload from a vehicle exterior photo or subtract arbitrary plate
weights. Arabic-only documents need manual review. No web lookup is implemented.

Comparison uses **declared laundry load + occupants/equipment <= documented
payload**. A detected excess blocks continuing and is also rejected by the
repository. Missing/ambiguous evidence may be saved for administrator review.
Even a consistent result does not prove vehicle identity, document authenticity,
or safe physical loading. A checkbox is a driver declaration, not an AI identity check.

SQLite version 6 stores the latest evidence in `vehicle_capacity_checks`, a
capacity assessment on `delivery_drivers`, and administrator decisions in
`vehicle_capacity_review_events`. Photos are copied from temporary picker storage
into private application support storage. Full OCR text is not retained. Photos
are local, not uploaded or shared between phones; there is no backend yet.
Replacing/saving a profile requests a new review. Previously retained photos are
not automatically deleted because review events may refer to them; a retention
policy is still needed before production use.

Admin → Driver management → Review evidence displays the image and metadata.
The administrator confirms vehicle identity and enters checked payload/reserve
values, then approves or rejects. Approval is disabled until the image loads,
and invalid weight comparisons or changed evidence snapshots are rejected.
Decisions and reviewer names are recorded locally. Mission assignment now requires
approval in both the UI and SQLite transaction. Pending, rejected and newly
resubmitted profiles cannot receive new missions. Dispatch conservatively reserves
the weight of every unfinished assigned mission; completed missions release it.
Reassigning the same mission does not reserve its weight twice. Existing missions
remain accessible so in-progress work can be completed.

The review screen offers offline AI document re-analysis with extracted text,
labelled payload, available laundry load and an explained recommendation. ML Kit
performs the learned text recognition; numerical checks are deterministic rules.
No confidence percentage, vehicle identification or authenticity claim is invented.
Unclear or conflicting payload readings require manual review. The fleet/operations
reviewer still checks identity and authenticity before final approval. This local
prototype has no backend authorization or cross-device synchronization.

Test steps:

1. Fully stop/relaunch the Android app after installing the native OCR plugin.
2. Enter vehicle details and occupants/equipment weight during setup.
3. Photograph or select a readable document with `Charge utile: 750 kg`.
4. With a 100 kg reserve, a 500 kg laundry capacity is consistent; 700 kg exceeds it.
5. Try a document with only `PTAC 3500 kg`; it should require manual review.
6. Finish setup, sign in as administrator and inspect/review the submitted evidence.

The generated image in `integration_test/vehicle_ocr_test.dart` is marked
**NOT A VEHICLE CERTIFICATE** and is solely an OCR test fixture. Unit tests cover
parsing, comparison, image retention after cache deletion, review validation,
auditing, and preservation of existing profiles through migration. iOS requires
15.5 and camera/photo-library permission descriptions; iOS builds need macOS and
have not been verified here.

Validation: 26 unit/widget tests passed. The native OCR integration test passed
on emulator-5554 with airplane mode enabled and Wi-Fi disabled, extracting
750 kg from the upright synthetic fixture. This does not validate authenticity
or performance on real photographed documents. The original emulator network
settings were restored afterward. Run the native test with
`flutter test integration_test/vehicle_ocr_test.dart -d emulator-5554`.

```text
.
├── assets/
│   └── logo.png
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── core/
│   │   ├── localization/
│   │   │   └── app_locale.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── database/
│   │   └── database.dart
│   ├── models/
│   │   ├── delivery_driver.dart
│   │   ├── delivery_order.dart
│   │   └── user.dart
│   └── features/
│       ├── auth/
│       │   └── presentation/
│       │       ├── auth_page.dart
│       │       ├── auth_screen.dart
│       │       ├── pages/
│       │       │   ├── forgot_password_page.dart
│       │       │   ├── sign_in_page.dart
│       │       │   └── sign_up_page.dart
│       │       └── widgets/
│       │           ├── auth_buttons.dart
│       │           ├── auth_divider.dart
│       │           ├── auth_footer.dart
│       │           ├── auth_heading.dart
│       │           ├── auth_illustration.dart
│       │           ├── auth_text_field.dart
│       │           └── brand_mark.dart
│       ├── casiers/
│       │   └── presentation/
│       │       ├── admin/
│       │       │   └── admin_interface.dart
│       │       ├── navigation/
│       │       │   ├── admin_navigation_bar.dart
│       │       │   └── resident_navigation_bar.dart
│       │       ├── resident/
│       │       │   └── resident_interface.dart
│       │       └── widgets/
│       │           └── casier_components.dart
│       ├── delivery_drivers/
│       │   └── presentation/
│       │       ├── admin_driver_management.dart
│       │       ├── driver_interface.dart
│       │       ├── navigation/
│       │       │   └── driver_navigation_bar.dart
│       │       └── widgets/
│       │           └── driver_components.dart
│       ├── lockers/
│       │   └── presentation/
│       │       └── home_page.dart
│       └── orders/
│           └── presentation/
│               └── home_page.dart
├── test/
│   ├── casier_interfaces_test.dart
│   └── widget_test.dart
├── pubspec.yaml
└── README.md
```

Platform-specific build and native configuration lives in `android/` and
`ios/`. Flutter dependencies and asset declarations are in `pubspec.yaml`.

---

## Application Entry Points

| File | Responsibility |
| --- | --- |
| `lib/main.dart` | Starts the Flutter application. |
| `lib/app.dart` | Configures `MaterialApp`, the ResiDry title, theme, and initial route. |
| `lib/core/theme/app_theme.dart` | Shared brand colors and light theme. |
| `lib/features/auth/presentation/auth_screen.dart` | Owns sign-in/sign-up state and routes users to their role's home screen. |

---

## Feature and Folder Guide

### Authentication — `lib/features/auth/`

`presentation/auth_screen.dart` coordinates the sign-in, sign-up, and password
reset flows. Individual screens are in `presentation/pages/`; shared controls
and visual elements are in `presentation/widgets/`.

The authentication flow looks up and creates users through
`lib/database/database.dart`, using the `User` model in `lib/models/user.dart`.
Role-based routing to the casier screens is handled by `auth_screen.dart`.

### Smart lockers — `lib/features/casiers/`

This feature contains separate user experiences:

| Folder/file | Responsibility |
| --- | --- |
| `presentation/admin/admin_interface.dart` | Administrator dashboard, locker list, search and filters, locker form, details, alerts, maintenance, and profile screens. |
| `presentation/resident/resident_interface.dart` | Resident home, assigned-locker controls, activity history, notifications, and profile screens. |
| `presentation/navigation/admin_navigation_bar.dart` | Collapsible administrator side drawer and its page destinations. Despite the legacy filename, this is a side menu, not a bottom navigation bar. |
| `presentation/navigation/resident_navigation_bar.dart` | Collapsible resident side drawer and its page destinations. |
| `presentation/widgets/casier_components.dart` | Shared sample locker records and reusable status, metric, detail, heading, and trend widgets. |

The side menu opens from the menu button in the app bar. Selecting a destination
switches to that role's corresponding page and closes the drawer.

### Delivery drivers — `lib/features/delivery_drivers/`

| Folder/file | Responsibility |
| --- | --- |
| `presentation/driver_interface.dart` | Delivery driver dashboard, active/past missions list, IoT locker unlocking, notifications, and driver profile screens. |
| `presentation/admin_driver_management.dart` | Administrator view for monitoring delivery driver fleet and assigning orders to drivers. |
| `presentation/navigation/driver_navigation_bar.dart` | Collapsible delivery driver side drawer and page destinations. |
| `presentation/widgets/driver_components.dart` | Reusable delivery order cards, status pills, and driver metrics widgets. |

The delivery feature also contains:

| Folder/file | Responsibility |
| --- | --- |
| `domain/delivery_status.dart` | Stable mission states and allowed state transitions. |
| `data/delivery_repository.dart` | Storage contract used by delivery screens. |
| `data/sqlite_delivery_repository.dart` | Transactional SQLite implementation for queries, assignment, status changes, and audit events. |

SQLite schema version 4 introduces `delivery_drivers`, `delivery_missions`, and
`delivery_events`. The repository boundary allows the local implementation to
be replaced by a REST-backed implementation when the team backend is ready.

### Other feature placeholders

| Folder/file | Current responsibility |
| --- | --- |
| `lib/features/lockers/presentation/home_page.dart` | Generic locker landing-page placeholder for roles without a dedicated screen. |
| `lib/features/orders/presentation/home_page.dart` | Legacy delivery/order landing page placeholder. |

Other modules listed in the team plan (laundry, laundry companies, and residents)
have not yet been added to the current `lib/features/` tree.

---

## Data and Prototype Boundaries

- User accounts, delivery drivers, missions, and mission audit events are stored
  locally through SQLite.
- Casier screens currently display sample data defined in
  `presentation/widgets/casier_components.dart`.
- Administrator edits and deletes affect in-memory sample records only; they
  are not persisted between app launches.
- Resident actions simulate locking and unlocking the assigned sample locker.
- IoT status, sensor values, charts, alerts, and anomaly confidence are
  illustrative UI data, not readings from connected hardware or an AI service.
- Delivery seed records are demonstration data. Assignment and status changes
  are persisted and validated, but order, locker, and company modules are not
  connected to these missions yet.
- The resident interface displays only its assigned locker in the current UI;
  production access control must also be enforced by the backend and data layer.

---

## Tests

`test/widget_test.dart` covers navigation among sign-in, password reset, and
sign-up screens.

`test/casier_interfaces_test.dart` covers administrator and resident side-menu
navigation, opening and closing the drawer, locker management access, and the
resident locker controls.

---

## Team & Planned Modules

| Member | Responsibility | Planned module |
| --- | --- | --- |
| Mohamed Khalil Marzouki | Locker management | `casiers` / `lockers` |
| Ben Dziri Sabaa | Intelligent laundry management | `laundry` |
| Achwek Ourari | Laundry company management | `laundry_companies` |
| Aymen Abdellatif | Delivery driver management | `delivery_drivers` |
| Mohamed Raed Boukari | Resident management | `residents` |
| Saber Ben Amira | Order management | `orders` |

---

## Git Workflow

Do not push directly to `main`. Develop changes on a feature branch and integrate
them through a pull request.

### Branch naming

```text
feature/<module>
```

Examples:

```text
feature/casiers
feature/laundry
feature/laundry-companies
feature/delivery-drivers
feature/residents
feature/orders
```

### Typical workflow

```bash
git checkout main
git pull origin main
git checkout -b feature/casiers

# Make and test your changes.
flutter analyze
flutter test

git add .
git commit -m "feat(casiers): implement locker management"
git push -u origin feature/casiers
```

Open a pull request from the feature branch to `main`. Describe the changes,
tests, dependencies, and any remaining work. Review and test changes before
merging.

### Collaboration guidelines

- Keep pull requests focused and commits descriptive.
- Pull the latest `main` regularly.
- Coordinate before changing another member's feature.
- Never commit API keys, passwords, or private credentials.

---

## Technologies

- Flutter and Dart
- SQLite for local user data
- IoT and AI concepts represented in the locker UI prototype
- Git and GitHub

---

## Objective

ResiDry aims to connect residents, smart lockers, delivery, and laundry
companies in a convenient residential laundry service:

```text
Residents
    ↓
Smart Lockers
    ↓
Delivery
    ↓
Laundry Companies
    ↓
Delivery
    ↓
Residents
```

> Develop independently. Review collaboratively. Integrate safely.


### Updated registration onboarding (October 12)

The first page now collects vehicle type and declared laundry capacity only.
The second requires both sides of the Tunisian registration certificate and an
online vision check. Continue stays disabled for missing, rejected, uncertain or
unavailable results. See [server setup](server/README.md) for configuration,
limitations and test instructions. No live AI verification is available until
the server, HTTPS endpoint and API credentials are configured.
SQLite version 7 preserves the back photo and verification summary, with a
non-destructive upgrade from version 6. Earlier one-photo evidence does not unlock
the new online verification gate. Older AI/OCR workflow notes above describe the
previous onboarding version; offline OCR remains only a reviewer tool.


### Shared driver applications backend

The new `backend/` module provides Spring Boot accounts, authenticated sessions,
private application documents, review statuses and decision events. See
[backend setup](backend/README.md). Build Flutter with `RESIDRY_API_URL` to use it.
Without this flag, the existing SQLite demo remains; demo accounts are not
automatically migrated to server accounts. Backend-mode drivers can submit a
complete dossier before AI analysis finishes. AI outages leave it pending.
Administrator approval and a decision reason are required; correction requests
and resubmissions preserve the application identity and update its revision.
PostgreSQL configuration is included, while automated checks use H2. Shared
mission dispatch, SMS verification, licence/insurance checks and Tunisia-specific
legal/data-retention validation remain separate follow-up stages.
