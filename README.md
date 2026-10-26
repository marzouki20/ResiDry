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

Email/password and Google authentication are handled by Supabase Auth through
`lib/database/supabase_connection.dart`; the display name and application role
are stored as Supabase user metadata. Signup email verification and password
recovery use six-digit codes. hCaptcha tokens are collected in a WebView and
sent with Supabase Auth requests. **Remember me** controls persistent Supabase
session storage; without it, the session lasts until the app is closed. Google
identity tokens are obtained with `google_sign_in` and verified by Supabase.

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

### Other feature placeholders

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
