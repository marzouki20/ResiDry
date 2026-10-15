# ResiDry driver applications backend

Spring Boot 3.5.16 / Java 17. This first backend module centralizes account
authentication and independent-driver applications. Flutter uses it when built
with `RESIDRY_API_URL`. Without that setting the existing local demo remains.
Existing SQLite users and missions are not automatically migrated to the server.

## Run locally on Windows

```powershell
cd "C:\PI MOBILE\ResiDry\backend"
.\start-local.ps1
```

Enter an administrator email and a new password of at least 12 characters locally.
The account is provisioned once; restarting does not change its password. Public
signup cannot create administrators. Do not share the password or commit it.
The script discovers the installed JDK used during verification, builds the JAR
and runs on `127.0.0.1:8766`. Keep this terminal open. Override a blocked port:

```powershell
.\start-local.ps1 -Port 18766
```

Check with `Invoke-RestMethod http://127.0.0.1:8766/api/health`.
The local profile uses persistent H2 at `backend/data/` so no database installation
is needed for coursework. Do not delete it if you want to retain test accounts.
Passwords use BCrypt; session tokens are random, stored as hashes on the server,
expire after eight hours and are revoked on sign-out. Flutter keeps the token in
memory and requires login again after restart.

## Connect your Android phone

Keep the server open. In another terminal run:

```powershell
cloudflared tunnel --url http://127.0.0.1:8766
```

Use the **new** HTTPS tunnel address, not the earlier Python service tunnel:

```powershell
flutter run -d YOUR_DEVICE_ID --dart-define=RESIDRY_API_URL=https://YOUR-NEW-TUNNEL.trycloudflare.com
```

No OpenAI key or development token is put in this Flutter command. The app obtains
its account session from the Spring backend. Local SQLite demo accounts will not
work here; create a new driver and log in as the provisioned administrator.
The URL changes whenever you restart a quick tunnel.

## Workflow

`DRAFT → SUBMITTED → UNDER_REVIEW → APPROVED / CORRECTION_REQUESTED / REJECTED`.
Correction/resubmission retains the application ID, increments its revision and
records events. Updating an approved application resets eligibility for review.
Submission requires zones, capacity, reserve weight and consent. Motorized
vehicles need two JPEG/PNG certificate photographs (maximum 5 MB each); the
bicycle path is manually reviewed without a registration certificate.
Documents are accessible only to their owner or an authenticated administrator.
They are stored inside the database and are not served as public file URLs.
Administrator approval checks confirmed available payload, identity confirmation
and a mandatory decision reason. Reviewer corrections are recorded in events.
Optimistic revisions prevent approving a stale dossier.

AI runs after submission and does not decide application acceptance. If it is
unavailable the submission remains reviewable. An administrator may review
manually. Shared mission dispatch is a subsequent module; server-mode drivers
currently see their application status rather than local demo missions.

## Optional AI bridge

The existing Python service remains the vision adapter. Set these values in the
Spring server terminal before starting it:

```powershell
$env:RESIDRY_AI_URL = 'http://127.0.0.1:8765/verify-registration'
```

`REGISTRATION_DEV_TOKEN` must match the Python process. Only that Python process
needs `OPENAI_API_KEY` and `OPENAI_VISION_MODEL`. No real AI calls were made during
automated validation. The Python update extracts raw weight values/units and
normalizes tonnes to kilograms deterministically: 0.410 t becomes 410 kg.
AI is an assistant to document review, not proof of authenticity or legal
eligibility. In-progress AI jobs are best-effort in this first version; a durable
job queue and retry scheduling remain future work.

## PostgreSQL

With Docker installed, set `RESIDRY_DB_PASSWORD` locally and run:

```powershell
docker compose up -d
$env:SPRING_PROFILES_ACTIVE = 'postgres'
$env:RESIDRY_DB_USER = 'residry'
$env:RESIDRY_DB_URL = 'jdbc:postgresql://127.0.0.1:5432/residry'
.\start-local.ps1
```

Flyway migrations create `accounts`, `auth_sessions`, `driver_applications`,
`application_documents` and `application_events`. PostgreSQL is configured but
not live-tested in this environment; integration tests use H2 PostgreSQL mode.
Use a permanent authenticated HTTPS deployment for real operation.

## Checks and remaining work

```powershell
.\mvnw.cmd test
```

Integration tests cover registration, login, hashed passwords, logout, role
restrictions, submission, correction/resubmission, approval, overload, stale
revision and invalid documents/zones/phone numbers. Flutter has a separate
backend-mode test and its original local-mode regression suite.

This is a coursework foundation, not a legally certified production service.
Before real enrollment: verify Tunisian independent-work/transport/insurance
requirements, define identity/licence/insurance evidence per vehicle category,
integrate SMS verification, implement retention/deletion, encryption at rest,
backups and abuse/rate limits, review overseas AI data processing, evaluate vision
accuracy on actual certificate layouts and connect server-side mission dispatch.
Do not collect real identity documents until those requirements are resolved.


## Strict document verification (current policy)

Motorized drivers must supply Tunisian registration front/back, driving licence
front/back and insurance proof showing delivery coverage. Borrowed/company
vehicles also require owner authorization identifying the vehicle and driver.
The account name must match the licence. Uncertain spelling/transliteration needs
correction rather than a guessed identity match. Every image is independently
classified, checked for readability and expected side; duplicate images are blocked.

`POST /api/driver/application/verify-documents` calls the private Python vision
adapter. Structured observations feed deterministic rules: document pairing,
vehicle type, licence category/expiry, insurance dates/plate/VIN/coverage, owner
permission and payload. Printed tonnes are converted to kilograms. Declared load
plus occupants/equipment must not exceed documented payload. The model never
searches for an estimated capacity or claims government authenticity.

Successful checks produce an account-bound, 30-minute server receipt bound to
exact photos, vehicle, capacity, reserve and ownership declaration. Final submit
requires this receipt. Editing any of those inputs requires another scan. Failure,
uncertainty, incomplete model output and outages block submission. Draft saving
remains available. This replaces the earlier nonblocking motorized submission
policy. Older dossiers must be rescanned before approval; data is preserved.
Administrator approval is still mandatory and cannot bypass missing verification.
Bicycles retain manual review and do not require motor-vehicle documents.

### Local AI startup
Stop an existing backend first, then run `./start-with-ai.ps1`. Enter a NEW API key
at the hidden prompt; never commit or put it in Flutter. This starts the private
Python adapter and backend with a shared random token. Keep this terminal open.
The USB phone can use `adb reverse tcp:8766 tcp:8766` and the app built with
`RESIDRY_API_URL=http://127.0.0.1:8766`. External AI calls require internet and may
incur API charges. No paid calls are made by automated tests.

### Limits before production
These are conservative application checks, not a guarantee of legal eligibility
or authentic documents. Category B/C and motorcycle A checks are conservative;
unclear categories require correction/review rather than inferred equivalence.
A Tunisian legal/insurance review must validate the policy, delivery permissions,
processor/data-protection requirements and document-retention period. Deployment
also needs authenticated HTTPS, access/rate limits, encrypted document storage
and secure operations. Model outputs can be wrong: test a representative consented
Tunisian document set and measure false acceptance/rejection before production.
