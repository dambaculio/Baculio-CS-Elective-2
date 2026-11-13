# Shai's Creation

## Supabase Auth (branch `backend-auth`)

Users must log in before shopping. Two sign-in options:

- **Email + password** (Supabase email provider): Log In / Sign Up tabs on
  `lib/screens/auth_screen.dart`, with email confirmation support.
- **GitHub** (additional third-party provider): `signInWithOAuth(OAuthProvider.github)`
  opens GitHub in the browser; Supabase redirects back to the app through the
  deep link `io.supabase.shaiscreation://login-callback/`.

How it fits together:

- `lib/providers/auth_provider.dart` listens to the `onAuthStateChange`
  stream and notifies the app on every login/logout.
- `lib/main.dart`: go_router `redirect` + `refreshListenable` guard every
  route, so signed-out users land on `/login` and signed-in users skip it.
- Account menu (top bar) shows the user and sign-in method, plus Sign Out.
- `supabase/auth_policies.sql`: RLS now lets only `authenticated` users
  insert/update/delete products; browsing stays public.
- Deep link registered in `AndroidManifest.xml`, `ios/Runner/Info.plist` and
  `macos/Runner/Info.plist`. On the web, login returns to the current site.
- GitHub icon: `mark-github` from GitHub's Octicons (MIT license).

## Supabase Backend (branch `backend-filter-pagination`)

Products are stored in a Supabase Postgres table instead of a hard-coded list.

- **Setup:** run `supabase/setup.sql` in the Supabase SQL Editor (creates the
  `products` table, RLS policies and 26 seed products), then put your project
  URL and anon/publishable key in `lib/config/supabase_config.dart`.
- **State management:** `provider` with a `ChangeNotifier`
  (`lib/providers/product_provider.dart`) holds the filters, price range and
  current page. Every change triggers one Supabase query built in
  `lib/services/product_service.dart`.
- **Filtering:** category (`.eq`), search (`.ilike`), favorites (`.inFilter`),
  sort (`.order`).
- **Price filter:** a `RangeSlider` on the home screen; the query uses
  `.gte('price', min).lte('price', max)`.
- **Pagination:** 6 products per page with `.range(from, to)` and
  `.count(CountOption.exact)` for the total, with Prev / page numbers / Next.
- **Update & delete:** on the product detail page (Edit / Delete buttons),
  using `.update(...).eq('id', id)` and `.delete().eq('id', id)`.

## Add Product Images

1. In the project root, create this folder:

   `assets/images/`

2. Copy your image files into that folder, for example:

   ```text
   assets/images/rose.jpg
   assets/images/sunflower.jpg
   assets/images/tulip.jpg
   ```

3. The `pubspec.yaml` file registers the whole folder:

   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/images/
   ```

   Keep the indentation exactly as shown. Run `flutter pub get` after changing
   `pubspec.yaml`.

4. Reference an image by its path in `lib/data/flower_data.dart`:

   ```dart
   Flower(
     id: '22',
     name: 'Rose Garden',
     price: 699,
     imageUrl: 'assets/images/rose.jpg',
     category: 'Flowers',
   ),
   ```

5. The reusable `ProductImage` widget detects paths beginning with `assets/`
   and loads them with the equivalent Flutter API:

   ```dart
   Image.asset('assets/images/rose.jpg')
   ```

You can also use `Image.asset` directly in any widget. File names and paths are
case-sensitive, so the spelling must match the file exactly.
