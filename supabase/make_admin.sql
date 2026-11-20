update public.profiles
set role_id = (select id from public.roles where role = 'admin')
where email = 'admin@example.com';

select p.email, r.role
from public.profiles p
join public.roles r on r.id = p.role_id
order by r.role, p.email;
