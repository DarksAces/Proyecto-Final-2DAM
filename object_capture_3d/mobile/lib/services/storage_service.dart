import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  Future<String> saveImage(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy('${directory.path}/$fileName');
    return savedImage.path;
  }
  
  Future<void> clearTempImages() async {
      // Implement cleanup logic if needed
  }
}
