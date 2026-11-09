-- Shai's Creation: Supabase setup script
-- Run this once in Supabase Dashboard -> SQL Editor -> New query -> Run.

-- 1. Products table (mirrors lib/models/flower.dart)
create table if not exists public.products (
  id          text primary key,
  name        text not null,
  price       numeric(10,2) not null check (price >= 0),
  image_url   text not null,
  category    text not null default '',
  description text not null default '',
  slug        text not null default '',
  sort_order  int  not null default 0,
  created_at  timestamptz not null default now()
);

-- Indexes for the price filter and category filter
create index if not exists products_price_idx    on public.products (price);
create index if not exists products_category_idx on public.products (category);

-- 2. Row Level Security
-- With RLS on and no policies, the API returns nothing. The app has no
-- login, so these policies let the public (anon) key read and modify
-- products. Fine for a class activity; a real shop would restrict
-- insert/update/delete to authenticated admins.
alter table public.products enable row level security;

drop policy if exists "Public can read products"   on public.products;
drop policy if exists "Public can insert products" on public.products;
drop policy if exists "Public can update products" on public.products;
drop policy if exists "Public can delete products" on public.products;

create policy "Public can read products"   on public.products for select using (true);
create policy "Public can insert products" on public.products for insert with check (true);
create policy "Public can update products" on public.products for update using (true) with check (true);
create policy "Public can delete products" on public.products for delete using (true);

-- 3. Seed data (copied from lib/data/flower_data.dart).
-- image_url keeps the local asset path; ProductImage already loads
-- paths starting with 'assets/' via Image.asset.
insert into public.products (id, name, price, image_url, category, description, slug, sort_order) values
  ('flowers-babys-breath', 'Baby''s Breath', 399, 'assets/images/Flowers - Baby''s Breath.png', 'Flowers', 'Delicate crochet baby''s breath blossoms, perfect for adding soft volume or subtle elegance.', '', 1),
  ('flowers-cosmos', 'Cosmos', 399, 'assets/images/Flowers - Cosmos.png', 'Flowers', 'Vibrant handcrafted cosmos flower featuring vivid petals and a charming detailed center.', '', 2),
  ('flowers-daisy', 'Daisy', 399, 'assets/images/Flowers - Daisy.png', 'Flowers', 'Classic crochet white daisy with a bright yellow center, bringing cheerful meadow energy.', '', 3),
  ('flowers-lilies', 'Lilies', 449, 'assets/images/Flowers - Lilies.png', 'Flowers', 'Elegant crochet lily bloom with gracefully flared petals and rich, detailed craftsmanship.', '', 4),
  ('flowers-roses', 'Roses', 499, 'assets/images/Flowers - Roses.png', 'Flowers', 'Timeless handcrafted crochet rose with intricate layered petals symbolizing romance.', '', 5),
  ('flowers-sundrop', 'Sundrop', 399, 'assets/images/Flowers - Sundrop.png', 'Flowers', 'Bright, sun-kissed crochet bloom designed to add a warm pop of color to any stem collection.', '', 6),
  ('flowers-sunflower', 'Sunflower', 449, 'assets/images/Flowers - Sunflower.png', 'Flowers', 'Golden-yellow crochet sunflower with a rich textured brown center, bursting with warmth and positivity.', '', 7),
  ('bouquet-blush-appreciation', 'Blush Appreciation', 899, 'assets/images/Bouquet - Blush Appreciation.png', 'Bouquet', 'Soft pastel pinks, delicate crochet daisies, and mesh netting paired with a heartfelt note.', '', 8),
  ('bouquet-bunny-meadow', 'Bunny Meadow Bloom', 999, 'assets/images/Bouquet - Bunny Meadow Bloom.png', 'Bouquet', 'Charming white crochet bunny peeking out from a vibrant garden of hot pink blossoms, white daisies, and soft pink buds.', '', 9),
  ('bouquet-cottontail-meadow', 'Cottontail Meadow', 999, 'assets/images/Bouquet - Cottontail Meadow.png', 'Bouquet', 'Playful arrangement featuring pink tulip buds cradling a cute crochet bunny face right in the center.', '', 10),
  ('bouquet-golden-pastel', 'Golden Pastel Symphony', 1099, 'assets/images/Bouquet - Golden Pastel Symphony.png', 'Bouquet', 'Gold-trimmed pink paper framing a dreamy mix of tulips, lilies of the valley, and pastel daisies.', '', 11),
  ('bouquet-golden-sunshine', 'Golden Sunshine Grace', 1099, 'assets/images/Bouquet - Golden Sunshine Grace.png', 'Bouquet', 'Striking central sunflower flanked by soft pastel tulips, wrapped in elegant gold-trimmed white paper and finished with an oversized bow.', '', 12),
  ('bouquet-midnight-starlight', 'Midnight Starlight', 1199, 'assets/images/Bouquet - Midnight Starlight.png', 'Bouquet', 'Deep blue petals and delicate white lilies wrapped in starry, night-sky tulle and dark paper.', '', 13),
  ('bouquet-raspberry-romance', 'Raspberry Romance', 999, 'assets/images/Bouquet - Raspberry Romance.png', 'Bouquet', 'Bold crimson, magenta blossoms, and pink tulips wrapped to make a vibrant, passionate statement.', '', 14),
  ('bouquet-strawberries-cream', 'Strawberries & Cream', 999, 'assets/images/Bouquet - Strawberries & Cream.png', 'Bouquet', 'Crisp, pleated white layers contrasting sharply with warm pink tulips and cherry blossoms.', '', 15),
  ('bouquet-blooming-tote', 'The Blooming Tote', 899, 'assets/images/Bouquet - The Blooming Tote.png', 'Bouquet', 'A wearable bouquet bag woven into a thick cream tote completely covered in textured red and pink roses.', '', 16),
  ('bouquet-scholars-bloom', 'The Scholar''s Bloom', 899, 'assets/images/Bouquet - The Scholar''s Bloom.png', 'Bouquet', 'A cheerful sunflower, royal blue blossoms, and a tiny graduation cap, making it the perfect celebratory gift.', '', 17),
  ('flowers-tulip-touch', 'Tulip Touch', 799, 'assets/images/Flowers - Tulip Touch.png', 'Flowers', 'Elegant set of handcrafted crochet tulips in soft pink and white hues.', '', 18),
  ('wrappers-bouquet-wrapping-paper', 'Bouquet Wrapping Paper Sheets with Golden Edge', 49, 'assets/images/Wrappers - Bouquet Wrapping Paper Sheets with Golden Edge.png', 'Wrappers', 'Premium waterproof wrapping paper sheets featuring elegant golden borders to frame your bouquet.', '', 19),
  ('wrappers-honeycomb', 'Honeycomb Wrapper', 49, 'assets/images/Wrappers - Honeycomb Wrapper.png', 'Wrappers', 'Uniquely textured mesh wrapping paper that adds depth and modern flair to floral arrangements.', '', 20),
  ('wrappers-korean-spider-mesh', 'Korean Spider Mesh', 49, 'assets/images/Wrappers - Korean Spider Mesh.png', 'Wrappers', 'Lightweight, starry spiderweb mesh netting ideal for soft, cloud-like bouquet layers.', '', 21),
  ('wrappers-plain', 'Plain Wrappers', 39, 'assets/images/Wrappers - Plain Wrappers.png', 'Wrappers', 'Clean, versatile matte wrapping sheets designed to give bouquets a sleek, professional backing.', '', 22),
  ('wrappers-tissue-paper', 'Tissue Paper', 39, 'assets/images/Wrappers - Tissue Paper.png', 'Wrappers', 'Soft, foldable inner tissue paper for cushioning and adding volume inside bouquet wraps.', '', 23),
  ('ribbons-lace', 'Lace Ribbon', 30, 'assets/images/Ribbons - Lace Ribbon.png', 'Ribbons', 'Intricate, vintage-style lace ribbon ideal for adding delicate detail to bouquet stems and bows.', '', 24),
  ('ribbons-ribbon-with-text', 'Ribbon with Text', 35, 'assets/images/Ribbons - Ribbon with Text.png', 'Ribbons', 'Elegant printed ribbon featuring heartfelt messaging to personalize your floral gifts.', '', 25),
  ('ribbons-sattin', 'Sattin Ribbon', 25, 'assets/images/Ribbons - Sattin Ribbon.png', 'Ribbons', 'Smooth, glossy satin ribbon for tying perfect accent bows around wrapped bouquets.', '', 26)
on conflict (id) do update set
  name = excluded.name, price = excluded.price, image_url = excluded.image_url,
  category = excluded.category, description = excluded.description,
  slug = excluded.slug, sort_order = excluded.sort_order;

-- Check: should return 26
select count(*) from public.products;
