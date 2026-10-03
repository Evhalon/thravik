-- Foundation only: authentication proves account ownership, not trusted device membership.
create schema if not exists redent_private;
revoke all on schema redent_private from public, anon, authenticated;

create table redent_private.sync_accounts (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  cursor bigint not null default 0 check (cursor >= 0)
);
create table public.sync_records (
  owner_id uuid not null references auth.users(id) on delete cascade,
  collection text not null,
  record_id uuid not null,
  revision bigint not null check (revision > 0),
  cursor bigint not null check (cursor > 0),
  encrypted_payload text not null,
  deleted boolean not null,
  primary key (owner_id, collection, record_id)
);
create table public.sync_changes (
  mutation_id uuid not null,
  expected_revision bigint not null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  cursor bigint not null,
  collection text not null,
  record_id uuid not null,
  revision bigint not null,
  encrypted_payload text not null,
  deleted boolean not null,
  primary key (owner_id, cursor)
);
create table redent_private.sync_mutations (
  owner_id uuid not null references auth.users(id) on delete cascade,
  mutation_id uuid not null,
  request jsonb not null,
  result jsonb not null,
  primary key (owner_id, mutation_id)
);

alter table redent_private.sync_accounts enable row level security;
alter table redent_private.sync_mutations enable row level security;
alter table public.sync_records enable row level security;
alter table public.sync_changes enable row level security;
create policy own_records on public.sync_records for select to authenticated
  using (owner_id = (select auth.uid()));
create policy own_changes on public.sync_changes for select to authenticated
  using (owner_id = (select auth.uid()));
revoke all on public.sync_records, public.sync_changes from public, anon, authenticated;
revoke all on redent_private.sync_accounts, redent_private.sync_mutations from public, anon, authenticated;
grant select on public.sync_records, public.sync_changes to authenticated;

create function public.sync_push(request jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  account_id uuid := auth.uid();
  incoming_mutation_id uuid;
  target_id uuid;
  expected bigint;
  current_revision bigint;
  next_cursor bigint;
  prior redent_private.sync_mutations%rowtype;
  result jsonb;
  encrypted_payload text;
  target_collection text;
  tombstone boolean;
begin
  if account_id is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  if request is null or jsonb_typeof(request) <> 'object' or octet_length(request::text) > 262144 then
    raise exception using errcode = '22023', message = 'invalid_request';
  end if;
  incoming_mutation_id := (request->>'mutation_id')::uuid;
  target_id := (request->>'record_id')::uuid;
  expected := (request->>'expected_revision')::bigint;
  encrypted_payload := request->>'encrypted_payload';
  target_collection := request->>'collection';
  tombstone := (request->>'deleted')::boolean;
  if incoming_mutation_id is null or target_id is null or expected is null or expected < 0 or tombstone is null
    or target_collection is null or target_collection !~ '^[a-z0-9_]{1,32}$'
    or encrypted_payload is null or jsonb_typeof(request->'encrypted_payload') <> 'string'
    or length(encrypted_payload) < 40 or length(encrypted_payload) > 262144
    or encrypted_payload !~ '^[A-Za-z0-9+/]+={0,2}$'
    or request - array['mutation_id', 'collection', 'record_id', 'expected_revision', 'encrypted_payload', 'deleted'] <> '{}'::jsonb then
    raise exception using errcode = '22023', message = 'invalid_request';
  end if;
  insert into redent_private.sync_accounts(owner_id) values(account_id) on conflict do nothing;
  -- Lock retained until commit: a later cursor cannot commit ahead of an earlier one.
  perform 1 from redent_private.sync_accounts where owner_id = account_id for update;
  select * into prior from redent_private.sync_mutations m where m.owner_id = account_id and m.mutation_id = incoming_mutation_id;
  if found then
    if prior.request <> request then raise exception using errcode = '22023', message = 'mutation_payload_mismatch'; end if;
    return prior.result;
  end if;
  select revision into current_revision from public.sync_records where owner_id = account_id and collection = target_collection and record_id = target_id;
  current_revision := coalesce(current_revision, 0);
  if current_revision <> expected then
    return jsonb_build_object('status', 'conflict', 'revision', current_revision);
  end if;
  if (select cursor from redent_private.sync_accounts where owner_id = account_id) >= 10000 then
    raise exception using errcode = '54000', message = 'foundation_quota_reached';
  end if;
  update redent_private.sync_accounts set cursor = cursor + 1 where owner_id = account_id returning cursor into next_cursor;
  insert into public.sync_records values(account_id, target_collection, target_id, current_revision + 1, next_cursor, encrypted_payload, tombstone)
    on conflict (owner_id, collection, record_id) do update set revision = excluded.revision, cursor = excluded.cursor,
      encrypted_payload = excluded.encrypted_payload, deleted = excluded.deleted;
  insert into public.sync_changes values(incoming_mutation_id, expected, account_id, next_cursor, target_collection, target_id, current_revision + 1, encrypted_payload, tombstone);
  result := request || jsonb_build_object('status', 'accepted', 'revision', current_revision + 1, 'cursor', next_cursor);
  insert into redent_private.sync_mutations values(account_id, incoming_mutation_id, request, result);
  return result;
end;
$$;

create function public.sync_pull(after_cursor bigint default 0, page_size integer default 100)
returns setof public.sync_changes language plpgsql security invoker set search_path = '' as $$
begin
  if auth.uid() is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  if after_cursor is null or after_cursor < 0 or page_size is null or page_size < 1 then
    raise exception using errcode = '22023', message = 'invalid_cursor';
  end if;
  return query select * from public.sync_changes where owner_id = auth.uid() and cursor > after_cursor
    order by cursor limit least(page_size, 100);
end;
$$;
revoke all on function public.sync_push(jsonb), public.sync_pull(bigint, integer) from public, anon;
grant execute on function public.sync_push(jsonb), public.sync_pull(bigint, integer) to authenticated;
