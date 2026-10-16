# ResiDry OCR pilot

This pilot reads original registration images locally. It does not approve an
application, change driver eligibility, or train Gemma. PaddleOCR downloads
public model weights on first use; document images stay on the PC.

Pinned packages tested in a dedicated Python environment:

```powershell
python -m venv .venv-ocr
.\.venv-ocr\Scripts\python.exe -m pip install -r server/requirements-ocr.txt
.\.venv-ocr\Scripts\python.exe server/ocr_probe.py --lang fr --output private-ocr-fr.json "PATH_TO_BACK_IMAGE" "PATH_TO_FRONT_IMAGE"
.\.venv-ocr\Scripts\python.exe server/ocr_probe.py --lang ar --output private-ocr-ar.json "PATH_TO_BACK_IMAGE" "PATH_TO_FRONT_IMAGE"
.\.venv-ocr\Scripts\python.exe server/ocr_registration_report.py --fr private-ocr-fr.json --ar private-ocr-ar.json --output private-ocr-summary.json
```

Reports contain private OCR text and bounding boxes. Keep them out of Git and
shared logs. Terminal output contains counts and timings only. Both language
passes are needed for mixed French/Arabic layouts. The parser only returns a
weight when its label, numeric value and printed unit were read with sufficient
confidence; it checks gross minus empty against payload. It never fills a field
from a stored reference image. An OCR confidence is not proof of correctness.

Acceptance before onboarding integration:

- Read the submitted card's three actual weights and units correctly.
- Repeat on different cards, with different capacities.
- Abstain on missing units, contradictions, low-confidence numbers and unrelated images.
- Check original images and positioning, not screenshots of the app.
- Keep existing approval, identity, insurance, category and mission checks active.

Card detection, perspective correction, insurance/date extraction, multilingual
name comparison and production service integration must be separately validated.

## Validated pilot result (15 October 2026)

On one original Tunisian registration certificate supplied for local testing,
the combined French/Arabic passes read PTAC 1,385 t, empty weight 0,975 t and
payload 0,410 t. The deterministic check confirmed 1,385 - 0,975 = 0,410 t.
The front title and private-car genre were also detected. Eight parser tests pass,
including different capacities, split Arabic labels, missing units, low confidence,
contradictory weights and an unrelated image. This validates the extraction pilot
on that card only; it is not yet wired into onboarding and does not establish
accuracy across all Tunisian cards or insurance layouts.
