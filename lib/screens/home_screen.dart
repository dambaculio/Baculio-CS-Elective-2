import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/flower_data.dart';
import '../models/flower.dart';
import '../theme/design_theme.dart';
import '../utils/responsive.dart';
import '../widgets/flower_card.dart';
import '../widgets/floating_cart_button.dart';

enum SortOption { defaultOrder, priceLowHigh, priceHighLow }

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final int cartItemCount;
  final VoidCallback onCartTap;
  final Set<String> favoriteIds;
  final void Function(String productId) onToggleFavorite;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.cartItemCount,
    required this.onCartTap,
    required this.favoriteIds,
    required this.onToggleFavorite,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _categories = [
    'Favorites',
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
      final matchesSearch = f.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory = _selectedCategory == 'Favorites'
          ? widget.favoriteIds.contains(f.id)
          : _selectedCategory == 'All' || f.category == _selectedCategory;
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
          // Cart and chat icons removed from here — cart now lives
          // as a floating button (see floatingActionButton below).
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
      floatingActionButton: FloatingCartButton(
        itemCount: widget.cartItemCount,
        onTap: widget.onCartTap,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: const TextStyle(color: AppColors.textColor),
                      cursorColor: AppColors.textColor,
                      decoration: InputDecoration(
                        hintText: 'Search flowers...',
                        hintStyle: TextStyle(
                          color: AppColors.textColor.withValues(alpha: 0.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textColor,
                        ),
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
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    return ChoiceChip(
                      label: Text(category),
                      avatar: category == 'Favorites'
                          ? Icon(
                              Icons.star,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.primary,
                            )
                          : null,
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor: AppColors.lightPink,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: const StadiumBorder(),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _selectedCategory == 'Favorites'
                    ? 'Favorites'
                    : _selectedCategory == 'All'
                    ? 'All Flowers'
                    : _selectedCategory,
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
                            isFavorite: widget.favoriteIds.contains(flower.id),
                            onToggleFavorite: () =>
                                widget.onToggleFavorite(flower.id),
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
