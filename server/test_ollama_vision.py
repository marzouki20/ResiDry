import io
import json
import unittest
from unittest.mock import patch
from ollama_vision import analyze

class OllamaTests(unittest.TestCase):
    def test_private_images_schema_and_no_paid_key(self):
        reply={'done':True,'done_reason':'stop','message':{'content':'{"photos":[]}'}}
        with patch('urllib.request.urlopen',return_value=io.BytesIO(json.dumps(reply).encode())) as call:
            self.assertEqual({'photos':[]},analyze('Inspect',{'type':'object'},[
                {'type':'input_text','text':'FRONT'}, {'type':'input_image','image_url':'data:image/jpeg;base64,YWJj'}]))
        request=call.call_args.args[0]
        self.assertIsNone(request.get_header('Authorization'))
        body=json.loads(request.data)
        self.assertEqual(['YWJj'],body['messages'][0]['images'])
        self.assertIn('FRONT',body['messages'][0]['content'])
        self.assertFalse(body['stream'])
        self.assertEqual({'type':'object'},body['format'])
        self.assertEqual(8192,body['options']['num_ctx'])
        self.assertEqual(2048,body['options']['num_predict'])
        self.assertEqual(300,call.call_args.kwargs['timeout'])
    def test_full_dossier_has_room_for_all_document_observations(self):
        reply={'done':True,'done_reason':'stop','message':{'content':'{"photos":[]}'}}
        with patch('urllib.request.urlopen',return_value=io.BytesIO(json.dumps(reply).encode())) as call:
            analyze('Inspect',{'type':'object','properties':{'photos':{'type':'array'}}},[{'type':'input_image','image_url':'data:image/jpeg;base64,YWJj'}])
        options=json.loads(call.call_args.args[0].data)['options']
        self.assertEqual(4096, options['num_predict'])
        self.assertEqual(16384, options['num_ctx'])
    def test_remote_image_urls_not_fetched(self):
        with self.assertRaises(ValueError):
            analyze('Inspect',{},[{'type':'input_image','image_url':'https://example.org/private.jpg'}])
    def test_truncated_output_rejected(self):
        with patch('urllib.request.urlopen',return_value=io.BytesIO(b'{"done":true,"done_reason":"length"}')):
            with self.assertRaises(RuntimeError): analyze('Inspect',{},[{'type':'input_image','image_url':'data:image/jpeg;base64,YWJj'}])

if __name__=='__main__': unittest.main()
