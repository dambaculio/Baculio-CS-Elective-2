class Flower {
  final String id;
  final String name;
  final double price; // or num/int based on your setup
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
    this.description = '', // Optional with default empty string
    this.slug = '',
  });

  /// Builds a Flower from a row of the Supabase `products` table.
  /// Column names are snake_case in Postgres, so `image_url` maps to
  /// `imageUrl`. `price` comes back as int or double, so use num.
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

  /// Converts a Flower into a map for insert/update calls.
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
