import base64
import copy
import unittest
from datetime import date
from unittest.mock import patch
from document_verification import evaluate, verify_dossier, REQUIRED


class DossierRulesTest(unittest.TestCase):
    def setUp(self):
        self.context = dict(driver_name='Test Driver', vehicle_type='Voiture', declared_kg=160, reserve_kg=250, borrowed=False)
        self.fields = dict(
            photos=[dict(slot=s,correct_type=True,correct_side=True,readable=True,evidence='visible document headings') for s in REQUIRED],
            registration=dict(tunisian=True,pair_consistent=True,brand='Example',model='Car',owner_name='Test Driver',plate='123 TU 4567',vin='VIN123',first_registration='2020-01-01',vehicle_type='Voiture',payload_value=.410,payload_unit='t',payload_evidence='Charge utile 0.410 t',gross_value=1.385,gross_unit='t',gross_evidence='PTAC 1.385 t',empty_value=.975,empty_unit='t',empty_evidence='PV .975 t'),
            license=dict(tunisian=True,pair_consistent=True,holder_name='Test Driver',valid_until='2030-01-01',categories=['B'],category_dates_clear=True),
            insurance=dict(plate='123 TU 4567',vin='VIN123',valid_from='2026-01-01',valid_until='2027-01-01',issuer='Example insurer',delivery_use='CONFIRMED',coverage_evidence='Paid delivery covered'),
            inspection=dict(tunisian=True,plate='123 TU 4567',vin='VIN123',issued_on='2026-01-01',valid_until='2027-01-01',center='Example centre',evidence='Inspection certificate'),
            authorization={})
    def result(self):
        return evaluate(self.fields,self.context,today=date(2026,10,13))
    def test_motorcycle_requires_documents_without_inspection(self):
        self.context.update(vehicle_type='Moto', declared_kg=40, reserve_kg=70)
        self.fields['registration'].update(vehicle_type='Moto', engine_cc=125)
        self.fields['license']['categories']=['A']
        self.fields['photos']=[p for p in self.fields['photos'] if p['slot']!='TECHNICAL_INSPECTION']
        self.fields['inspection']={}
        self.assertEqual('PASSED',self.result()['status'])
        self.fields['insurance']['valid_until']='2025-01-01'
        self.assertEqual('BLOCKED',self.result()['status'])
        self.fields['insurance']['valid_until']='2027-01-01'
        self.fields['photos']=[p for p in self.fields['photos'] if p['slot']!='LICENSE_BACK']
        self.assertEqual('BLOCKED',self.result()['status'])
    def test_complete_dossier_and_tonnes(self):
        result=self.result()
        self.assertEqual('PASSED',result['status'])
        self.assertEqual(410,result['payload_kg'])
        self.assertEqual(160,result['available_kg'])
    def test_meme_in_any_field_blocks(self):
        for slot in REQUIRED:
            fields=copy.deepcopy(self.fields)
            next(p for p in fields['photos'] if p['slot']==slot)['correct_type']=False
            self.assertEqual('BLOCKED',evaluate(fields,self.context,today=date(2026,10,13))['status'])
    def test_unreadable_or_wrong_side_blocks(self):
        for flag in ['readable','correct_side']:
            fields=copy.deepcopy(self.fields); fields['photos'][0][flag]=False
            self.assertEqual('BLOCKED',evaluate(fields,self.context,today=date(2026,10,13))['status'])
    def test_inspection_expired_missing_and_vehicle_mismatch_block(self):
        self.fields['inspection']['valid_until']='2025-01-01'
        result=self.result()
        failed=next(c for c in result['checks'] if c['code']=='inspection_validity')
        self.assertEqual('document_expired',failed['details']['reason'])
        self.assertEqual('BLOCKED',result['status'])
        self.fields['inspection']['valid_until']='2027-01-01'
        self.fields['inspection']['plate']='different'
        self.assertEqual('BLOCKED',self.result()['status'])
        self.fields['inspection']={}
        self.assertEqual('BLOCKED',self.result()['status'])
    def test_overload_blocks(self):
        self.context['declared_kg']=200
        self.assertEqual('BLOCKED',self.result()['status'])
    def test_license_expiry_is_not_required_but_insurance_expiry_is(self):
        self.fields['license']['valid_until']=None
        self.fields['license']['category_dates_clear']=False
        self.assertEqual('PASSED',self.result()['status'])
        self.fields['license']['valid_until']='2012-05-16'
        self.assertEqual('PASSED',self.result()['status'])
        self.fields['insurance']['valid_until']='2025-01-01'
        self.assertEqual('BLOCKED',self.result()['status'])
    def test_person_or_plate_mismatch_blocks(self):
        self.fields['license']['holder_name']='Another Driver'
        self.assertEqual('BLOCKED',self.result()['status'])
        self.fields['license']['holder_name']='Test Driver'
        self.fields['insurance']['plate']='different'
        self.assertEqual('BLOCKED',self.result()['status'])
    def test_missing_or_excluded_delivery_coverage_blocks(self):
        for value in ['UNCERTAIN','EXCLUDED']:
            self.fields['insurance']['delivery_use']=value
            self.assertEqual('BLOCKED',self.result()['status'])
    def test_missing_category_and_conflicting_weights_block(self):
        self.fields['license']['categories']=[]
        self.assertEqual('BLOCKED',self.result()['status'])
        self.fields['license']['categories']=['B']; self.fields['registration']['payload_value']=.6
        self.assertEqual('BLOCKED',self.result()['status'])
    def test_borrowed_vehicle_without_authorization_goes_to_admin(self):
        self.context['borrowed']=True
        self.fields['registration']['owner_name']='Owner'
        result=self.result()
        self.assertEqual('PASSED',result['status'])
        self.assertIn('borrowed_vehicle_declared',[c['code'] for c in result['checks']])
        self.context['borrowed']=False
        self.assertEqual('BLOCKED',self.result()['status'])
    def test_duplicate_photos_rejected_before_provider_call(self):
        photo=base64.b64encode(b'\xff\xd8\xff12345').decode()
        with patch('document_verification.analyze_response') as model:
            result=verify_dossier(dict(context=self.context,documents={s:photo for s in REQUIRED}))
        self.assertEqual('BLOCKED',result['status']); model.assert_not_called()
    def test_all_images_labelled_for_model(self):
        documents={s:base64.b64encode(b'\xff\xd8\xff'+s.encode()).decode() for s in REQUIRED}
        with patch('document_verification.analyze_response',return_value=self.fields) as model:
            verify_dossier(dict(context=self.context,documents=documents))
        content=model.call_args.args[3]
        self.assertEqual(len(REQUIRED),sum(c['type']=='input_image' for c in content))
        self.assertTrue(all(any(s in c.get('text','') for c in content) for s in REQUIRED))

if __name__=='__main__': unittest.main()
