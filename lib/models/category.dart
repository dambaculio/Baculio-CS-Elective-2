class ProductCategory {
  const ProductCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory ProductCategory.fromMap(Map<String, dynamic> map) => ProductCategory(
    id: (map['id'] as num).toInt(),
    name: map['name'] as String,
  );
}
