import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- MAIN LIST PAGE (URL: "/") ---
class FruitListPage extends StatelessWidget {
  const FruitListPage({super.key});

  static const List<Map<String, String>> fruits = [
    {
      'name': 'Orange',
      'image': 'https://images.unsplash.com/photo-1611080626919-7cf5a9dbab5b?w=600',
    },
    {
      'name': 'Strawberry',
      'image': 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=600',
    },
    {
      'name': 'Apple',
      'image': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600',
    },
    {
      'name': 'Mango',
      'image': 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=600',
    },
    {
      'name': 'Grapes',
      'image': 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=600',
    },
    {
      'name': 'Pineapple',
      'image': 'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?w=600',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        title: const Text(
          'List of Fruits',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.82,
        ),
        itemCount: fruits.length,
        itemBuilder: (context, index) {
          final fruit = fruits[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          fruit['image']!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        fruit['name']!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Material(
                        color: Colors.grey.shade100,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.black87,
                          ),
                          onPressed: () => context.go('/fruit/${fruit['name']}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- DETAIL PAGE (URL: "/fruit/:name") ---
class FruitDetailPage extends StatelessWidget {
  final String fruitName;

  const FruitDetailPage({super.key, required this.fruitName});

  static const Map<String, Map<String, String>> fruitData = {
    'orange': {
      'image': 'https://images.unsplash.com/photo-1611080626919-7cf5a9dbab5b?w=600',
    },
    'strawberry': {
      'image': 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=600',
    },
    'apple': {
      'image': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600',
    },
    'mango': {
      'image': 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=600',
    },
    'grapes': {
      'image': 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=600',
    },
    'pineapple': {
      'image': 'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?w=600',
    },
  };

  @override
  Widget build(BuildContext context) {
    final details = fruitData[fruitName.toLowerCase()] ?? {
      'image': 'https://picsum.photos/400',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(fruitName),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  details['image']!,
                  width: 260,
                  height: 260,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                fruitName,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Fruits'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}