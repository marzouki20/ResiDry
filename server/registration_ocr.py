"""Evidence-based extraction from OCR lines. No document/example values are stored here."""
import re
import unicodedata
from decimal import Decimal, InvalidOperation


def normalized(text):
    text = unicodedata.normalize('NFKD', text).casefold()
    return ''.join(c for c in text if c.isalnum() and not unicodedata.combining(c))


def tokens_from_reports(reports):
    tokens = []
    for report in reports:
        for page in report['pages']:
            for text, score, box in zip(page['texts'], page['scores'], page['boxes']):
                if text.strip():
                    tokens.append(dict(text=text, score=float(score), box=[float(v) for v in box]))
    return tokens


def row_near(a, b):
    ay = (a['box'][1] + a['box'][3]) / 2
    by = (b['box'][1] + b['box'][3]) / 2
    height = max(a['box'][3]-a['box'][1], b['box'][3]-b['box'][1], 1)
    return abs(ay-by) <= height * .65


def gap(a, b):
    return max(0, a['box'][0]-b['box'][2], b['box'][0]-a['box'][2])


def numeric(text):
    # Only a numeric line, optionally followed/preceded by a unit: never a date or identifier.
    text = ''.join(str(unicodedata.digit(c)) if c.isdigit() else c for c in text)
    match = re.fullmatch(r'\s*(?:طن|kg|t|كغ)?\s*(\d{1,5}(?:[.,٫]\d{1,3})?)\s*(?:طن|kg|t|كغ)?\s*', text, re.I)
    if not match:
        return None
    try:
        value = Decimal(match[1].replace(',', '.').replace('٫', '.'))
        return value if value > 0 else None
    except InvalidOperation:
        return None


def unit(text):
    if re.search(r'(?<![A-Za-z])kg(?![A-Za-z])|كغ', text, re.I):
        return 'kg'
    if re.search(r'(?<![A-Za-z])t(?![A-Za-z])|طن', text, re.I):
        return 't'
    return None


def weight(tokens, aliases):
    anchors = [t for t in tokens if t['score'] >= .75 and any(a in normalized(t['text']) for a in aliases)]
    readings = []
    for anchor in anchors:
        candidates = [t for t in tokens if t['score'] >= .75 and row_near(anchor, t) and numeric(t['text']) is not None]
        candidates.sort(key=lambda t: gap(anchor, t))
        if not candidates:
            continue
        candidate = candidates[0]
        value = numeric(candidate['text'])
        units = [t for t in tokens if t['score'] >= .75 and row_near(candidate, t) and unit(t['text']) and gap(candidate, t) <= max(30, (candidate['box'][3]-candidate['box'][1])*4)]
        explicit = unit(candidate['text']) or unit(anchor['text'])
        if not explicit and units:
            units.sort(key=lambda t: gap(candidate, t))
            explicit = unit(units[0]['text'])
        if not explicit:
            continue
        kg = value * (1000 if explicit == 't' else 1)
        readings.append(dict(kg=float(kg), value=str(value), unit=explicit,
                             label=anchor['text'], observed=candidate['text'],
                             confidence=min(anchor['score'], candidate['score'])))
    if not readings:
        return dict(status='UNREADABLE', reason='label_value_or_unit_not_read')
    values = {Decimal(str(r['kg'])) for r in readings}
    if len(values) != 1:
        return dict(status='UNCERTAIN', reason='conflicting_ocr_readings')
    best = max(readings, key=lambda r: r['confidence'])
    return dict(status='READ', **best)


def registration_fields(tokens):
    fields = {
        'payload': weight(tokens, ['chargeutile', normalized('الحمولة')]),
        'gross': weight(tokens, ['ptac']),
        # The Arabic label is commonly detected as two boxes: "weight" and "empty".
        'empty': weight(tokens, ['pv', normalized('الوزن'), normalized('فارغ')]),
    }
    if all(fields[k]['status']=='READ' for k in fields):
        gross, empty, payload = [Decimal(str(fields[k]['kg'])) for k in ['gross','empty','payload']]
        consistent = gross > empty > 0 and abs(gross-empty-payload) <= Decimal('1')
        if not consistent:
            return dict(status='UNCERTAIN', reason='weights_inconsistent', fields=fields)
    return dict(status='READ' if all(f['status']=='READ' for f in fields.values()) else 'UNCERTAIN', fields=fields)
