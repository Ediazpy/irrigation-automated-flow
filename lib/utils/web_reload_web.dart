// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation - force reload to clear service worker cache
void forceWebReloadImpl() {
  // Force reload bypasses the cache
  html.window.location.reload();
}
