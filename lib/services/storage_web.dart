// Stub file for web platform - actual storage is handled via SharedPreferences
// These functions are not called on web, but must exist for conditional imports

Future<void> saveToFile(String jsonString) async {
  // Not used on web - SharedPreferences handles storage
}

Future<String?> loadFromFile() async {
  // Not used on web - SharedPreferences handles storage
  return null;
}
