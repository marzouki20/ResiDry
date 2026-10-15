t# ResiDry self-hosted vision

Status: integration and deployment configuration prepared. No public server has
been provisioned. Real vision accuracy, container runtime, latency and hosted
PostgreSQL deployment have not been validated on a target server.

## Free local model

Install Ollama from its official Windows installer. Download the vision model:
`ollama pull gemma3:4b` (several GB). Keep Ollama running. Stop the previous
ResiDry services, then run `backend/start-with-local-ai.ps1`. No paid API key is
used and there is no automatic fallback to OpenAI. Existing strict document
checks and server verification receipts remain mandatory.

This is not on-device AI: the computer/server does the work. Its hardware and
operating costs still exist. Benchmark clear French/Arabic Tunisian documents
before relying on the model. Slow inference exceeding the existing 110-second
backend deadline is blocked; do not weaken validation to get a passing demo.

## Independent public server

Required: a Linux server with sufficient RAM/compute, Docker Compose, persistent
storage, a domain pointing to it and inbound TCP 80/443. Free hosting availability
and resources must be confirmed with the chosen provider. This project does not
create an account, charge a card, or promise permanent free hosting.

On the server, create a private environment file outside Git with:
RESIDRY_DOMAIN, RESIDRY_DB_PASSWORD, RESIDRY_ADMIN_EMAIL,
RESIDRY_ADMIN_PASSWORD (12+ characters), REGISTRATION_DEV_TOKEN (random secret).
Optional OLLAMA_VISION_MODEL defaults to gemma3:4b. Protect the file permissions.

From the project root:
```
docker compose --env-file /private/residry.env -f compose.hosted.yaml up -d --build
docker compose --env-file /private/residry.env -f compose.hosted.yaml exec ollama ollama pull gemma3:4b
```
Build the Android app with its final public URL:
```
flutter build apk --dart-define=RESIDRY_API_URL=https://YOUR_DOMAIN
```

Only the HTTPS reverse proxy publishes ports. PostgreSQL, vision adapter and
Ollama have no published ports. Caddy obtains HTTPS certificates after DNS and
network access are correct. Accounts/photos persist in PostgreSQL volumes and
models persist separately. Existing local H2 accounts are NOT migrated by these
commands: plan an explicit backed-up migration before moving user data.

Before real public use: pin tested container image digests, verify HTTPS,
authentication and service isolation, set up encrypted backups and document
retention/deletion, add operator rate limiting and test recovery. Never publish
Ollama or the private vision adapter directly. No production deployment has been
performed. The hosted app currently includes account/application workflows; the
existing local mission module has not become shared server dispatch.

## Private visual references
The local classifier uses the user-provided examples in server/document_references. This directory is excluded from Git and Docker build contexts. On a future hosted server, mount the authorized private reference directory read-only at /app/document_references in the vision container. Do not publish source photos or assume examples are valid driver documents. No insurance or vehicle-use authorization example has been supplied. Technical inspection layout is recognized as a distinct document, but its onboarding field is not implemented.


## Technical-inspection document
Motorized onboarding now includes TECHNICAL_INSPECTION, stored as a supporting document and restored when editing drafts. Policy tn-driver-documents-v2 checks Tunisian type, issue/expiry dates, registration, chassis when visible, and inspection centre. New submissions require a fresh v2 verification receipt. Earlier applications need the new document before a new approval; their stored status and files have not been changed in bulk.


## Vehicle policy v3
Moto: maximum declared laundry capacity 60 kg; camera capture required; vehicle photo reviewed by a manager. Bicycle: maximum 20 kg; camera or gallery photo required; manager review. These are application limits, not manufacturer-certified payload values. Camera source metadata is declared by the app and is not proof of liveness. Car/van retain registration, licence, insurance and inspection documents, with capacity verified from registration. Licence expiry is not an acceptance condition under the requested application policy; insurance and inspection validity remain mandatory. New photos are private supporting documents. Migration V3 only adds photo-source metadata and does not change existing application statuses.


## Motorcycle documents policy v4
Motorcycles now require registration front/back, driving licence front/back and current insurance, plus a camera-captured motorcycle photo for manager review. Technical inspection remains required for cars/vans, not motorcycles in this onboarding policy. The AI receipt binds the documents, photo, declared capacity and reserve to the account. Motorcycle laundry capacity stays capped at 60 kg; this cap is not the total payload including the rider. Bicycle onboarding is unchanged. Licence and registration expiry are not acceptance conditions; insurance expiry is checked. Existing receipts require a new v4 scan.

## Local OCR pilot

`server/OCR.md` documents a separate PaddleOCR pilot for Tunisian registration
certificates. It combines French and Arabic recognition, keeps word positions and
confidence scores, and validates PTAC minus empty weight against payload. On 15
October 2026, one original test card produced 1,385 t, 0,975 t and 0,410 t with a
consistent result. Eight deterministic parser tests passed.

This pilot is not connected to onboarding yet. It must be repeated on multiple
cards with different values before it can affect acceptance. Insurance layouts
vary by company and require their own extraction and expiry-date validation.
Private OCR reports and source document photos must remain outside Git.

## Test from a phone on the same Wi-Fi

Find the PC Wi-Fi IPv4 address with `ipconfig`. Stop any existing ResiDry
services, then expose only the backend to the local network:

```powershell
cd "C:\PI MOBILE\ResiDry\backend"
$env:Path += ";$env:LOCALAPPDATA\Programs\Ollama"
.\start-with-local-ai.ps1 -Bind 0.0.0.0
```

Build and install a debug APK using that address, for example:

```powershell
cd "C:\PI MOBILE\ResiDry"
flutter build apk --debug --dart-define=RESIDRY_API_URL=http://192.168.1.25:8766
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

The PC and phone must remain on the same non-isolated Wi-Fi. The address can
change after reconnecting, so rebuild with the new IPv4 address when necessary.
HTTP private-network access is accepted only by the debug build; release builds
continue to require HTTPS. The AI and Ollama remain bound to the PC loopback
interface and are reached only through the backend.
