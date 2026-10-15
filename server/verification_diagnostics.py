"""Only allowlisted error codes are persisted: no keys, images or provider messages."""
import json
import socket
import urllib.error
from pathlib import Path

LOG = Path(__file__).resolve().parent / 'verification-status.json'

def error_code(error):
    if isinstance(error, urllib.error.HTTPError):
        provider_code = None
        try:
            body = json.loads(error.read(8192))
            provider_code = body.get('error', {}).get('code')
        except (ValueError, AttributeError, TypeError):
            pass
        if provider_code == 'insufficient_quota': return 'ai_insufficient_quota'
        if error.code == 401: return 'ai_invalid_api_key'
        if error.code in (403, 404): return 'ai_model_or_project_access_denied'
        if error.code == 429: return 'ai_rate_limit'
        if error.code == 400: return 'ai_request_or_image_invalid'
        return 'ai_provider_unavailable'
    if isinstance(error, (TimeoutError, socket.timeout)): return 'ai_timeout'
    if isinstance(error, urllib.error.URLError): return 'ai_connection_failed'
    if isinstance(error, RuntimeError):
        return {'AI service is not configured': 'ai_not_configured',
                'incomplete_response': 'ai_incomplete_response',
                'model_refusal_or_missing_response': 'ai_refused_or_empty_response'}.get(str(error), 'ai_internal_error')
    return 'ai_internal_error'

def record(code):
    # No exception text, headers, document contents or account data in this file.
    try:
        LOG.write_text(json.dumps({'code': code}), encoding='utf-8')
    except OSError:
        pass
