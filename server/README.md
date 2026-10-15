# Registration verification prototype

The Flutter flow uses two new steps: vehicle/capacity, then mandatory front/back
registration photographs. The existing governorate and final setup steps follow.
Page two stays locked until the online check passes. No offline fallback unlocks it.
Administrator approval is still required before mission assignment.

The server sends both images to OpenAI's Responses vision API with structured
output, then applies numerical/type/completeness rules itself. It does not search
for generic car capacities or claim document authenticity. Payload is either
explicitly documented or calculated from clearly documented PTAC minus empty
weight. Missing/conflicting fields require new evidence and block progression.
Owner names and addresses are not requested. Images are not stored by this server;
`store:false` is set for the Responses request, but this is not a guarantee about
provider retention. Configure an appropriate privacy/retention policy before
using real personal documents. Flutter stores submitted evidence locally.

## Configuration still required

No API key, vision model, public HTTPS endpoint or deployment is bundled.
Set `OPENAI_API_KEY`, `OPENAI_VISION_MODEL` (an image-capable model supporting
structured outputs), and `REGISTRATION_DEV_TOKEN` in the server environment.
Never put the OpenAI key in Flutter or commit it. Run:

```powershell
python server/registration_service.py
```

It binds to loopback port 8080. Put it behind HTTPS with request limits/timeouts.
For a supervised coursework test, configure Flutter with:

```powershell
flutter run --dart-define=REGISTRATION_API_URL=https://YOUR-SERVER/verify-registration --dart-define=REGISTRATION_DEV_TOKEN=YOUR-DEVELOPMENT-TOKEN
```

The development token is extractable from the app and is **not production user
authentication**. Before deployment, replace it with authenticated sessions,
per-user rate limits and server-side persisted verification receipts. Current
SQLite account creation is local; client-side checks are not a security boundary.
Use test documents until this infrastructure and consent/retention are ready.
Bicycles do not fit the registration-certificate flow and need a separate policy;
this version cannot verify them automatically.

Run deterministic backend tests:

```powershell
python -m unittest discover -s server -p "test_*.py"
```

Live AI accuracy on actual Tunisian certificates has not been evaluated yet.
Tests exercise rules and error handling; they do not establish model accuracy.
