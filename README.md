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

<!-- Content retained from dev-2 -->
To run the project on a connected Android phone:

```bash
flutter devices
flutter run -d <device-id>
```

Run the project checks with:
<!-- Content retained from dev -->
For your first local run, copy the example config and fill in `.env`:

```powershell
Copy-Item .env.example .env
```

Open the root `.env` file and replace the example values. The local `.env`
already contains this project's Supabase URL and publishable key; enter the
hCaptcha **site key** and Google web OAuth client ID if you use those features.

`.env` is ignored by Git and bundled into the app. It is for public client-side
configuration only; anything included in a Flutter app can be extracted.

Run the relevant checks:
<!-- End combined content -->

```bash
flutter analyze
flutter test
```

## Resident management scope

<!-- Content retained from dev-2 -->
### Resident features

- Create and authenticate a resident account.
- Load the resident profile using the authenticated email address.
- Edit personal information such as name, email, phone number and apartment.
- Detect the nearby residence using the phone GPS.
- Save the detected residence and profile changes locally in SQLite.
- View residence information, laundry requests, notifications and locker assignment.
- Navigate through a resident dashboard and mobile-friendly profile screens.
<!-- Content retained from dev -->
| Role | Destination |
| --- | --- |
| Résident | Resident smart-locker interface |
| Administrateur | Administrator smart-locker interface |
| Livreur | Delivery/order interface |
| Société de lavage | Laundry-company interface |

Email/password and Google sign-in use Supabase Auth. Email signup sends a
verification code; users must enter it before the app signs them in. Password
recovery also uses an email code. The app checks email syntax, while successful
code verification proves the user can receive mail at that address. The
**Remember me** option controls whether the Supabase session survives an app
restart. hCaptcha protects signup, password sign-in, Google sign-in, email
verification, resend, and password recovery.

### Supabase email and hCaptcha setup

1. In **Supabase → Authentication → Sign In / Providers → Email**, enable
   **Confirm email**.
2. In **Supabase → Authentication → Email Templates**, update both **Confirm
   signup** and **Reset password** templates to include the six-digit code:

   ```html
   <p>Your ResiDry verification code is: <strong>{{ .Token }}</strong></p>
   ```

   Keep the code private and do not include the Supabase secret key in an email
   or the app.
3. Configure a custom SMTP provider in Supabase **Authentication → SMTP
   Settings** for reliable delivery and higher sending limits. Supabase's
   built-in mail service is rate-limited and intended for testing.
4. Create an hCaptcha site and copy its **site key**. Add the hostname passed
   as `HCAPTCHA_DOMAIN` to that hCaptcha site's allowed domains. The default
   is `localhost` for development; use a hostname you control for production.
5. In **Supabase → Authentication → Bot and Abuse Protection**, enable CAPTCHA,
   select **hCaptcha**, and enter the hCaptcha **secret key**. The secret stays
   in Supabase and must never be included in the Flutter app.
6. Put the hCaptcha site key and allowed hostname in the local `.env` file.
   The site key is public; do not put the hCaptcha secret or SMTP credentials
   in `.env`.
7. Copy the Supabase project URL and publishable key into `.env`. These are
   client-side public values. Never put a Supabase `service_role` or secret key
   in the app.

Google sign-in additionally requires an OAuth web client ID, Android OAuth
client registration, and Google as an enabled provider in the Supabase project.

### Google Sign-In setup (Android)

1. In Google Cloud Console, create an Android OAuth client for package
   `com.example.ttttttteee`, using the SHA-1 certificate fingerprint for your
   build. For the local debug fingerprint, run `.\gradlew signingReport` from
   the `android` directory.
2. Create a separate OAuth client of type **Web application** and copy its
   client ID.
3. Run the app with that web client ID:

   ```powershell
   flutter run -d RFCX10K0JVM
   ```

The web client ID is not a secret, but do not put private keys or client
secrets in the app. Add the matching Android OAuth client for each signing
certificate/build variant. If the Android package name changes, update the
OAuth registration too.
<!-- End combined content -->

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
<!-- Content retained from dev-2 -->
lib/features/residents/data/residence_data.dart
<!-- Content retained from dev -->
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
│   │   └── user.dart
│   └── features/
│       ├── auth/
│       │   ├── data/
│       │   │   ├── auth_session_store.dart
│       │   │   └── google_auth_service.dart
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
│       ├── laundry_companies/
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
<!-- End combined content -->
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

<!-- Content retained from dev-2 -->
```text
resident_id
residence_id
locker_id
laundry_request_id
order_id
```
<!-- Content retained from dev -->
Email/password and Google authentication are handled by Supabase Auth through
`lib/database/supabase_connection.dart`; the display name and application role
are stored as Supabase user metadata. Signup email verification and password
recovery use six-digit codes. hCaptcha tokens are collected in a WebView and
sent with Supabase Auth requests. **Remember me** controls persistent Supabase
session storage; without it, the session lasts until the app is closed. Google
identity tokens are obtained with `google_sign_in` and verified by Supabase.
<!-- End combined content -->

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

<!-- Content retained from dev-2 -->
## Team modules

| Team member | Responsibility | Module |
<!-- Content retained from dev -->
| Folder/file | Current responsibility |
| --- | --- |
| `lib/features/laundry_companies/presentation/home_page.dart` | Laundry-company landing page. |
| `lib/features/orders/presentation/home_page.dart` | Delivery/order landing page used for the `Livreur` role. |

Both placeholder pages and the administrator/resident casier interfaces
currently use demonstration data.

---

## Data and Prototype Boundaries

- User accounts are managed by Supabase Auth; the app does not store account
  passwords in a local database.
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
<!-- End combined content -->
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

<!-- Content retained from dev-2 -->
- Replace prototype laundry requests and notifications with persistent data.
- Connect resident profiles to a backend API.
- Verify all residence GPS coordinates and detection radii.
- Add stronger role-based access control on the backend.
- Store passwords securely through a real authentication service.
<!-- Content retained from dev -->
- Keep pull requests focused and commits descriptive.
- Pull the latest `main` regularly.
- Coordinate before changing another member's feature.
- Never commit API keys, passwords, or private credentials.

---

## Technologies

- Flutter and Dart
- Supabase Auth for account authentication
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
<!-- End combined content -->
