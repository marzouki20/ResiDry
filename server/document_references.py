"""Private visual examples. No training and no copying exemplar identity/weight values."""
import base64
import json
import os
from pathlib import Path

GUIDANCE = '''Tunisian document layout guidance:
DRIVING_LICENSE: headings PERMIS DE CONDUIRE / رخصة سياقة. Front has identity/photo;
back has categories A1, A, B, B+E, C, D and their issue/expiry columns.
REGISTRATION: CERTIFICAT D'IMMATRICULATION / شهادة تسجيل. Front has vehicle/owner
identifiers. Back has Nombre de places, PTAC/PTRA, PV, Charge Utile and restrictions. These identify registration, not technical inspection. Date et lieu d etablissement is an ISSUE date, not expiry. Registration has no expiry check in this application.
TECHNICAL_INSPECTION: شهادة الفحص الفني, issue date, valid-until, vehicle identifiers,
inspection centre and stamp. Read expiry only next to the valid-until label, not the issue-date label. A file named authorization may actually contain inspection: inspect the image, never its filename. This is NOT registration, driving licence, insurance or owner vehicle-use authorization.
Examples may be SPECIMEN, expired, unreadable or belong to different vehicles.
Recognize legitimate layout variations. Layout resemblance is not authenticity.
Never fill missing candidate data with example names, dates, identifiers or weights.
'''

FILES = {
    'FRONT': ['immatriculation-recto-aymen.jpeg', 'immatriculation-verso-aymen.jpeg'],
    'BACK': ['immatriculation-recto-aymen.jpeg', 'immatriculation-verso-aymen.jpeg'],
    'LICENSE_FRONT': ['permis-tunisien-recto-aymen.jpeg', 'permis-tunisien-verso-aymen.jpeg'],
    'LICENSE_BACK': ['permis-tunisien-recto-aymen.jpeg', 'permis-tunisien-verso-aymen.jpeg'],
    'TECHNICAL_INSPECTION': ['visite-technique-aymen.jpeg'],
}

def examples(slot):
    root = Path(os.environ.get('DOCUMENT_REFERENCES_DIR', str(Path(__file__).parent/'document_references')))
    files = FILES.get(slot, [])
    result = []
    for name in files:
        path = root/name
        if not path.is_file():
            continue
        raw = path.read_bytes()
        if not 0 < len(raw) <= 5*1024*1024:
            raise ValueError('reference_image_size')
        if raw.startswith(b'\xff\xd8\xff'):
            mime='image/jpeg'
        elif raw.startswith(b'\x89PNG\r\n\x1a\n'):
            mime='image/png'
        else:
            raise ValueError('reference_image_format')
        result.extend([dict(type='input_text',text='LAYOUT REFERENCE ONLY: '+name+'. Not the candidate. Ignore its personal values and dates.'),
                       dict(type='input_image',image_url=f'data:{mime};base64,'+base64.b64encode(raw).decode())])
    return result
