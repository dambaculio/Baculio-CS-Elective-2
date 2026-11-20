import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  static const String productImagesBucket = 'product-images';

  Future<String> uploadProductImage(PickedImage image) async {
    final safeName = image.fileName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]'),
      '_',
    );
    final path = 'products/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final bucket = _client.storage.from(productImagesBucket);
    await bucket.uploadBinary(
      path,
      image.bytes,
      fileOptions: FileOptions(
        contentType: image.mimeType ?? _guessMimeType(safeName),
        upsert: false,
      ),
    );
    return bucket.getPublicUrl(path);
  }

  static String _guessMimeType(String fileName) {
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.webp')) return 'image/webp';
    if (fileName.endsWith('.gif')) return 'image/gif';
    if (fileName.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
