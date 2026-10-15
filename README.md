# ResiDry — Resident Management

ResiDry is a Flutter mobile application for managing laundry services and smart
lockers in residential buildings. This branch focuses on the **resident
management module**, developed for the ResiDry project.

The module provides separate experiences for residents and administrators. A
resident can manage their own profile and residence information, while an
administrator can manage the residents registered in the building.

## Project information

| Item | Details |
| --- | --- |
| Project | ResiDry |
| Class | 4IET_I4 |
| Team | Ethivon |
| Platform | Flutter mobile application |
| Language | Dart |
| Local database | SQLite |
| Feature owner | Mohamed Raed Boukari |

## Getting started

From the repository root, install the dependencies and run the application:

```bash
flutter pub get
flutter run
```

To run the project on a connected Android phone:

```bash
flutter devices
flutter run -d <device-id>
```

Run the project checks with:

```bash
flutter analyze
flutter test
```

## Resident management scope

### Resident features

- Create and authenticate a resident account.
- Load the resident profile using the authenticated email address.
- Edit personal information such as name, email, phone number and apartment.
- Detect the nearby residence using the phone GPS.
- Save the detected residence and profile changes locally in SQLite.
- View residence information, laundry requests, notifications and locker assignment.
- Navigate through a resident dashboard and mobile-friendly profile screens.

### Administrator features

The administrator side includes a **Resident Management** page where an
administrator can:

- view the residents stored locally;
- search by name, email or apartment;
- add a resident;
- edit a resident;
- delete a resident after confirmation;
- refresh the resident list.

Resident management is accessible from the administrator side menu and is kept
separate from the resident's personal profile area.

## GPS residence detection

When a resident edits their profile, ResiDry can request location permission and
detect the closest configured residence. The application compares the phone's
GPS position with the configured latitude, longitude and detection radius.

The GPS flow is deliberately performed in the resident profile form, not during
account creation:

1. The resident creates an account.
2. The resident opens **Profile** and selects **Edit Profile**.
3. The application requests location permission.
4. A nearby residence is detected within its configured radius.
5. The resident saves the profile and the residence is stored in SQLite.

The configured residence data is stored in:

```text
lib/features/residents/data/residence_data.dart
```

The GPS logic is implemented in:

```text
lib/features/residents/data/residence_locator.dart
```

The current coordinates were supplied for the project prototype and are marked
as unverified. The detection radius is currently 300 meters per residence and
should be validated before production use.

The `geolocator` package is used for location access. Android and iOS location
permissions are configured in:

```text
android/app/src/main/AndroidManifest.xml
ios/Runner/Info.plist
```

## Repository structure

```text
lib/
├── app.dart
├── main.dart
├── core/
│   └── theme/app_theme.dart
├── database/
│   └── database.dart
├── models/
│   └── user.dart
└── features/
    ├── auth/
    │   └── presentation/
    ├── residents/
    │   ├── data/
    │   │   ├── residence_data.dart
    │   │   └── residence_locator.dart
    │   ├── mock/
    │   │   └── residents_mock_data.dart
    │   └── presentation/
    │       ├── pages/
    │       │   ├── edit_profile_page.dart
    │       │   ├── resident_management_page.dart
    │       │   ├── resident_profile_page.dart
    │       │   └── ...
    │       ├── residents_home_page.dart
    │       └── widgets/
    ├── casiers/
    ├── laundry/
    ├── laundry_companies/
    ├── delivery_drivers/
    └── orders/
```

## Important files

| File | Responsibility |
| --- | --- |
| `lib/features/auth/presentation/auth_screen.dart` | Sign-in, sign-up and role-based navigation. |
| `lib/features/residents/presentation/residents_home_page.dart` | Resident dashboard and resident navigation. |
| `lib/features/residents/presentation/pages/edit_profile_page.dart` | Resident profile form and GPS residence detection. |
| `lib/features/residents/presentation/pages/resident_management_page.dart` | Administrator resident CRUD interface. |
| `lib/features/residents/mock/residents_mock_data.dart` | Resident, request and notification models used by the prototype. |
| `lib/features/residents/data/residence_data.dart` | Configured residence coordinates and geofencing radii. |
| `lib/features/residents/data/residence_locator.dart` | GPS permission and nearest-residence detection. |
| `lib/database/database.dart` | SQLite schema and resident CRUD operations. |

## Local data and prototype boundaries

The following data is currently stored locally or represented with prototype
data:

- user accounts and resident profiles are stored in SQLite;
- resident profile creation, update and deletion are persisted locally;
- laundry requests are currently demonstration data;
- notifications are currently kept in memory;
- locker assignment and IoT readings are demonstration data;
- live backend synchronization is not connected yet;
- GPS coordinates must be verified before real production deployment.

The laundry, locker, order and delivery modules are being developed by other
team members. Their final data contracts will be integrated later using stable
identifiers such as:

```text
resident_id
residence_id
locker_id
laundry_request_id
order_id
```

## Testing

The project currently includes tests for:

- authentication screen navigation;
- resident CRUD persistence;
- resident and administrator navigation;
- administrator resident-management access;
- compact mobile layouts;
- locker interfaces;
- administrator order navigation.

Run all tests with:

```bash
flutter test
```

## Team modules

| Team member | Responsibility | Module |
| --- | --- | --- |
| Mohamed Khalil Marzouki | Locker management | `casiers` / `lockers` |
| Ben Dziri Sabaa | Intelligent laundry management | `laundry` |
| Achwek Ourari | Laundry company management | `laundry_companies` |
| Aymen Abdellatif | Delivery driver management | `delivery_drivers` |
| Mohamed Raed Boukari | Resident management | `residents` |
| Saber Ben Amira | Order management | `orders` |

## Git workflow

Work on the resident feature branch and open a pull request instead of pushing
directly to `main`:

```bash
git checkout feature/residents
flutter analyze
flutter test
git add .
git commit -m "feat(residents): improve resident management"
git push -u origin feature/residents
```

Keep commits focused, coordinate shared data contracts with the other module
owners, and never commit passwords, API keys or private credentials.

## Future improvements

- Replace prototype laundry requests and notifications with persistent data.
- Connect resident profiles to a backend API.
- Verify all residence GPS coordinates and detection radii.
- Add stronger role-based access control on the backend.
- Store passwords securely through a real authentication service.
