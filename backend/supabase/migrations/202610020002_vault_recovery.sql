create table public.vault_recovery_envelopes (
  account_id uuid primary key references auth.users(id) on delete cascade,
  envelope jsonb not null,
  created_at timestamptz not null default now()
);
alter table public.vault_recovery_envelopes enable row level security;
revoke all on public.vault_recovery_envelopes from anon, authenticated;

create function public.vault_recovery_get() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if auth.uid() is null then raise insufficient_privilege; end if;
  select envelope into result from public.vault_recovery_envelopes where account_id = auth.uid();
  return result;
end;
$$;

create function public.vault_recovery_create(envelope jsonb) returns boolean
language plpgsql security definer set search_path = '' as $$
declare existing jsonb;
begin
  if auth.uid() is null then raise insufficient_privilege; end if;
  if envelope is null or jsonb_typeof(envelope) <> 'object'
    or envelope->>'protocolVersion' is distinct from '1'
    or length(envelope->>'nonce') is distinct from 16
    or length(envelope->>'ciphertext') is distinct from 44
    or length(envelope->>'authenticationTag') is distinct from 24 then
    raise invalid_parameter_value using message = 'invalid_recovery_envelope';
  end if;
  if octet_length(decode(envelope->>'nonce', 'base64')) <> 12
    or octet_length(decode(envelope->>'ciphertext', 'base64')) <> 32
    or octet_length(decode(envelope->>'authenticationTag', 'base64')) <> 16 then
    raise invalid_parameter_value using message = 'invalid_recovery_envelope';
  end if;
  insert into public.vault_recovery_envelopes(account_id, envelope)
    values (auth.uid(), envelope) on conflict (account_id) do nothing;
  select stored.envelope into existing from public.vault_recovery_envelopes stored where account_id = auth.uid();
  return existing = envelope;
end;
$$;
revoke all on function public.vault_recovery_get() from public, anon;
revoke all on function public.vault_recovery_create(jsonb) from public, anon;
grant execute on function public.vault_recovery_get() to authenticated;
grant execute on function public.vault_recovery_create(jsonb) to authenticated;
