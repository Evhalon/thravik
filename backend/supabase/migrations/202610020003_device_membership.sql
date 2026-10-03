-- Device membership. Login proves the account; an approved device credential proves the writer.
-- The server stores only a hash of that credential. Ed25519 signatures are checked by clients before apply.
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table redent_private.sync_devices (
  owner_id uuid not null references auth.users(id) on delete cascade,
  device_id uuid not null,
  agreement_public_key text not null,
  signing_public_key text not null,
  credential_hash text not null,
  status text not null check (status in ('pending', 'approved', 'revoked')),
  expires_at timestamptz,
  primary key (owner_id, device_id),
  check (
    (status = 'pending' and expires_at is not null and credential_hash ~ '^[0-9a-f]{64}$')
    or (status = 'approved' and expires_at is null and credential_hash ~ '^[0-9a-f]{64}$')
    or (status = 'revoked' and credential_hash = '')
  )
);
create table redent_private.sync_device_envelopes (
  owner_id uuid not null references auth.users(id) on delete cascade,
  recipient_device_id uuid not null,
  sender_device_id uuid not null,
  request_id uuid not null,
  expires_at timestamptz not null,
  key_epoch bigint not null check (key_epoch > 0),
  nonce text not null,
  ciphertext text not null,
  authentication_tag text not null,
  signature text not null,
  primary key (owner_id, recipient_device_id)
);
create table redent_private.sync_recovery_claims (
  account_id uuid primary key references auth.users(id) on delete cascade,
  claim_hash text not null check (claim_hash ~ '^[0-9a-f]{64}$')
);
alter table public.sync_changes add column if not exists signer_device_id uuid;
alter table public.sync_changes add column if not exists signature text;
alter table redent_private.sync_devices enable row level security;
alter table redent_private.sync_device_envelopes enable row level security;
alter table redent_private.sync_recovery_claims enable row level security;
revoke all on redent_private.sync_devices, redent_private.sync_device_envelopes, redent_private.sync_recovery_claims
  from public, anon, authenticated;

create function redent_private.sha256_hex(raw bytea) returns text
language sql immutable strict set search_path = '' as $$
  select encode(extensions.digest(raw, 'sha256'), 'hex');
$$;

create function redent_private.base64_bytes(value text, expected integer) returns bytea
language plpgsql immutable set search_path = '' as $$
declare decoded bytea;
begin
  if value is null or value !~ '^[A-Za-z0-9+/]+={0,2}$' then
    raise exception using errcode = '22023', message = 'invalid_request';
  end if;
  decoded := decode(value, 'base64');
  if octet_length(decoded) <> expected then
    raise exception using errcode = '22023', message = 'invalid_request';
  end if;
  return decoded;
end $$;

create function redent_private.parse_device(device jsonb, timed boolean)
returns table(device_id uuid, agreement text, signing text, credential_hash text, expires_at timestamptz)
language plpgsql stable set search_path = '' as $$
declare allowed text[]; expiry bigint; parsed uuid;
begin
  allowed := array['device_id', 'agreement_public_key', 'signing_public_key', 'credential'];
  if timed then allowed := allowed || array['expires_at']; end if;
  if device is null or jsonb_typeof(device) <> 'object' or device - allowed <> '{}'::jsonb
     or (timed and device->>'expires_at' is null) then
    raise exception using errcode = '22023', message = 'invalid_request';
  end if;
  begin
    parsed := (device->>'device_id')::uuid;
  exception when invalid_text_representation then
    raise exception using errcode = '22023', message = 'invalid_request';
  end;
  perform redent_private.base64_bytes(device->>'agreement_public_key', 32);
  perform redent_private.base64_bytes(device->>'signing_public_key', 32);
  device_id := parsed;
  agreement := device->>'agreement_public_key';
  signing := device->>'signing_public_key';
  credential_hash := redent_private.sha256_hex(redent_private.base64_bytes(device->>'credential', 32));
  if timed then
    begin
      expiry := (device->>'expires_at')::bigint;
    exception when others then
      raise exception using errcode = '22023', message = 'invalid_request';
    end;
    if expiry <= extract(epoch from now())::bigint or expiry > extract(epoch from now())::bigint + 3600 then
      raise exception using errcode = '42501', message = 'device_expired';
    end if;
    expires_at := to_timestamp(expiry);
  end if;
  return next;
end $$;

create function redent_private.lock_account(account_id uuid) returns void
language plpgsql set search_path = '' as $$
begin
  insert into redent_private.sync_accounts(owner_id) values (account_id) on conflict do nothing;
  perform 1 from redent_private.sync_accounts where owner_id = account_id for update;
end $$;

create function public.sync_device_bootstrap(device jsonb) returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  account_id uuid := auth.uid();
  parsed record;
  existing redent_private.sync_devices%rowtype;
begin
  if account_id is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  select * into parsed from redent_private.parse_device(device, false);
  perform redent_private.lock_account(account_id);
  select * into existing from redent_private.sync_devices where owner_id = account_id and device_id = parsed.device_id;
  if found and existing.status = 'approved' and existing.agreement_public_key = parsed.agreement
     and existing.signing_public_key = parsed.signing and existing.credential_hash = parsed.credential_hash then
    return true;
  end if;
  if found then raise exception using errcode = '42501', message = 'device_rejected'; end if;
  if exists (select 1 from redent_private.sync_devices where owner_id = account_id and status = 'approved') then
    raise exception using errcode = '42501', message = 'device_already_registered';
  end if;
  insert into redent_private.sync_devices values
    (account_id, parsed.device_id, parsed.agreement, parsed.signing, parsed.credential_hash, 'approved', null);
  return true;
end $$;

create function public.sync_device_enroll(device jsonb) returns boolean
language plpgsql security definer set search_path = '' as $$
declare account_id uuid := auth.uid(); parsed record; existing redent_private.sync_devices%rowtype;
begin
  if account_id is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  select * into parsed from redent_private.parse_device(device, true);
  perform redent_private.lock_account(account_id);
  if not exists (select 1 from redent_private.sync_devices where owner_id = account_id and status = 'approved') then
    raise exception using errcode = '42501', message = 'device_authentication_required';
  end if;
  select * into existing from redent_private.sync_devices where owner_id = account_id and device_id = parsed.device_id;
  if found and (existing.status = 'revoked' or existing.credential_hash <> parsed.credential_hash
                or existing.agreement_public_key <> parsed.agreement or existing.signing_public_key <> parsed.signing) then
    raise exception using errcode = '42501', message = 'device_rejected';
  end if;
  if found and existing.status = 'approved' then return true; end if;
  insert into redent_private.sync_devices values
    (account_id, parsed.device_id, parsed.agreement, parsed.signing, parsed.credential_hash, 'pending', parsed.expires_at)
  on conflict (owner_id, device_id) do update set expires_at = excluded.expires_at, status = 'pending';
  return true;
end $$;

create function public.sync_device_list() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare account_id uuid := auth.uid(); result jsonb;
begin
  if account_id is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'device_id', device_id, 'agreement_public_key', agreement_public_key,
    'signing_public_key', signing_public_key, 'status', status,
    'expires_at', floor(extract(epoch from expires_at))::bigint) order by device_id), '[]'::jsonb)
  into result from redent_private.sync_devices where owner_id = account_id;
  return result;
end $$;

create function public.sync_device_approve(request jsonb) returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  account_id uuid := auth.uid();
  approver redent_private.sync_devices%rowtype;
  recipient redent_private.sync_devices%rowtype;
  existing redent_private.sync_device_envelopes%rowtype;
  expiry bigint;
  approver_id uuid;
  recipient_id uuid;
  request_id uuid;
begin
  if account_id is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  if request is null or jsonb_typeof(request) <> 'object' or request - array[
    'approver_device_id', 'approver_credential', 'sender_device_id', 'recipient_device_id', 'request_id',
    'expires_at', 'key_epoch', 'nonce', 'ciphertext', 'authentication_tag', 'signature'] <> '{}'::jsonb then
    raise exception using errcode = '22023', message = 'invalid_request';
  end if;
  begin
    approver_id := (request->>'approver_device_id')::uuid;
    recipient_id := (request->>'recipient_device_id')::uuid;
    request_id := (request->>'request_id')::uuid;
    expiry := (request->>'expires_at')::bigint;
    if request->>'key_epoch' is null or (request->>'key_epoch')::bigint <= 0
       or (request->>'sender_device_id')::uuid <> approver_id or approver_id = recipient_id then
      raise exception using errcode = '22023', message = 'invalid_request';
    end if;
  exception when invalid_text_representation or numeric_value_out_of_range then
    raise exception using errcode = '22023', message = 'invalid_request';
  end;
  perform redent_private.base64_bytes(request->>'nonce', 12);
  perform redent_private.base64_bytes(request->>'ciphertext', 32);
  perform redent_private.base64_bytes(request->>'authentication_tag', 16);
  perform redent_private.base64_bytes(request->>'signature', 64);
  if expiry <= extract(epoch from now())::bigint or expiry > extract(epoch from now())::bigint + 3600 then
    raise exception using errcode = '42501', message = 'device_expired';
  end if;
  perform redent_private.lock_account(account_id);
  select * into approver from redent_private.sync_devices where owner_id = account_id and device_id = approver_id;
  if not found or approver.status <> 'approved'
     or approver.credential_hash <> redent_private.sha256_hex(redent_private.base64_bytes(request->>'approver_credential', 32)) then
    raise exception using errcode = '42501', message = 'device_rejected';
  end if;
  select * into existing from redent_private.sync_device_envelopes
    where owner_id = account_id and recipient_device_id = recipient_id;
  if found then
    if existing.sender_device_id = approver_id and existing.request_id = request_id
       and existing.nonce = request->>'nonce' and existing.ciphertext = request->>'ciphertext'
       and existing.authentication_tag = request->>'authentication_tag' and existing.signature = request->>'signature' then
      return true;
    end if;
    raise exception using errcode = '42501', message = 'device_rejected';
  end if;
  select * into recipient from redent_private.sync_devices where owner_id = account_id and device_id = recipient_id;
  if not found or recipient.status <> 'pending' or recipient.expires_at <= now() then
    raise exception using errcode = '42501', message = 'device_expired';
  end if;
  insert into redent_private.sync_device_envelopes values
    (account_id, recipient_id, approver_id, request_id, to_timestamp(expiry), (request->>'key_epoch')::bigint,
     request->>'nonce', request->>'ciphertext', request->>'authentication_tag', request->>'signature');
  update redent_private.sync_devices set status = 'approved', expires_at = null
    where owner_id = account_id and device_id = recipient_id;
  return true;
end $$;

create function public.sync_device_envelope(device_id uuid, credential text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare account_id uuid := auth.uid(); device redent_private.sync_devices%rowtype; envelope redent_private.sync_device_envelopes%rowtype;
begin
  if account_id is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  select * into device from redent_private.sync_devices devices
    where devices.owner_id = account_id and devices.device_id = sync_device_envelope.device_id;
  if not found or device.credential_hash <> redent_private.sha256_hex(redent_private.base64_bytes(credential, 32)) then
    raise exception using errcode = '42501', message = 'device_rejected';
  end if;
  select * into envelope from redent_private.sync_device_envelopes stored
    where stored.owner_id = account_id and stored.recipient_device_id = sync_device_envelope.device_id;
  if not found then return null; end if;
  return jsonb_build_object(
    'sender_device_id', envelope.sender_device_id, 'recipient_device_id', envelope.recipient_device_id,
    'request_id', envelope.request_id, 'expires_at', floor(extract(epoch from envelope.expires_at))::bigint,
    'key_epoch', envelope.key_epoch, 'nonce', envelope.nonce, 'ciphertext', envelope.ciphertext,
    'authentication_tag', envelope.authentication_tag, 'signature', envelope.signature);
end $$;

create function public.sync_device_revoke(request jsonb) returns boolean
language plpgsql security definer set search_path = '' as $$
declare account_id uuid := auth.uid(); approver redent_private.sync_devices%rowtype; target uuid; approver_id uuid;
begin
  if account_id is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  if request is null or jsonb_typeof(request) <> 'object'
     or request - array['device_id', 'approver_device_id', 'approver_credential'] <> '{}'::jsonb then
    raise exception using errcode = '22023', message = 'invalid_request';
  end if;
  begin
    target := (request->>'device_id')::uuid;
    approver_id := (request->>'approver_device_id')::uuid;
  exception when invalid_text_representation then
    raise exception using errcode = '22023', message = 'invalid_request';
  end;
  perform redent_private.lock_account(account_id);
  select * into approver from redent_private.sync_devices where owner_id = account_id and device_id = approver_id;
  if not found or approver.status <> 'approved'
     or approver.credential_hash <> redent_private.sha256_hex(redent_private.base64_bytes(request->>'approver_credential', 32)) then
    raise exception using errcode = '42501', message = 'device_rejected';
  end if;
  if not exists (select 1 from redent_private.sync_devices where owner_id = account_id and device_id = target and status <> 'revoked') then
    raise exception using errcode = '42501', message = 'device_rejected';
  end if;
  if (select count(*) from redent_private.sync_devices where owner_id = account_id and status = 'approved') < 2
     and exists (select 1 from redent_private.sync_devices where owner_id = account_id and device_id = target and status = 'approved') then
    raise exception using errcode = '42501', message = 'device_rejected';
  end if;
  update redent_private.sync_devices set status = 'revoked', credential_hash = '', expires_at = null
    where owner_id = account_id and device_id = target;
  return true;
end $$;

create function public.sync_recovery_claim_publish(claim_key text) returns boolean
language plpgsql security definer set search_path = '' as $$
declare owner uuid := auth.uid(); hash text; existing text;
begin
  if owner is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  hash := redent_private.sha256_hex(redent_private.base64_bytes(claim_key, 32));
  perform redent_private.lock_account(owner);
  insert into redent_private.sync_recovery_claims(account_id, claim_hash) values (owner, hash) on conflict do nothing;
  select claims.claim_hash into existing from redent_private.sync_recovery_claims claims
    where claims.account_id = owner;
  if existing <> hash then raise exception using errcode = '42501', message = 'recovery_claim_rejected'; end if;
  return true;
end $$;

create function public.sync_device_claim(request jsonb) returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  owner uuid := auth.uid();
  device redent_private.sync_devices%rowtype;
  target uuid;
  presented_credential text;
  presented_claim text;
  stored_claim text;
begin
  if owner is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  if request is null or jsonb_typeof(request) <> 'object'
     or request - array['device_id', 'credential', 'claim_key'] <> '{}'::jsonb then
    raise exception using errcode = '22023', message = 'invalid_request';
  end if;
  begin
    target := (request->>'device_id')::uuid;
  exception when invalid_text_representation then
    raise exception using errcode = '22023', message = 'invalid_request';
  end;
  presented_credential := redent_private.sha256_hex(redent_private.base64_bytes(request->>'credential', 32));
  presented_claim := redent_private.sha256_hex(redent_private.base64_bytes(request->>'claim_key', 32));
  perform redent_private.lock_account(owner);
  select claims.claim_hash into stored_claim from redent_private.sync_recovery_claims claims where claims.account_id = owner;
  select * into device from redent_private.sync_devices where owner_id = owner and device_id = target;
  if not found or device.credential_hash <> presented_credential then
    raise exception using errcode = '42501', message = 'device_rejected';
  end if;
  if device.status = 'approved' then return true; end if;
  if stored_claim is null or stored_claim <> presented_claim or device.status <> 'pending' or device.expires_at <= now() then
    raise exception using errcode = '42501', message = 'recovery_claim_rejected';
  end if;
  update redent_private.sync_devices set status = 'approved', expires_at = null
    where owner_id = owner and device_id = target;
  return true;
end $$;

create function redent_private.require_device(account_id uuid, request jsonb)
returns table(signer uuid, signature text)
language plpgsql set search_path = '' as $$
declare approved integer; device redent_private.sync_devices%rowtype; presented text;
begin
  select count(*) into approved from redent_private.sync_devices devices
    where devices.owner_id = account_id and devices.status = 'approved';
  if not (request ? 'device_id') and not (request ? 'device_credential') and not (request ? 'signature') then
    if approved > 0 then raise exception using errcode = '42501', message = 'device_authentication_required'; end if;
    return;
  end if;
  presented := request->>'device_credential';
  if presented !~ '^[0-9a-f]{64}$' then raise exception using errcode = '22023', message = 'invalid_request'; end if;
  perform redent_private.base64_bytes(request->>'signature', 64);
  begin
    select * into device from redent_private.sync_devices devices
      where devices.owner_id = account_id and devices.device_id = (request->>'device_id')::uuid;
  exception when invalid_text_representation then
    raise exception using errcode = '22023', message = 'invalid_request';
  end;
  if not found or device.status <> 'approved' or device.credential_hash <> presented then
    raise exception using errcode = '42501', message = 'device_rejected';
  end if;
  signer := device.device_id;
  signature := request->>'signature';
  return next;
end $$;

create or replace function public.sync_push(request jsonb) returns jsonb
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
  normalized jsonb;
  signer_id uuid;
  signature_text text;
  device_keys boolean;
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
  device_keys := request ? 'device_id' or request ? 'device_credential' or request ? 'signature';
  if incoming_mutation_id is null or target_id is null or expected is null or expected < 0 or tombstone is null
    or target_collection is null or target_collection !~ '^[a-z0-9_]{1,32}$'
    or encrypted_payload is null or jsonb_typeof(request->'encrypted_payload') <> 'string'
    or length(encrypted_payload) < 40 or length(encrypted_payload) > 262144
    or encrypted_payload !~ '^[A-Za-z0-9+/]+={0,2}$'
    or (device_keys and (request->>'device_id' is null or request->>'device_credential' is null or request->>'signature' is null))
    or request - array['mutation_id', 'collection', 'record_id', 'expected_revision', 'encrypted_payload', 'deleted',
      'device_id', 'device_credential', 'signature'] <> '{}'::jsonb then
    raise exception using errcode = '22023', message = 'invalid_request';
  end if;
  normalized := request;
  if normalized ? 'device_credential' then
    normalized := jsonb_set(normalized, '{device_credential}', to_jsonb(redent_private.sha256_hex(
      redent_private.base64_bytes(normalized->>'device_credential', 32))));
  end if;
  perform redent_private.lock_account(account_id);
  select proof.signer, proof.signature into signer_id, signature_text
    from redent_private.require_device(account_id, normalized) proof;
  select * into prior from redent_private.sync_mutations mutations
    where mutations.owner_id = account_id and mutations.mutation_id = incoming_mutation_id;
  if found then
    if prior.request <> normalized then raise exception using errcode = '22023', message = 'mutation_payload_mismatch'; end if;
    return prior.result;
  end if;
  select records.revision into current_revision from public.sync_records records
    where records.owner_id = account_id and records.collection = target_collection and records.record_id = target_id;
  current_revision := coalesce(current_revision, 0);
  if current_revision <> expected then
    return jsonb_build_object('status', 'conflict', 'revision', current_revision);
  end if;
  if (select accounts.cursor from redent_private.sync_accounts accounts where accounts.owner_id = account_id) >= 10000 then
    raise exception using errcode = '54000', message = 'foundation_quota_reached';
  end if;
  update redent_private.sync_accounts accounts set cursor = accounts.cursor + 1
    where accounts.owner_id = account_id returning accounts.cursor into next_cursor;
  insert into public.sync_records(owner_id, collection, record_id, revision, cursor, encrypted_payload, deleted)
    values(account_id, target_collection, target_id, current_revision + 1, next_cursor, encrypted_payload, tombstone)
    on conflict (owner_id, collection, record_id) do update set revision = excluded.revision, cursor = excluded.cursor,
      encrypted_payload = excluded.encrypted_payload, deleted = excluded.deleted;
  insert into public.sync_changes(mutation_id, expected_revision, owner_id, cursor, collection, record_id, revision,
    encrypted_payload, deleted, signer_device_id, signature)
    values(incoming_mutation_id, expected, account_id, next_cursor, target_collection, target_id, current_revision + 1,
      encrypted_payload, tombstone, signer_id, signature_text);
  result := (normalized - 'device_credential') || jsonb_build_object(
    'status', 'accepted', 'revision', current_revision + 1, 'cursor', next_cursor);
  insert into redent_private.sync_mutations values(account_id, incoming_mutation_id, normalized, result);
  return result;
end $$;

revoke all on function redent_private.sha256_hex(bytea) from public, anon, authenticated;
revoke all on function redent_private.base64_bytes(text, integer) from public, anon, authenticated;
revoke all on function redent_private.parse_device(jsonb, boolean) from public, anon, authenticated;
revoke all on function redent_private.lock_account(uuid) from public, anon, authenticated;
revoke all on function redent_private.require_device(uuid, jsonb) from public, anon, authenticated;
revoke all on function public.sync_device_bootstrap(jsonb) from public, anon;
revoke all on function public.sync_device_enroll(jsonb) from public, anon;
revoke all on function public.sync_device_list() from public, anon;
revoke all on function public.sync_device_approve(jsonb) from public, anon;
revoke all on function public.sync_device_envelope(uuid, text) from public, anon;
revoke all on function public.sync_device_revoke(jsonb) from public, anon;
revoke all on function public.sync_recovery_claim_publish(text) from public, anon;
revoke all on function public.sync_device_claim(jsonb) from public, anon;
grant execute on function public.sync_device_bootstrap(jsonb) to authenticated;
grant execute on function public.sync_device_enroll(jsonb) to authenticated;
grant execute on function public.sync_device_list() to authenticated;
grant execute on function public.sync_device_approve(jsonb) to authenticated;
grant execute on function public.sync_device_envelope(uuid, text) to authenticated;
grant execute on function public.sync_device_revoke(jsonb) to authenticated;
grant execute on function public.sync_recovery_claim_publish(text) to authenticated;
grant execute on function public.sync_device_claim(jsonb) to authenticated;
