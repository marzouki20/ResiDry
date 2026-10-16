import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from document_references import examples, GUIDANCE
from ollama_vision import classify_image, grounded_kind

class ReferencesTests(unittest.TestCase):
    def test_only_relevant_references_and_candidate_last(self):
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ,DOCUMENT_REFERENCES_DIR=folder):
            for name in ['permis-tunisien-recto-aymen.jpeg','permis-tunisien-verso-aymen.jpeg','immatriculation-recto-exemple.jpeg']:
                (Path(folder)/name).write_bytes(b'\xff\xd8\xff12345')
            with patch('ollama_vision.analyze',side_effect=[{'visible_headings':'PERMIS DE CONDUIRE','kind':'DRIVING_LICENSE'}, {'candidate_visible_headings':'PERMIS DE CONDUIRE','compatible_layout':True}]) as model:
                classify_image('data:image/jpeg;base64,YWJj','LICENSE_FRONT')
            content=model.call_args.args[2]
            self.assertEqual(3,sum(c['type']=='input_image' for c in content))
            self.assertEqual('data:image/jpeg;base64,YWJj',content[-1]['image_url'])
            self.assertIn('CANDIDATE',content[-2]['text'])
            self.assertTrue(all('immatriculation' not in c.get('text','') for c in content))
            self.assertIn('Never fill missing candidate data',model.call_args.args[0])
    def test_references_cannot_upgrade_an_unrelated_candidate(self):
        with patch('ollama_vision.analyze',return_value={'visible_headings':'School exercise','kind':'OTHER'}) as model:
            value=classify_image('data:image/jpeg;base64,YWJj','LICENSE_FRONT')
        self.assertEqual('OTHER',value['kind'])
        self.assertEqual(1,model.call_count)
        self.assertEqual(1,sum(c['type']=='input_image' for c in model.call_args.args[2]))
    def test_missing_references_do_not_invent_images(self):
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ,DOCUMENT_REFERENCES_DIR=folder):
            self.assertEqual([],examples('FRONT'))
            self.assertEqual([],examples('INSURANCE'))
    def test_registration_weights_override_wrong_inspection_guess(self):
        self.assertEqual('REGISTRATION',grounded_kind(dict(visible_headings='PTAC/PTRA PV Charge Utile Date et lieu d etablissement',kind='TECHNICAL_INSPECTION')))
    def test_unrelated_screen_does_not_invent_inspection(self):
        self.assertEqual('OTHER',grounded_kind(dict(visible_headings='Instagram Post Android settings',kind='TECHNICAL_INSPECTION')))
    def test_registration_date_is_not_expiry(self):
        with patch('ollama_vision.examples',return_value=[]), patch('ollama_vision.analyze',return_value=dict(visible_headings='PTAC PV Charge Utile',kind='TECHNICAL_INSPECTION',expires_on='2022-04-26')):
            result=classify_image('data:image/jpeg;base64,YWJj','BACK')
        self.assertEqual('REGISTRATION',result['kind'])
        self.assertIsNone(result['expires_on'])
    def test_licence_title_overrides_wrong_inspection_guess(self):
        self.assertEqual('DRIVING_LICENSE', grounded_kind(dict(visible_headings='PERMIS DE CONDUIRE',kind='TECHNICAL_INSPECTION')))
    def test_unrelated_image_cannot_be_a_licence(self):
        self.assertEqual('OTHER', grounded_kind(dict(visible_headings='Instagram Post Settings',kind='DRIVING_LICENSE')))
    def test_licence_date_does_not_trigger_expiry(self):
        with patch('ollama_vision.examples',return_value=[]), patch('ollama_vision.analyze',return_value=dict(visible_headings='PERMIS DE CONDUIRE',kind='DRIVING_LICENSE',expires_on='2012-05-16')):
            result=classify_image('data:image/jpeg;base64,YWJj','LICENSE_FRONT')
        self.assertIsNone(result['expires_on'])
    def test_technical_inspection_is_distinct(self):
        self.assertIn('This is NOT registration',GUIDANCE)

if __name__=='__main__': unittest.main()
