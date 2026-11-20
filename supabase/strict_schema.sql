drop table if exists public.order_item_colors;
drop table if exists public.product_colors;
drop function if exists public.set_product_colors(bigint, text[]);
drop table if exists public.products_legacy cascade;

alter table public.products drop column if exists colors;
alter table public.order_items drop column if exists color;
alter table public.order_items drop column if exists product_name;

delete from public.order_items where product_id is null;
alter table public.order_items alter column product_id set not null;
alter table public.order_items drop constraint if exists order_items_product_id_fkey;
alter table public.order_items
  add constraint order_items_product_id_fkey
  foreign key (product_id) references public.products (id);

alter table public.products alter column price drop not null;
alter table public.orders alter column status drop not null;
alter table public.orders alter column total drop not null;

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

    select id, name, price, stock
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
    if v_product.price is null then
      raise exception '"%" has no price yet.', v_product.name;
    end if;

    v_price := v_product.price::numeric(10, 2);

    insert into public.order_items (order_id, product_id, unit_price, quantity)
    values (v_order_id, v_product.id, v_price, v_line.quantity);

    update public.products
       set stock = stock - v_line.quantity
     where id = v_product.id;

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

select table_name, column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
order by table_name, ordinal_position;
