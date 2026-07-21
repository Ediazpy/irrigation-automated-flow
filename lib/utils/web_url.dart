import 'web_url_stub.dart'
    if (dart.library.html) 'web_url_web.dart';

/// Get the actual browser URL (window.location.href on web, null on mobile)
String? getWebUrl() => getWebUrlImpl();
