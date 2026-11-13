class Flower {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String category;
  final String description;
  final String slug;

  const Flower({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.category = '',
    this.description = '',
    this.slug = '',
  });

  factory Flower.fromMap(Map<String, dynamic> map) {
    return Flower(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] as String,
      category: (map['category'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      slug: (map['slug'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'description': description,
      'slug': slug,
    };
  }
}
