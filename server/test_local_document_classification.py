import base64
import unittest
from unittest.mock import patch
from document_verification import verify_dossier, REQUIRED

class LocalClassificationTests(unittest.TestCase):
    def data(self):
        return dict(context=dict(driver_name='Test Driver',vehicle_type='Voiture',declared_kg=100,reserve_kg=70,borrowed=False),
                    documents={slot:base64.b64encode(b'\xff\xd8\xff'+slot.encode()).decode() for slot in REQUIRED})
    def test_unrelated_image_blocks_before_joint_extraction(self):
        with patch.dict('os.environ',AI_PROVIDER='ollama'), patch('ollama_vision.classify_image',return_value={'visible_headings':'School exercise','kind':'OTHER'}), patch('document_verification.analyze_response') as extraction:
            result=verify_dossier(self.data())
        self.assertEqual('BLOCKED',result['status'])
        self.assertEqual(set(REQUIRED),{d['slot'] for d in result['documents']})
        self.assertTrue(all(d['reasons']==['wrong_document_type'] for d in result['documents']))
        extraction.assert_not_called()
    def test_expired_photo_retains_exact_date_and_slot(self):
        kinds=['REGISTRATION','REGISTRATION','DRIVING_LICENSE','DRIVING_LICENSE','INSURANCE','TECHNICAL_INSPECTION']
        findings=[dict(visible_headings='Heading',kind=kind,expires_on='2020-05-16' if kind=='INSURANCE' else None) for kind in kinds]
        with patch.dict('os.environ',AI_PROVIDER='ollama'), patch('ollama_vision.classify_image',side_effect=findings), patch('document_verification.analyze_response') as extraction:
            result=verify_dossier(self.data())
        problem=next(d for d in result['documents'] if d['slot']=='INSURANCE')
        self.assertEqual(['document_expired'],problem['reasons'])
        self.assertEqual('2020-05-16',problem['details']['expires_on'])
        extraction.assert_not_called()
    def test_uncertain_image_is_not_accepted(self):
        with patch.dict('os.environ',AI_PROVIDER='ollama'), patch('ollama_vision.classify_image',return_value={'visible_headings':'','kind':'UNCERTAIN'}):
            result=verify_dossier(self.data())
        self.assertTrue(all(d['status']=='UNCERTAIN' for d in result['documents']))

if __name__=='__main__': unittest.main()
