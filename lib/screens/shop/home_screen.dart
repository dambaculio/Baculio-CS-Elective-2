import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/carousel_data.dart';
import '../../models/product.dart';
import '../../providers/auth_providers.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_providers.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/product_providers.dart';
import '../../providers/theme_provider.dart';
import '../../theme/design_theme.dart';
import '../../utils/errors.dart';
import '../../utils/responsive.dart';
import '../../widgets/account_menu.dart';
import '../../widgets/floating_cart_button.dart';
import '../../widgets/image_carousel.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/price_filter.dart';
import '../../widgets/product_actions.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _resultsKey = GlobalKey();
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(productFilterProvider).search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    ref.read(productFilterProvider.notifier).goToPage(page);
    final target = _resultsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(priceBoundsProvider);
    ref.invalidate(currentProfileProvider);
    await ref
        .refresh(productPageProvider.future)
        .catchError((_) => const ProductPage(items: [], totalCount: 0));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        centerTitle: true,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_color.png',
              height: 56,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 4),
            Text(
              "Shai's Creation",
              style: DesignTheme.logoStyle.copyWith(fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle light / dark mode',
            onPressed: ref.read(themeModeProvider.notifier).toggle,
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
          ),
          const AccountMenu(),
        ],
      ),
      floatingActionButton: profile.hasValue ? _buildFab() : null,
      body: profile.when(
        skipLoadingOnReload: true,
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: describeError(error),
          permissionDenied: isPermissionDenied(error),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) => _buildShop(context, profile?.isAdmin ?? false),
      ),
    );
  }

  Widget _buildFab() {
    final isAdmin = ref.watch(isAdminProvider);
    if (isAdmin) {
      return FloatingActionButton.extended(
        onPressed: () => context.push('/admin/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      );
    }
    return FloatingCartButton(
      itemCount: ref.watch(cartCountProvider),
      onTap: () => context.push('/cart'),
    );
  }

  Widget _buildShop(BuildContext context, bool isAdmin) {
    final filter = ref.watch(productFilterProvider);
    final pageValue = ref.watch(productPageProvider);
    final boundsValue = ref.watch(priceBoundsProvider);
    final bounds = boundsValue.value;
    final categories = ref.watch(categoriesProvider);
    final favorites = ref.watch(favoritesProvider);
    final filterNotifier = ref.read(productFilterProvider.notifier);
    final hPad = sidePadding(MediaQuery.sizeOf(context).width);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final categoryList = categories.value ?? const [];
    final selectedName = filter.favoritesOnly
        ? 'Favorites'
        : filter.categoryId == null
        ? 'All Products'
        : categoryList
                  .where((c) => c.id == filter.categoryId)
                  .map((c) => c.name)
                  .firstOrNull ??
              'Products';

    final page = pageValue.value;
    final totalPages = page == null || page.totalCount == 0
        ? 1
        : (page.totalCount / productsPerPage).ceil();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: filterNotifier.setSearch,
                          style: const TextStyle(color: AppColors.textColor),
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
                        initialValue: filter.sort,
                        onSelected: filterNotifier.setSort,
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
                  const SizedBox(height: 16),
                  const ImageCarousel(imagePaths: carouselImages),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: 'All',
                          selected: filter.showingAll,
                          onTap: filterNotifier.showAll,
                        ),
                        for (final category in categoryList)
                          _CategoryChip(
                            label: category.name,
                            selected: filter.categoryId == category.id,
                            onTap: () =>
                                filterNotifier.selectCategory(category.id),
                          ),
                        if (!isAdmin)
                          _CategoryChip(
                            label: 'Favorites',
                            selected: filter.favoritesOnly,
                            onTap: filterNotifier.showFavorites,
                          ),
                      ],
                    ),
                  ),
                  if (categories.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Couldn't load categories: "
                        '${describeError(categories.error!)}',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  if (bounds != null) ...[
                    const SizedBox(height: 8),
                    PriceFilter(
                      bounds: bounds,
                      selected: filter.priceRange,
                      onChanged: filterNotifier.setPriceRange,
                    ),
                  ] else if (boundsValue.hasError)
                    TextButton.icon(
                      onPressed: () => ref.invalidate(priceBoundsProvider),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Price filter didn't load. Retry"),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    key: _resultsKey,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          selectedName,
                          style: textTheme.headlineMedium,
                        ),
                      ),
                      if (page != null && page.totalCount > 0)
                        Text(
                          '${filter.page * productsPerPage + 1}–'
                          '${filter.page * productsPerPage + page.items.length}'
                          ' of ${page.totalCount}',
                          style: textTheme.bodyMedium,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 4,
                    child: pageValue.isLoading && page != null
                        ? const LinearProgressIndicator()
                        : null,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          ...pageValue.when(
            skipLoadingOnReload: true,
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingView(),
              ),
            ],
            error: (error, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  message: describeError(error),
                  permissionDenied: isPermissionDenied(error),
                  onRetry: () => ref.invalidate(productPageProvider),
                ),
              ),
            ],
            data: (page) => page.items.isEmpty
                ? [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: MessageView(
                        icon: filter.favoritesOnly
                            ? Icons.favorite_border
                            : Icons.search_off,
                        title: filter.favoritesOnly
                            ? 'No favorites yet'
                            : 'No products found',
                        message: filter.favoritesOnly
                            ? 'Tap the heart on a product to save it here.'
                            : 'Try another search, category or price range.',
                      ),
                    ),
                  ]
                : [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      sliver: SliverOpacity(
                        opacity: pageValue.isLoading ? 0.5 : 1,
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 240,
                                mainAxisExtent: 300,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildCard(
                              page.items[index],
                              isAdmin,
                              favorites,
                            ),
                            childCount: page.items.length,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 96),
                      sliver: SliverToBoxAdapter(
                        child: PaginationBar(
                          page: filter.page,
                          totalPages: totalPages,
                          enabled: !pageValue.isLoading,
                          onPageSelected: _goToPage,
                        ),
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Product product, bool isAdmin, Set<int> favorites) {
    void open() => context.push('/product/${product.id}');
    if (isAdmin) {
      return ProductCard(
        product: product,
        onTap: open,
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit',
            onPressed: () => context.push('/admin/products/${product.id}/edit'),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete',
            color: Colors.red.shade600,
            onPressed: () => confirmAndDeleteProduct(context, ref, product),
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      );
    }
    return ProductCard(
      product: product,
      onTap: open,
      isFavorite: favorites.contains(product.id),
      onToggleFavorite: () =>
          ref.read(favoritesProvider.notifier).toggle(product.id),
      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: !product.inStock
              ? 'Out of stock'
              : product.hasColors
              ? 'Choose a color'
              : 'Add to cart',
          color: AppColors.hotPink,
          onPressed: !product.inStock
              ? null
              : product.hasColors
              ? open
              : () => addProductToCart(context, ref, product),
          icon: const Icon(Icons.add_shopping_cart, size: 20),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppColors.hotPink,
        backgroundColor: AppColors.lightPink,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textColor,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
