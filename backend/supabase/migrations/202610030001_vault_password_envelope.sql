create table public.vault_password_envelopes (
  account_id uuid primary key references auth.users(id) on delete cascade,
  envelope jsonb not null,
  created_at timestamptz not null default now()
);
alter table public.vault_password_envelopes enable row level security;
revoke all on public.vault_password_envelopes from anon, authenticated;

create function public.vault_password_get() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if auth.uid() is null then raise insufficient_privilege; end if;
  select envelope into result from public.vault_password_envelopes where account_id = auth.uid();
  return result;
end;
$$;

create function public.vault_password_create(envelope jsonb) returns boolean
language plpgsql security definer set search_path = '' as $$
declare existing jsonb;
begin
  if auth.uid() is null then raise insufficient_privilege; end if;
  if envelope is null or jsonb_typeof(envelope) <> 'object' then
    raise invalid_parameter_value using message = 'invalid_password_envelope';
  end if;
  if (select count(*) from jsonb_object_keys(envelope)) <> 7
    or envelope->>'protocolVersion' is distinct from '1'
    or envelope->>'kdf' is distinct from 'pbkdf2-hmac-sha256'
    or envelope->>'iterations' is distinct from '600000'
    or length(envelope->>'salt') is distinct from 44
    or length(envelope->>'nonce') is distinct from 16
    or length(envelope->>'ciphertext') is distinct from 100
    or length(envelope->>'authenticationTag') is distinct from 24 then
    raise invalid_parameter_value using message = 'invalid_password_envelope';
  end if;
  if not exists(select 1 from public.vault_recovery_envelopes where account_id = auth.uid()) then
    raise invalid_parameter_value using message = 'recovery_required';
  end if;
  if octet_length(decode(envelope->>'salt', 'base64')) <> 32
    or octet_length(decode(envelope->>'nonce', 'base64')) <> 12
    or octet_length(decode(envelope->>'ciphertext', 'base64')) <> 73
    or octet_length(decode(envelope->>'authenticationTag', 'base64')) <> 16 then
    raise invalid_parameter_value using message = 'invalid_password_envelope';
  end if;
  insert into public.vault_password_envelopes(account_id, envelope)
    values (auth.uid(), envelope) on conflict (account_id) do nothing;
  select stored.envelope into existing from public.vault_password_envelopes stored where account_id = auth.uid();
  return existing = envelope;
end;
$$;
revoke all on function public.vault_password_get() from public, anon;
revoke all on function public.vault_password_create(jsonb) from public, anon;
grant execute on function public.vault_password_get() to authenticated;
grant execute on function public.vault_password_create(jsonb) to authenticated;

create function public.vault_password_replace(envelope jsonb, expected jsonb, claim_key text) returns boolean
language plpgsql security definer set search_path = '' as $$
declare owner uuid := auth.uid(); stored_claim text; presented_claim text; changed integer;
begin
  if owner is null then raise insufficient_privilege; end if;
  presented_claim := redent_private.sha256_hex(redent_private.base64_bytes(claim_key, 32));
  select claims.claim_hash into stored_claim from redent_private.sync_recovery_claims claims
    where claims.account_id = owner;
  if stored_claim is null or stored_claim <> presented_claim then raise insufficient_privilege; end if;
  if not exists(select 1 from public.vault_password_envelopes stored
    where stored.account_id = owner and stored.envelope = expected) then return false; end if;
  perform public.vault_password_create(envelope);
  update public.vault_password_envelopes stored set envelope = vault_password_replace.envelope
    where stored.account_id = owner and stored.envelope = expected;
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;
revoke all on function public.vault_password_replace(jsonb, jsonb, text) from public, anon;
grant execute on function public.vault_password_replace(jsonb, jsonb, text) to authenticated;
