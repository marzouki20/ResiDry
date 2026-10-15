import unittest
from registration_ocr import registration_fields

def token(text,x,y,score=.98):
    return dict(text=text,score=score,box=[x,y,x+45,y+20])

def document(payload='.300',gross='1.200',empty='.900',units=True):
    rows=[]
    for i,(label,value) in enumerate([('Charge Utile',payload),('PTAC/PTRA',gross),('PV',empty)]):
        rows += [token(label,0,i*50),token(value,140,i*50)]
        if units: rows += [token('طن',90,i*50)]
    return rows

class WeightTests(unittest.TestCase):
    def test_printed_tonnes_and_consistency(self):
        # Leading zero is part of the actual OCR numeric representation.
        result=registration_fields(document('0.300','1.200','0.900'))
        self.assertEqual('READ',result['status'])
        self.assertEqual(300,result['fields']['payload']['kg'])
    def test_different_values_do_not_use_reference_capacity(self):
        result=registration_fields(document('0.750','2.100','1.350'))
        self.assertEqual(750,result['fields']['payload']['kg'])
    def test_missing_units_abstains(self):
        self.assertEqual('UNCERTAIN',registration_fields(document(units=False))['status'])
    def test_low_confidence_abstains(self):
        rows=document('0.300','1.200','0.900')
        rows[1]['score']=.2
        self.assertEqual('UNREADABLE',registration_fields(rows)['fields']['payload']['status'])
    def test_inconsistent_weights_do_not_pass(self):
        result=registration_fields(document('0.500','1.200','0.900'))
        self.assertEqual('weights_inconsistent',result['reason'])
    def test_unrelated_image_does_not_produce_weights(self):
        result=registration_fields([token('Instagram',0,0),token('2026/05/16',100,0)])
        self.assertEqual('UNCERTAIN',result['status'])
    def test_decimal_comma_and_kg(self):
        rows=[]
        for i,(label,value) in enumerate([('Charge Utile','300 kg'),('PTAC','1200 kg'),('PV','900 kg')]):
            rows += [token(label,0,i*50),token(value,100,i*50)]
        result=registration_fields(rows)
        self.assertEqual('READ',result['status'])
        self.assertEqual(300,result['fields']['payload']['kg'])
    def test_split_arabic_empty_weight_label(self):
        rows=document('0.410','1.385','0.975')
        rows=[r for r in rows if r['text'] != 'PV']
        rows += [token('الوزن',250,100), token('فارغ',300,100)]
        result=registration_fields(rows)
        self.assertEqual('READ',result['status'])
        self.assertEqual(975,result['fields']['empty']['kg'])

if __name__=='__main__': unittest.main()
