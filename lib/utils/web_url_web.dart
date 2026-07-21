// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation - get the actual browser URL
String? getWebUrlImpl() {
  return html.window.location.href;
}
