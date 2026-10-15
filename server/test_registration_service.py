import unittest
from registration_service import decide, image_data, normalize_weights

def fields(**changes):
    return dict(is_tunisian_certificate=True, both_sides_readable=True,
        same_vehicle=True, brand='Example', model='Van', year=2022,
        vehicle_type='Camionnette', payload_kg=750, gross_kg=None,
        empty_kg=None, payload_evidence='Charge utile: 750 kg',
        gross_evidence=None, empty_evidence=None, **changes)

class VerificationTests(unittest.TestCase):
    def test_tunisian_tonne_values_are_normalized_before_comparison(self):
        data = fields()
        data.update(payload_value=0.410, payload_unit='t', gross_value=1.385,
                    gross_unit='t', empty_value=0.975, empty_unit='t',
                    payload_evidence='Charge utile 0.410 t',
                    gross_evidence='PTAC 1.385 t', empty_evidence='PV 0.975 t')
        converted = normalize_weights(data)
        self.assertAlmostEqual(converted['payload_kg'], 410)
        self.assertEqual(decide(converted, 'Camionnette', 160, 250)['status'], 'passed')
        self.assertEqual(decide(converted, 'Camionnette', 200, 250)['status'], 'rejected')

    def test_unknown_units_do_not_create_a_capacity(self):
        data = fields()
        data.update(payload_value=410, payload_unit=None)
        self.assertEqual(decide(normalize_weights(data), 'Camionnette', 200, 0)['status'], 'inconclusive')

    def test_pass_equal_and_below(self):
        for load in [500, 650]:
            self.assertEqual(decide(fields(), 'Camionnette', load, 100)['status'], 'passed')

    def test_reject_excess_and_mismatch(self):
        self.assertEqual(decide(fields(), 'Camionnette', 700, 100)['status'], 'rejected')
        self.assertEqual(decide(fields(), 'Moto', 40, 100)['reason'], 'vehicle_type_mismatch')

    def test_missing_unreadable_side_or_unsupported_facts_block(self):
        for key, value in [('both_sides_readable', False), ('same_vehicle', False),
                           ('is_tunisian_certificate', False), ('year', None),
                           ('brand', None), ('payload_kg', None),
                           ('payload_evidence', None), ('vehicle_type', None)]:
            data = fields()
            data[key] = value
            self.assertEqual(decide(data, 'Camionnette', 200, 0)['status'], 'inconclusive', key)

    def test_derived_payload_and_conflicts(self):
        data = fields()
        data.update(payload_kg=None, payload_evidence=None, gross_kg=2500,
                    empty_kg=2000, gross_evidence='PTAC 2500 kg', empty_evidence='Poids a vide 2000 kg')
        self.assertEqual(decide(data, 'Camionnette', 400, 100)['payload_kg'], 500)
        data['payload_kg'] = 750
        data['payload_evidence'] = 'Charge utile 750 kg'
        self.assertEqual(decide(data, 'Camionnette', 400, 100)['status'], 'inconclusive')

    def test_image_validation(self):
        with self.assertRaises(ValueError):
            image_data('bm90IGFuIGltYWdl')

if __name__ == '__main__':
    unittest.main()
