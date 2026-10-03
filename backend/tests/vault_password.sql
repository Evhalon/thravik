\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values
 ('40000000-0000-0000-0000-000000000001'),
 ('40000000-0000-0000-0000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000001', true);
do $$
declare
 envelope jsonb := jsonb_build_object('protocolVersion', 1, 'kdf', 'pbkdf2-hmac-sha256', 'iterations', 600000,
 'salt', encode(decode(repeat('00',32),'hex'),'base64'),
 'nonce', encode(decode(repeat('00',12),'hex'),'base64'),
 'ciphertext', replace(encode(decode(repeat('00',73),'hex'),'base64'), E'\n', ''),
 'authenticationTag', encode(decode(repeat('00',16),'hex'),'base64'));
 recovery jsonb := jsonb_build_object('protocolVersion', 1,
 'nonce', encode(decode(repeat('00',12),'hex'),'base64'),
 'ciphertext', encode(decode(repeat('00',32),'hex'),'base64'),
 'authenticationTag', encode(decode(repeat('00',16),'hex'),'base64'));
 replaced jsonb;
 claim text := encode(decode(repeat('01',32),'hex'),'base64');
begin
 if public.vault_password_get() is not null then raise exception 'unexpected envelope'; end if;
 begin
  perform public.vault_password_create(envelope);
  raise exception 'creation without recovery accepted';
 exception when invalid_parameter_value then null;
 end;
 perform public.vault_recovery_create(recovery);
 if not public.vault_password_create(envelope) then raise exception 'creation rejected'; end if;
 if not public.vault_password_create(envelope) then raise exception 'retry rejected'; end if;
 replaced := jsonb_set(envelope, '{nonce}', to_jsonb(encode(decode(repeat('01',12),'hex'),'base64')));
 if public.vault_password_create(replaced) then raise exception 'replacement without proof accepted'; end if;
 if public.vault_password_get() <> envelope then raise exception 'envelope changed'; end if;
 begin
  perform public.vault_password_create(jsonb_set(envelope, '{iterations}', '1'));
  raise exception 'unsafe KDF accepted';
 exception when invalid_parameter_value then null;
 end;
 begin
  delete from public.vault_password_envelopes;
  raise exception 'direct writes permitted';
 exception when insufficient_privilege then null;
 end;
 perform public.sync_recovery_claim_publish(claim);
 begin
  perform public.vault_password_replace(replaced, envelope, encode(decode(repeat('02',32),'hex'),'base64'));
  raise exception 'wrong proof accepted';
 exception when insufficient_privilege then null;
 end;
 if not public.vault_password_replace(replaced, envelope, claim) then raise exception 'authorized replacement failed'; end if;
 if public.vault_password_replace(envelope, envelope, claim) then raise exception 'stale replacement accepted'; end if;
 if public.vault_password_get() <> replaced then raise exception 'new envelope missing'; end if;
end;
$$;
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000002', true);
do $$ begin
 if public.vault_password_get() is not null then raise exception 'cross account leak'; end if;
end; $$;
rollback;
