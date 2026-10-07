# ResiDry

### Smart Laundry Service for Residential Buildings

ResiDry is a Flutter mobile application concept for managing laundry services and
smart lockers in residential buildings. It brings residents, administrators,
delivery, and laundry operations into one mobile experience.

The current application includes authentication screens and role-specific
administrator and resident smart-locker interfaces. Locker readings and
management actions in those interfaces currently use demonstration data; live
IoT devices, a remote service, and persistent locker management are not
connected yet.

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

---

## Repository Structure

```text
.
├── assets/
│   └── logo.png
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── core/
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

### Other feature placeholders

| Folder/file | Current responsibility |
| --- | --- |
| `lib/features/lockers/presentation/home_page.dart` | Generic locker landing-page placeholder for roles without a dedicated screen. |
| `lib/features/orders/presentation/home_page.dart` | Legacy delivery/order landing page placeholder. |

Other modules listed in the team plan (laundry, laundry companies, and residents)
have not yet been added to the current `lib/features/` tree.

---

## Data and Prototype Boundaries

- User accounts are stored locally through SQLite.
- Casier screens currently display sample data defined in
  `presentation/widgets/casier_components.dart`.
- Administrator edits and deletes affect in-memory sample records only; they
  are not persisted between app launches.
- Resident actions simulate locking and unlocking the assigned sample locker.
- IoT status, sensor values, charts, alerts, and anomaly confidence are
  illustrative UI data, not readings from connected hardware or an AI service.
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
