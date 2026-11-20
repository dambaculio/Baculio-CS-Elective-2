import 'dart:typed_data';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.description = '',
    this.imageUrl,
    this.categoryName,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? imageUrl;
  final int categoryId;
  final String? categoryName;

  bool get inStock => stock > 0;

  factory Product.fromMap(Map<String, dynamic> map) {
    final category = map['categories'];
    return Product(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      price: ((map['price'] as num?) ?? 0).toDouble(),
      stock: ((map['stock'] as num?) ?? 0).toInt(),
      imageUrl: map['image_url'] as String?,
      categoryId: (map['category_id'] as num).toInt(),
      categoryName: category is Map<String, dynamic>
          ? category['name'] as String?
          : null,
    );
  }
}

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.imageUrl,
  });

  final String name;
  final String description;
  final double price;
  final int stock;
  final int categoryId;
  final String? imageUrl;

  ProductDraft withImageUrl(String? url) => ProductDraft(
    name: name,
    description: description,
    price: price,
    stock: stock,
    categoryId: categoryId,
    imageUrl: url,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'category_id': categoryId,
    'image_url': imageUrl,
  };
}

class ProductPage {
  const ProductPage({required this.items, required this.totalCount});

  final List<Product> items;
  final int totalCount;
}

class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String? mimeType;
}
