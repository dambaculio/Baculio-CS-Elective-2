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
}