"""Summarize two local language passes without disclosing identity text."""
import argparse
import json
from pathlib import Path
from registration_ocr import registration_fields, tokens_from_reports, normalized


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--fr', required=True)
    parser.add_argument('--ar', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    french = json.loads(Path(args.fr).read_text(encoding='utf-8'))
    arabic = json.loads(Path(args.ar).read_text(encoding='utf-8'))
    if len(french) != len(arabic):
        raise ValueError('language_passes_must_use_the_same_image_order')
    results = []
    for index, (fr, ar) in enumerate(zip(french, arabic)):
        if (fr['width'],fr['height']) != (ar['width'],ar['height']):
            raise ValueError('image_dimensions_must_match')
        # New reports are cryptographically bound to the same image. Reports
        # produced before this field existed remain readable for this pilot.
        if (fr.get('sha256') or ar.get('sha256')) and fr.get('sha256') != ar.get('sha256'):
            raise ValueError('language_passes_must_use_the_exact_same_images')
        tokens = tokens_from_reports([fr, ar])
        texts = [normalized(t['text']) for t in tokens if t['score'] >= .75]
        title = any('immatriculation' in t or normalized('شهادة تسجيل') in t for t in texts)
        result = dict(image_index=index, registration_title_read=title)
        if any('ptac' in t or 'chargeutile' in t for t in texts):
            result['weights'] = registration_fields(tokens)
        if any(normalized('سيارة خاصة') in t or 'voitureparticuliere' in t for t in texts):
            result['vehicle_type'] = 'Voiture'
        results.append(result)
    Path(args.output).write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(results,ensure_ascii=True,indent=2))


if __name__ == '__main__':
    main()
