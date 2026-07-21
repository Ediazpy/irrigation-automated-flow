import 'web_reload_stub.dart'
    if (dart.library.html) 'web_reload_web.dart';

/// Force reload the web page to clear cache and get latest version
/// No-op on mobile platforms
void forceWebReload() => forceWebReloadImpl();
