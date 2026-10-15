"""Local OCR experiment. Raw text stays in a local report, never in stdout."""
import os
os.environ['PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK'] = 'True'
os.environ['HF_HUB_DISABLE_TELEMETRY'] = '1'
import argparse
import hashlib
import json
import time
from pathlib import Path

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--lang', choices=['fr', 'ar'], default='fr')
    parser.add_argument('--output', required=True)
    parser.add_argument('images', nargs='+')
    args = parser.parse_args()
    from paddleocr import PaddleOCR
    ocr = PaddleOCR(ocr_version='PP-OCRv5', lang=args.lang,
                   use_doc_orientation_classify=False,
                   use_doc_unwarping=False, use_textline_orientation=False,
                   device='cpu', enable_mkldnn=False, cpu_threads=4,
                   text_det_limit_side_len=1600, text_det_limit_type='max')
    records = []
    for index, filename in enumerate(args.images):
        start = time.monotonic()
        # Byte loading avoids Windows Unicode filename decoding problems.
        import cv2
        import numpy as np
        image_bytes = Path(filename).read_bytes()
        img = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError('invalid_image')
        pages = []
        for result in ocr.predict(img):
            raw = result.json
            if isinstance(raw, str):
                raw = json.loads(raw)
            value = raw.get('res', raw)
            pages.append({'texts': value['rec_texts'], 'scores': value['rec_scores'],
                          'boxes': value['rec_boxes']})
        records.append({'image_index': index, 'language': args.lang,
                        'sha256': hashlib.sha256(image_bytes).hexdigest(),
                        'width': img.shape[1], 'height': img.shape[0], 'pages': pages})
        Path(args.output).write_text(json.dumps(records, ensure_ascii=False), encoding='utf-8')
        print(f'image={index} lines={sum(len(p["texts"]) for p in pages)} seconds={time.monotonic()-start:.1f}', flush=True)

if __name__ == '__main__':
    main()
