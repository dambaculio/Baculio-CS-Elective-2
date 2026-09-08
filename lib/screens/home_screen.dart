import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/carousel_data.dart';
import '../data/flower_data.dart';
import '../models/flower.dart';
import '../theme/design_theme.dart';
import '../utils/responsive.dart';
import '../widgets/flower_card.dart';
import '../widgets/floating_cart_button.dart';
import '../widgets/image_carousel.dart';

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
    'All',
    'Bouquet',
    'Flowers',
    'Wrappers',
    'Ribbons',
    'Favorites',
  ];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  SortOption _sortOption = SortOption.defaultOrder;

  List<Flower> get _visibleFlowers {
    final filtered = flowerList.where((f) {
      final matchesSearch = f.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesFavorites =
          _selectedCategory != 'Favorites' || widget.favoriteIds.contains(f.id);
      final matchesCategory =
          _selectedCategory == 'All' ||
          _selectedCategory == 'Favorites' ||
          f.category == _selectedCategory;
      return matchesSearch && matchesCategory && matchesFavorites;
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
        toolbarHeight: 92,
        centerTitle: true,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: SvgPicture.asset(
                'assets/images/Shai’s Creation.svg',
                fit: BoxFit.contain,
              ),
            ),
            Text(
              "Shai's Creation",
              style: DesignTheme.logoStyle.copyWith(
                fontSize: 16,
                letterSpacing: 0,
              ),
              maxLines: 1,
            ),
          ],
        ),
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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
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
                                color: AppColors.textColor.withValues(
                                  alpha: 0.5,
                                ),
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
                          onSelected: (value) =>
                              setState(() => _sortOption = value),
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
                    const SizedBox(height: 20),
                    const ImageCarousel(imagePaths: carouselImages),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 60,
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
                            selected: isSelected,
                            selectedColor: colorScheme.primary,
                            backgroundColor: AppColors.lightPink,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textColor,
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
                      _selectedCategory == 'All'
                          ? 'All Flowers'
                          : _selectedCategory,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (flowers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No items found.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final flower = flowers[index];
                    return FlowerCard(
                      flower: flower,
                      onTap: () => context.push('/product/${flower.id}'),
                      isFavorite: widget.favoriteIds.contains(flower.id),
                      onToggleFavorite: () {
                        widget.onToggleFavorite(flower.id);
                        setState(() {});
                      },
                    );
                  }, childCount: flowers.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.7,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
