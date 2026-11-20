# Shai's Creation — E-Commerce App (Final Project)

A Flutter shop for handmade crochet flowers and bouquets with two roles:
**admins** manage the catalog and orders, **customers** browse, build a cart,
check out and review their orders.

| Area | Used |
|---|---|
| State management | Riverpod 3 (`Notifier`, `AsyncNotifier`-style `FutureProvider`s) |
| Backend | Supabase Auth, Postgres, Row Level Security, Storage |
| Sign-in | Email + password, Google |
| Images | Supabase Storage bucket `product-images` |

## Setup

1. **Database** – Supabase Dashboard → SQL Editor → run `supabase/final_project.sql`.
   It creates the six tables from the required schema, the `handle_new_user`,
   `is_admin` and `place_order` functions, every RLS policy, the storage bucket
   and seed data.
2. **Google sign-in** – create an OAuth client in Google Cloud Console and
   paste its Client ID/Secret in Supabase → Authentication → Sign In / Providers → Google.
3. **Redirect URLs** – Supabase → Authentication → URL Configuration must list
   `io.supabase.shaiscreation://login-callback/` (and your web URL if deployed).
   If your database was created with an earlier version of the script, run
   `supabase/strict_schema.sql` once. It removes everything that is not in the
   required schema.
4. **First admin** – sign up in the app, then run `supabase/make_admin.sql`
   with that email. Every new account starts as a customer.
5. `flutter pub get` → `flutter run`.

## Roles

| Capability | Signed out | Customer | Admin |
|---|---|---|---|
| Sign up / log in (email or Google) | ✓ | – | – |
| View products and categories | ✗ | ✓ | ✓ |
| Add / edit / delete products | ✗ | ✗ | ✓ |
| Manage categories | ✗ | ✗ | ✓ |
| Cart, place order, own order history | ✗ | ✓ | ✗ |
| View all orders, update status | ✗ | ✗ | ✓ |

## Security: why hiding a button is not security

The app hides admin controls from customers, but that only changes what is
drawn on screen. Anyone holding the public key could call the Supabase API
directly. The real protection is in Postgres:

- **RLS on every table** (`profiles`, `roles`, `categories`, `products`,
  `orders`, `order_items`) with policies matching the permission table. No
  policy exists for `anon`, so signed-out requests get nothing.
- **`is_admin()`** decides admin-only writes. It is `security definer` so it
  can read `profiles` without triggering the profiles policies again.
- **Column privileges**: customers can only update their own `firstname` /
  `lastname` (never `role_id`); admins can only change an order's `status`.
- **Checkout integrity**: customers cannot insert orders directly.
  `place_order()` runs in one transaction. It reads names, prices and stock
  from the database, locks the product rows, rejects quantities above stock,
  saves the order and its items (with the unit price paid),
  reduces stock, and sets the status to `done`. If anything fails, nothing is saved.
- **Storage**: only admins can upload or change product images.
- **Order history**: `order_items.product_id` is required, so a product that
  appears in past orders cannot be deleted (set its stock to 0 instead).

## Architecture

```
lib/
  models/      plain data classes (Product, ProductCategory, ShopOrder, Profile, CartItem)
  services/    the only code that talks to Supabase
  providers/   Riverpod providers that call services and hold app state
  screens/     pages, which only read providers
    auth/        login, sign up
    shop/        product list and product page (both roles)
    customer/    cart, order confirmation, order history
    admin/       product form, all orders, categories
  widgets/     reusable UI (cards, async/loading/error/empty views, dialogs)
  utils/       error messages and formatting
supabase/
  final_project.sql   schema, functions, RLS, storage, seed
  strict_schema.sql   one-time cleanup for databases made with older scripts
  make_admin.sql      promote an account to admin
  legacy/             SQL from earlier activities
```

Screens → providers → services → Supabase. Every async provider's loading,
error (including permission denied) and data states are handled in the UI
through `AsyncValueView` and the shared state views.

## Credits

Google and GitHub marks: Simple Icons (CC0) and GitHub Octicons (MIT).
