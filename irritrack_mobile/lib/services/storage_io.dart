import 'dart:io';
import 'package:path_provider/path_provider.dart';

const String _fileName = 'irritrack_data.json';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/$_fileName');
}

Future<void> saveToFile(String jsonString) async {
  final file = await _localFile;
  await file.writeAsString(jsonString);
}

Future<String?> loadFromFile() async {
  final file = await _localFile;
  if (!await file.exists()) {
    return null;
  }
  return await file.readAsString();
}
