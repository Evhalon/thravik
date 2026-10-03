\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values
 ('00000000-0000-0000-0000-000000000001'),
 ('00000000-0000-0000-0000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
do $$
declare
  request jsonb := '{"mutation_id":"10000000-0000-0000-0000-000000000001","collection":"spaces","record_id":"20000000-0000-0000-0000-000000000001","expected_revision":0,"deleted":false,"encrypted_payload":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}';
  result jsonb;
begin
  result := public.sync_push(request);
  if result->>'status' <> 'accepted' or result->>'revision' <> '1' or result->>'cursor' <> '1' then raise exception 'initial write failed'; end if;
  if public.sync_push(request) <> result then raise exception 'retry changed result'; end if;
  if (select count(*) from public.sync_pull()) <> 1 then raise exception 'duplicate feed entry'; end if;
  begin
    perform public.sync_push(jsonb_set(request, '{deleted}', 'true'));
    raise exception 'mismatched retry accepted';
  exception when invalid_parameter_value then null;
  end;
  request := jsonb_set(request, '{mutation_id}', '"10000000-0000-0000-0000-000000000002"');
  if public.sync_push(request)->>'status' <> 'conflict' then raise exception 'CAS failed'; end if;
  request := jsonb_set(request, '{expected_revision}', '1');
  request := jsonb_set(request, '{deleted}', 'true');
  result := public.sync_push(request);
  if result->>'cursor' <> '2' or result->>'revision' <> '2' then raise exception 'cursor/revision failed'; end if;
  if not (select deleted from public.sync_pull(1, 1)) then raise exception 'tombstone missing'; end if;
  if (select count(*) from public.sync_pull(0, 1)) <> 1 then raise exception 'page bound failed'; end if;
  request := jsonb_set(request, '{mutation_id}', '"10000000-0000-0000-0000-000000000003"');
  request := jsonb_set(request, '{collection}', '"bookmarks"');
  if public.sync_push(request)->>'status' <> 'conflict' then raise exception 'nonzero create accepted'; end if;
  request := jsonb_set(request, '{expected_revision}', '0');
  if public.sync_push(request)->>'revision' <> '1' then raise exception 'collections share revisions'; end if;

  begin
    delete from public.sync_records;
    raise exception 'direct writes allowed';
  exception when insufficient_privilege then null;
  end;
end;
$$;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
do $$
begin
  if (select count(*) from public.sync_records) <> 0 then raise exception 'cross-account records visible'; end if;
  if (select count(*) from public.sync_changes) <> 0 then raise exception 'cross-account changes visible'; end if;
  if (select count(*) from public.sync_pull()) <> 0 then raise exception 'cross-account pull visible'; end if;
  if public.sync_push('{"mutation_id":"10000000-0000-0000-0000-000000000001","collection":"spaces","record_id":"20000000-0000-0000-0000-000000000001","expected_revision":0,"deleted":false,"encrypted_payload":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}')->>'cursor' <> '1' then
    raise exception 'account cursor/dedup not isolated';
  end if;
end;
$$;
reset role;
set local role anon;
do $$
begin
  begin
    perform public.sync_pull();
    raise exception 'anonymous RPC allowed';
  exception when insufficient_privilege then null;
  end;
end;
$$;
rollback;
