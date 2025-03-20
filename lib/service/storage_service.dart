import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 🔹 Récupérer les images des plats depuis Firebase Storage
  Future<List<String>> getPlatsImages(List<String> plats) async {
    List<String> imageUrls = [];
    for (String filePath in plats) {
      try {
        String url = await _storage.ref(filePath).getDownloadURL();
        imageUrls.add(url);
      } catch (e) {
        print("❌ Erreur récupération image: $e");
      }
    }
    return imageUrls;
  }
}
