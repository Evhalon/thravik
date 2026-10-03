\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values
 ('30000000-0000-0000-0000-000000000001'),
 ('30000000-0000-0000-0000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000001', true);
do $$
declare
 envelope jsonb := jsonb_build_object('protocolVersion', 1,
 'nonce', encode(decode(repeat('00',12),'hex'),'base64'),
 'ciphertext', encode(decode(repeat('00',32),'hex'),'base64'),
 'authenticationTag', encode(decode(repeat('00',16),'hex'),'base64'));
begin
 if public.vault_recovery_get() is not null then raise exception 'unexpected vault'; end if;
 if not public.vault_recovery_create(envelope) then raise exception 'creation rejected'; end if;
 if not public.vault_recovery_create(envelope) then raise exception 'retry rejected'; end if;
 if public.vault_recovery_create(jsonb_set(envelope,'{nonce}',to_jsonb(encode(decode(repeat('01',12),'hex'),'base64')))) then
   raise exception 'replacement accepted';
 end if;
 if public.vault_recovery_get() <> envelope then raise exception 'root replaced'; end if;
 begin
  delete from public.vault_recovery_envelopes;
  raise exception 'direct writes permitted';
 exception when insufficient_privilege then null;
 end;
end;
$$;
select set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000002', true);
do $$ begin
 if public.vault_recovery_get() is not null then raise exception 'cross account leak'; end if;
end; $$;
rollback;
