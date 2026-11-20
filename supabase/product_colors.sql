do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'products'
      and column_name = 'colors'
  ) then
    alter table public.products
      add column colors text[] not null default '{}';
    alter table public.products
      add constraint products_colors_allowed check (
        colors <@ array['White', 'Cream', 'Pink', 'Red', 'Orange',
                        'Yellow', 'Green', 'Blue', 'Purple', 'Black']::text[]
      );
    update public.products p
       set colors = array['White', 'Pink', 'Blue', 'Red', 'Yellow', 'Green']
      from public.categories c
     where c.id = p.category_id
       and c.name in ('Flowers', 'Wrappers', 'Ribbons');
  end if;
end $$;

alter table public.order_items add column if not exists color text;

create or replace function public.place_order(p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user     uuid := auth.uid();
  v_order_id bigint;
  v_total    numeric(12, 2) := 0;
  v_line     record;
  v_product  record;
  v_price    numeric(10, 2);
begin
  if v_user is null then
    raise exception 'You must be signed in to place an order.' using errcode = '42501';
  end if;
  if public.is_admin() then
    raise exception 'Admin accounts cannot place orders.' using errcode = '42501';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Your cart is empty.';
  end if;

  insert into public.orders (user_id, status, total)
  values (v_user, 'pending', 0)
  returning id into v_order_id;

  for v_line in
    select (e ->> 'product_id')::bigint as product_id,
           sum((e ->> 'quantity')::int)  as quantity,
           bool_or(coalesce((e ->> 'quantity')::int, 0) <= 0) as has_bad_quantity
    from jsonb_array_elements(p_items) as e
    group by 1
    order by 1
  loop
    if v_line.has_bad_quantity then
      raise exception 'Quantities must be at least 1.';
    end if;

    select id, name, stock
      into v_product
      from public.products
     where id = v_line.product_id
       for update;

    if not found then
      raise exception 'A product in your cart is no longer available.';
    end if;
    if v_product.stock < v_line.quantity then
      raise exception '"%" only has % left in stock.', v_product.name, v_product.stock;
    end if;

    update public.products
       set stock = stock - v_line.quantity
     where id = v_product.id;
  end loop;

  for v_line in
    select (e ->> 'product_id')::bigint      as product_id,
           nullif(trim(e ->> 'color'), '')   as color,
           sum((e ->> 'quantity')::int)      as quantity
    from jsonb_array_elements(p_items) as e
    group by 1, 2
    order by 1, 2
  loop
    select id, name, price, colors
      into v_product
      from public.products
     where id = v_line.product_id;

    if cardinality(v_product.colors) > 0 then
      if v_line.color is null then
        raise exception 'Choose a color for "%".', v_product.name;
      end if;
      if not (v_line.color = any (v_product.colors)) then
        raise exception '"%" is not available in %.', v_product.name, v_line.color;
      end if;
    elsif v_line.color is not null then
      raise exception '"%" has no color options.', v_product.name;
    end if;

    v_price := v_product.price::numeric(10, 2);

    insert into public.order_items
      (order_id, product_id, product_name, color, unit_price, quantity)
    values
      (v_order_id, v_product.id, v_product.name, v_line.color, v_price, v_line.quantity);

    v_total := v_total + v_price * v_line.quantity;
  end loop;

  update public.orders
     set total = v_total, status = 'done'
   where id = v_order_id;

  return jsonb_build_object('order_id', v_order_id, 'total', v_total);
end;
$$;

revoke all on function public.place_order(jsonb) from public, anon;
grant execute on function public.place_order(jsonb) to authenticated;

select name, colors from public.products order by id;
