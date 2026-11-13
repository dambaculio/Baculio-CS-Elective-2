drop policy if exists "Public can insert products" on public.products;
drop policy if exists "Public can update products" on public.products;
drop policy if exists "Public can delete products" on public.products;
drop policy if exists "Signed-in users can insert products" on public.products;
drop policy if exists "Signed-in users can update products" on public.products;
drop policy if exists "Signed-in users can delete products" on public.products;

create policy "Signed-in users can insert products"
  on public.products for insert to authenticated
  with check (true);

create policy "Signed-in users can update products"
  on public.products for update to authenticated
  using (true) with check (true);

create policy "Signed-in users can delete products"
  on public.products for delete to authenticated
  using (true);

select policyname, cmd, roles from pg_policies where tablename = 'products';
