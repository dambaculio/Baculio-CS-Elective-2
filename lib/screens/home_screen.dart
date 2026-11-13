import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/carousel_data.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme/design_theme.dart';
import '../utils/responsive.dart';
import '../widgets/flower_card.dart';
import '../widgets/floating_cart_button.dart';
import '../widgets/image_carousel.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final Set<String> favoriteIds;
  final void Function(String productId) onToggleFavorite;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
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

  final GlobalKey _resultsKey = GlobalKey();

  RangeValues? _draftPrice;

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ProductProvider>().search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToPage(ProductProvider products, int page) {
    products.goToPage(page);
    final target = _resultsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = gridColumnsFor(deviceTypeOf(width));
    final products = context.watch<ProductProvider>();
    final flowers = products.items;

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
          const _AccountMenu(),
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
        itemCount: context.watch<CartProvider>().itemCount,
        onTap: () => context.push('/cart'),
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
                            controller: _searchController,
                            onChanged: products.setSearch,
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
                          initialValue: products.sort,
                          onSelected: products.setSort,
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
                          final isSelected = category == products.category;
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
                            onSelected: (_) => products.setCategory(category),
                          );
                        },
                      ),
                    ),
                    if (products.hasPriceData) ...[
                      const SizedBox(height: 8),
                      _PriceFilter(
                        bounds: products.priceBounds,
                        values: _draftPrice ?? products.priceRange,
                        isFiltered: products.isPriceFiltered,
                        onChanged: (v) => setState(() => _draftPrice = v),
                        onChangeEnd: (v) {
                          setState(() => _draftPrice = null);
                          products.setPriceRange(
                            RangeValues(
                              v.start.roundToDouble(),
                              v.end.roundToDouble(),
                            ),
                          );
                        },
                        onReset: () {
                          setState(() => _draftPrice = null);
                          products.resetPriceRange();
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      key: _resultsKey,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            products.category == 'All'
                                ? 'All Flowers'
                                : products.category,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        if (products.totalCount > 0)
                          Text(
                            '${products.firstItemNumber}–'
                            '${products.lastItemNumber} of '
                            '${products.totalCount}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 4,
                      child: products.isLoading && flowers.isNotEmpty
                          ? LinearProgressIndicator(
                              color: colorScheme.primary,
                              backgroundColor: AppColors.lightPink,
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (products.state == ProductLoadState.error && flowers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorView(
                  message: products.errorMessage ?? 'Something went wrong.',
                  onRetry: products.refresh,
                ),
              )
            else if (flowers.isEmpty &&
                (products.isLoading || products.state == ProductLoadState.idle))
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (flowers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No items found.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverOpacity(
                  opacity: products.isLoading ? 0.5 : 1,
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
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                sliver: SliverToBoxAdapter(
                  child: _PaginationBar(
                    page: products.page,
                    totalPages: products.totalPages,
                    enabled: !products.isLoading,
                    onPageSelected: (p) => _goToPage(products, p),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceFilter extends StatelessWidget {
  final RangeValues bounds;
  final RangeValues values;
  final bool isFiltered;
  final ValueChanged<RangeValues> onChanged;
  final ValueChanged<RangeValues> onChangeEnd;
  final VoidCallback onReset;

  const _PriceFilter({
    required this.bounds,
    required this.values,
    required this.isFiltered,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onReset,
  });

  static String _peso(double v) => '\u20b1${v.round()}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final divisions = ((bounds.end - bounds.start) / 10).round().clamp(1, 1000);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Price: ${_peso(values.start)} – ${_peso(values.end)}',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isFiltered)
                TextButton(
                  onPressed: onReset,
                  child: Text(
                    'Reset',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
            ],
          ),
          RangeSlider(
            min: bounds.start,
            max: bounds.end,
            divisions: divisions,
            values: RangeValues(
              values.start.clamp(bounds.start, bounds.end).toDouble(),
              values.end.clamp(bounds.start, bounds.end).toDouble(),
            ),
            labels: RangeLabels(_peso(values.start), _peso(values.end)),
            activeColor: colorScheme.primary,
            inactiveColor: AppColors.pink,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_peso(bounds.start), style: textTheme.bodySmall),
                Text(_peso(bounds.end), style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final bool enabled;
  final ValueChanged<int> onPageSelected;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.enabled,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    const window = 5;
    var first = (page - window ~/ 2).clamp(0, totalPages - 1);
    final last = (first + window - 1).clamp(0, totalPages - 1);
    first = (last - window + 1).clamp(0, totalPages - 1);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          IconButton(
            tooltip: 'Previous page',
            onPressed: enabled && page > 0
                ? () => onPageSelected(page - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          for (var i = first; i <= last; i++)
            SizedBox(
              width: 40,
              height: 40,
              child: i == page
                  ? FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                        disabledBackgroundColor: colorScheme.primary,
                        disabledForegroundColor: Colors.white,
                      ),
                      child: Text('${i + 1}'),
                    )
                  : OutlinedButton(
                      onPressed: enabled ? () => onPageSelected(i) : null,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                        side: const BorderSide(color: AppColors.pink),
                      ),
                      child: Text('${i + 1}'),
                    ),
            ),
          IconButton(
            tooltip: 'Next page',
            onPressed: enabled && page < totalPages - 1
                ? () => onPageSelected(page + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              "Couldn't load products.",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  Future<void> _signOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.signOut();
      cart.clear();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final via = auth.signInMethod == 'github' ? 'GitHub' : 'Email';

    return PopupMenuButton<String>(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (value) {
        if (value == 'signout') _signOut(context);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.email ?? 'Signed in',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Signed in with $via'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'signout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
          ),
        ),
      ],
    );
  }
}
