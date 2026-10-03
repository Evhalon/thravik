\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values
 ('40000000-0000-0000-0000-000000000001'),
 ('40000000-0000-0000-0000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000001', true);
do $$
declare
  raw_credential text := encode(decode(repeat('33', 32), 'hex'), 'base64');
  second_credential text := encode(decode(repeat('66', 32), 'hex'), 'base64');
  device jsonb := jsonb_build_object(
    'device_id', '41000000-0000-0000-0000-000000000001',
    'agreement_public_key', encode(decode(repeat('11', 32), 'hex'), 'base64'),
    'signing_public_key', encode(decode(repeat('22', 32), 'hex'), 'base64'),
    'credential', raw_credential);
  second jsonb := jsonb_build_object(
    'device_id', '41000000-0000-0000-0000-000000000002',
    'agreement_public_key', encode(decode(repeat('44', 32), 'hex'), 'base64'),
    'signing_public_key', encode(decode(repeat('55', 32), 'hex'), 'base64'),
    'credential', second_credential,
    'expires_at', floor(extract(epoch from now()))::bigint + 600);
  signature text := replace(encode(decode(repeat('77', 64), 'hex'), 'base64'), E'\n', '');
  claim text := encode(decode(repeat('88', 32), 'hex'), 'base64');
  push jsonb;
  result jsonb;
begin
  if not public.sync_device_bootstrap(device) then raise exception 'bootstrap failed'; end if;
  if not public.sync_device_bootstrap(device) then raise exception 'bootstrap retry failed'; end if;
  if jsonb_array_length(public.sync_device_list()) <> 1 then raise exception 'device list failed'; end if;
  begin
    perform public.sync_device_bootstrap(second - 'expires_at');
    raise exception 'second bootstrap accepted';
  exception when insufficient_privilege then
    if sqlerrm <> 'device_already_registered' then raise; end if;
  end;
  if not public.sync_device_enroll(second) then raise exception 'enroll failed'; end if;
  push := jsonb_build_object(
    'mutation_id', '42000000-0000-0000-0000-000000000001', 'collection', 'credentials',
    'record_id', '43000000-0000-0000-0000-000000000001', 'expected_revision', 0, 'deleted', false,
    'encrypted_payload', encode(decode(repeat('99', 40), 'hex'), 'base64'));
  begin
    perform public.sync_push(push);
    raise exception 'unsigned push accepted';
  exception when insufficient_privilege then
    if sqlerrm <> 'device_authentication_required' then raise; end if;
  end;
  result := public.sync_push(push || jsonb_build_object(
    'device_id', '41000000-0000-0000-0000-000000000001', 'device_credential', raw_credential, 'signature', signature));
  if result->>'status' <> 'accepted' or result ? 'device_credential' then raise exception 'signed push failed'; end if;
  if not public.sync_recovery_claim_publish(claim) or not public.sync_recovery_claim_publish(claim) then
    raise exception 'claim publish failed';
  end if;
  begin
    perform public.sync_recovery_claim_publish(encode(decode(repeat('01', 32), 'hex'), 'base64'));
    raise exception 'claim replacement accepted';
  exception when insufficient_privilege then
    if sqlerrm <> 'recovery_claim_rejected' then raise; end if;
  end;
  if not public.sync_device_claim(jsonb_build_object(
    'device_id', '41000000-0000-0000-0000-000000000002', 'credential', second_credential, 'claim_key', claim)) then
    raise exception 'claim failed';
  end if;
  if not public.sync_device_revoke(jsonb_build_object(
    'device_id', '41000000-0000-0000-0000-000000000001',
    'approver_device_id', '41000000-0000-0000-0000-000000000002',
    'approver_credential', second_credential)) then raise exception 'revoke failed'; end if;
  begin
    perform public.sync_device_revoke(jsonb_build_object(
      'device_id', '41000000-0000-0000-0000-000000000002',
      'approver_device_id', '41000000-0000-0000-0000-000000000002',
      'approver_credential', second_credential));
    raise exception 'last device revoked';
  exception when insufficient_privilege then
    if sqlerrm <> 'device_rejected' then raise; end if;
  end;
end;
$$;
reset role;
do $$ begin
  if (select request::text from redent_private.sync_mutations) like '%' || encode(decode(repeat('33', 32), 'hex'), 'base64') || '%' then
    raise exception 'raw credential stored';
  end if;
  if (select signer_device_id::text from public.sync_changes) <> '41000000-0000-0000-0000-000000000001' then
    raise exception 'signer missing';
  end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub', '40000000-0000-0000-0000-000000000002', true);
do $$ begin
  if jsonb_array_length(public.sync_device_list()) <> 0 then raise exception 'cross-account devices visible'; end if;
end; $$;
reset role;
set local role anon;
do $$ begin
  begin
    perform public.sync_device_list();
    raise exception 'anonymous device list allowed';
  exception when insufficient_privilege then null;
  end;
end; $$;
rollback;
