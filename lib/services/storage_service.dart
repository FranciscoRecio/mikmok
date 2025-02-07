import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> storeAvatarFromUrl(String userId, String avatarId, String sourceUrl) async {
    try {
      // Download SVG from URL
      final response = await http.get(Uri.parse(sourceUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download SVG');
      }

      // Create reference to storage location
      final ref = _storage.ref().child('avatars/$userId/$avatarId.svg');
      
      // Upload SVG data
      await ref.putData(
        response.bodyBytes,
        SettableMetadata(contentType: 'image/svg+xml'),
      );

      // Get download URL
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error storing avatar: $e');
      rethrow;
    }
  }
} 