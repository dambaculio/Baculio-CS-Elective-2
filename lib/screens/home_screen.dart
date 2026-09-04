import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/flower_data.dart';
import '../models/flower.dart';
import '../theme/design_theme.dart';
import '../utils/responsive.dart';
import '../widgets/flower_card.dart';

enum SortOption { defaultOrder, priceLowHigh, priceHighLow }

/// StatefulWidget (Lecture 8): search text, sort order, and the
/// selected category are all mutable UI state, managed here with
/// setState() — the same pattern as the counter example.
class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _categories = [
    'All',
    'Bouquet',
    'Flowers',
    'Wrappers',
    'Ribbon',
  ];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  SortOption _sortOption = SortOption.defaultOrder;

  List<Flower> get _visibleFlowers {
    final filtered = flowerList.where((f) {
      final matchesSearch =
          f.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || f.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case SortOption.defaultOrder:
        break;
      case SortOption.priceLowHigh:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighLow:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = gridColumnsFor(deviceTypeOf(width));
    final flowers = _visibleFlowers;

    return Scaffold(
      appBar: AppBar(
        title: Text("Shai's Creation", style: DesignTheme.logoStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Cart (coming soon)',
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Message seller (coming soon)',
            onPressed: null,
          ),
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            tooltip: 'Toggle light / dark mode',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar — text/hint/icon colors are hardcoded to
              // AppColors.textColor so they stay dark/legible against
              // the pale pink fill in BOTH light and dark mode
              // (dark mode's default light text color was nearly
              // invisible against this fill).
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(color: AppColors.textColor),
                      cursorColor: AppColors.textColor,
                      decoration: InputDecoration(
                        hintText: 'Search flowers...',
                        hintStyle: TextStyle(color: AppColors.textColor.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textColor),
                        filled: true,
                        fillColor: AppColors.lightPink,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter button — now also holds the sort options
                  // that used to live in a separate dropdown.
                  PopupMenuButton<SortOption>(
                    tooltip: 'Sort',
                    initialValue: _sortOption,
                    onSelected: (value) => setState(() => _sortOption = value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: SortOption.defaultOrder,
                        child: Text('Default'),
                      ),
                      PopupMenuItem(
                        value: SortOption.priceLowHigh,
                        child: Text('Price: Low–High'),
                      ),
                      PopupMenuItem(
                        value: SortOption.priceHighLow,
                        child: Text('Price: High–Low'),
                      ),
                    ],
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primary,
                      child: const Icon(Icons.tune, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Category nav bar
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    return ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor: AppColors.lightPink,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: const StadiumBorder(),
                      onSelected: (_) => setState(() => _selectedCategory = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _selectedCategory == 'All' ? 'All Flowers' : _selectedCategory,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: flowers.isEmpty
                    ? Center(
                        child: Text(
                          'No items found.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: flowers.length,
                        itemBuilder: (context, index) {
                          final flower = flowers[index];
                          return FlowerCard(
                            flower: flower,
                            onTap: () => context.push('/product/${flower.id}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}