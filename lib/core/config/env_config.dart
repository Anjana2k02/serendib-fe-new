/// Environment Configuration
/// Switch between environments by commenting/uncommenting the URLs below.
/// Only ONE url should be active (uncommented) per server at a time.
class EnvConfig {
  EnvConfig._();

  // ─────────────────────────────────────────────
  // Spring Boot Backend (Java)
  // ─────────────────────────────────────────────

  // LOCAL
  // static const String backendUrl = 'http://localhost:8080';

  // HOSTED
  static const String backendUrl = 'https://serendib-be-production.up.railway.app';

  // ─────────────────────────────────────────────
  // Python Server 1
  // ─────────────────────────────────────────────

  // LOCAL
  static const String pythonServer1Url = 'http://localhost:8888';

  // HOSTED
  // static const String pythonServer1Url = 'https://museum-model1-production.up.railway.app';

  // ─────────────────────────────────────────────
  // Python Server 2
  // ─────────────────────────────────────────────

  // LOCAL
  static const String pythonServer2Url = 'http://localhost:5001';

  // HOSTED
  // static const String pythonServer2Url = 'https://python2.serendib.com';
}
