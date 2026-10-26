import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HCaptchaChallenge extends StatefulWidget {
  const HCaptchaChallenge({super.key, required this.siteKey});

  static String get configuredSiteKey =>
      dotenv.env['HCAPTCHA_SITE_KEY']?.trim() ?? '';
  static String get domain =>
      dotenv.env['HCAPTCHA_DOMAIN']?.trim().isNotEmpty == true
      ? dotenv.env['HCAPTCHA_DOMAIN']!.trim()
      : 'localhost';

  static Future<String?> show(BuildContext context) {
    final siteKey = configuredSiteKey;
    if (siteKey.isEmpty) {
      throw StateError(
        'Set HCAPTCHA_SITE_KEY when launching the app to enable CAPTCHA.',
      );
    }

    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => HCaptchaChallenge(siteKey: siteKey),
      ),
    );
  }

  final String siteKey;

  @override
  State<HCaptchaChallenge> createState() => _HCaptchaChallengeState();
}

class _HCaptchaChallengeState extends State<HCaptchaChallenge> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'HCaptchaToken',
        onMessageReceived: (message) {
          if (message.message.isNotEmpty && mounted) {
            Navigator.of(context).pop(message.message);
          }
        },
      )
      ..loadHtmlString(
        _challengeHtml,
        baseUrl: 'https://${HCaptchaChallenge.domain}',
      );
  }

  String get _challengeHtml {
    final escapedSiteKey = htmlEscape.convert(widget.siteKey);
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script src="https://js.hcaptcha.com/1/api.js" async defer></script>
  <script>
    function onHCaptchaVerified(token) {
      HCaptchaToken.postMessage(token);
    }
  </script>
  <style>
    html, body { height: 100%; margin: 0; }
    body { display: flex; align-items: center; justify-content: center; }
  </style>
</head>
<body>
  <div class="h-captcha"
       data-sitekey="$escapedSiteKey"
       data-callback="onHCaptchaVerified"></div>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Human verification'),
        leading: IconButton(
          tooltip: 'Cancel verification',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
