-- MAGIZH POS: initial multi-tenant foundation.
-- Apply only to a NEW Supabase project after reviewing this migration.
-- All business data is tenant-scoped. Never disable RLS in production.

create extension if not exists pgcrypto;

create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null,
  display_name text not null,
  business_type text not null default 'cafe',
  owner_email text,
  owner_phone text,
  gst_registered boolean not null default false,
  gstin text,
  status text not null default 'pending' check (status in ('pending','active','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  branch_code text not null,
  name text not null,
  address text,
  phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (business_id, branch_code),
  unique (business_id, id)
);

create table if not exists public.business_memberships (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  user_id uuid not null references auth.users(id),
  role text not null check (role in ('owner','manager','cashier')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (business_id, user_id)
);

create table if not exists public.user_branch_access (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  branch_id uuid not null,
  user_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (business_id, branch_id) references public.branches(business_id, id),
  unique (branch_id, user_id)
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name text not null,
  product_type text not null check (product_type in ('prepared_food','retail')),
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (business_id, id)
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  category_id uuid,
  product_type text not null check (product_type in ('prepared_food','retail')),
  sku text,
  name text not null,
  unit text not null default 'unit',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  foreign key (business_id, category_id) references public.categories(business_id, id),
  unique (business_id, id)
);

create unique index if not exists products_business_sku_unique
  on public.products(business_id, sku) where sku is not null;

create table if not exists public.product_branch_settings (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null,
  branch_id uuid not null,
  product_id uuid not null,
  selling_price numeric(12,2) not null check (selling_price >= 0),
  is_available boolean not null default true,
  reorder_level numeric(14,3),
  foreign key (business_id, branch_id) references public.branches(business_id, id),
  foreign key (business_id, product_id) references public.products(business_id, id),
  unique (branch_id, product_id)
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name text,
  mobile text,
  email text,
  created_at timestamptz not null default now(),
  unique (business_id, id)
);
create index if not exists customers_business_mobile_idx on public.customers(business_id, mobile);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null,
  branch_id uuid not null,
  invoice_number text not null,
  customer_id uuid,
  cashier_user_id uuid not null references auth.users(id),
  subtotal numeric(12,2) not null check (subtotal >= 0),
  discount_total numeric(12,2) not null default 0 check (discount_total >= 0),
  tax_total numeric(12,2) not null default 0 check (tax_total >= 0),
  grand_total numeric(12,2) not null check (grand_total >= 0),
  payment_status text not null default 'pending' check (payment_status in ('pending','confirmed','refunded','partially_refunded','voided')),
  finalized_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (business_id, branch_id) references public.branches(business_id, id),
  foreign key (business_id, customer_id) references public.customers(business_id, id),
  unique (branch_id, invoice_number),
  unique (business_id, id)
);

create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null,
  invoice_id uuid not null,
  product_id uuid,
  item_name_snapshot text not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  discount_amount numeric(12,2) not null default 0,
  tax_amount numeric(12,2) not null default 0,
  line_total numeric(12,2) not null check (line_total >= 0),
  foreign key (business_id, invoice_id) references public.invoices(business_id, id),
  foreign key (business_id, product_id) references public.products(business_id, id)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null,
  invoice_id uuid not null,
  method text not null check (method in ('cash','upi')),
  amount numeric(12,2) not null check (amount > 0),
  status text not null default 'pending' check (status in ('pending','confirmed','failed','refunded')),
  upi_reference text,
  confirmed_by uuid references auth.users(id),
  confirmed_at timestamptz,
  idempotency_key text not null,
  created_at timestamptz not null default now(),
  foreign key (business_id, invoice_id) references public.invoices(business_id, id),
  unique (business_id, idempotency_key)
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.businesses(id),
  branch_id uuid references public.branches(id),
  actor_user_id uuid references auth.users(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists invoices_business_branch_created_idx
  on public.invoices(business_id, branch_id, created_at desc);
create index if not exists invoice_items_invoice_idx on public.invoice_items(invoice_id);
create index if not exists payments_invoice_idx on public.payments(invoice_id);

-- Security helper functions. SECURITY DEFINER functions use a fixed search_path.
create or replace function public.is_business_member(target_business uuid)
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.business_memberships m
    where m.business_id = target_business
      and m.user_id = auth.uid()
      and m.is_active = true
  );
$$;

create or replace function public.has_branch_access(target_business uuid, target_branch uuid)
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.business_memberships m
    where m.business_id = target_business
      and m.user_id = auth.uid()
      and m.role = 'owner' and m.is_active = true
  ) or exists (
    select 1 from public.user_branch_access a
    where a.business_id = target_business
      and a.branch_id = target_branch
      and a.user_id = auth.uid()
  );
$$;

alter table public.businesses enable row level security;
alter table public.branches enable row level security;
alter table public.business_memberships enable row level security;
alter table public.user_branch_access enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_branch_settings enable row level security;
alter table public.customers enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.payments enable row level security;
alter table public.audit_logs enable row level security;

-- Initial read policies only. Writes must be implemented through validated server-side
-- RPC/Edge Function workflows; do not add broad client-side write policies.
create policy "members read own business" on public.businesses
for select to authenticated using (public.is_business_member(id));

create policy "members read own branches" on public.branches
for select to authenticated using (public.is_business_member(business_id));

create policy "members read own memberships" on public.business_memberships
for select to authenticated using (user_id = auth.uid() or public.is_business_member(business_id));

create policy "members read branch access" on public.user_branch_access
for select to authenticated using (user_id = auth.uid() or public.is_business_member(business_id));

create policy "members read own categories" on public.categories
for select to authenticated using (public.is_business_member(business_id));

create policy "members read own products" on public.products
for select to authenticated using (public.is_business_member(business_id));

create policy "members read own branch product settings" on public.product_branch_settings
for select to authenticated using (public.has_branch_access(business_id, branch_id));

create policy "members read own customers" on public.customers
for select to authenticated using (public.is_business_member(business_id));

create policy "authorized users read invoices" on public.invoices
for select to authenticated using (public.has_branch_access(business_id, branch_id));

create policy "authorized users read invoice items" on public.invoice_items
for select to authenticated using (
  exists (select 1 from public.invoices i
    where i.id = invoice_id and i.business_id = business_id
      and public.has_branch_access(i.business_id, i.branch_id))
);

create policy "authorized users read payments" on public.payments
for select to authenticated using (
  exists (select 1 from public.invoices i
    where i.id = invoice_id and i.business_id = business_id
      and public.has_branch_access(i.business_id, i.branch_id))
);

create policy "members read audit logs" on public.audit_logs
for select to authenticated using (
  business_id is not null and public.is_business_member(business_id)
);

-- Important: this is a foundation migration, not a complete production authorization model.
-- Add explicit owner/manager/cashier permissions and server-validated write RPCs before live use.
