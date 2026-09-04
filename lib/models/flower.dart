/// Plain data model for a single product.
class Flower {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String category;

  const Flower({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
  });
}