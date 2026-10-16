import io
import unittest
import urllib.error
from verification_diagnostics import error_code

class DiagnosticsTest(unittest.TestCase):
    def test_quota_is_distinct_from_rate_limit(self):
        quota=urllib.error.HTTPError('https://api.openai.com',429,'ignored',{},io.BytesIO(b'{"error":{"code":"insufficient_quota"}}'))
        rate=urllib.error.HTTPError('https://api.openai.com',429,'ignored',{},io.BytesIO(b'{}'))
        self.assertEqual('ai_insufficient_quota',error_code(quota))
        self.assertEqual('ai_rate_limit',error_code(rate))
    def test_provider_message_is_not_exposed(self):
        error=urllib.error.HTTPError('https://api.openai.com',401,'private message',{},io.BytesIO(b'{"error":{"message":"sensitive"}}'))
        self.assertEqual('ai_invalid_api_key',error_code(error))
    def test_access_timeout_and_network(self):
        error=urllib.error.HTTPError('https://api.openai.com',403,'ignored',{},io.BytesIO(b'{}'))
        self.assertEqual('ai_model_or_project_access_denied',error_code(error))
        self.assertEqual('ai_timeout',error_code(TimeoutError()))
        self.assertEqual('ai_connection_failed',error_code(urllib.error.URLError('private')))

if __name__=='__main__': unittest.main()
