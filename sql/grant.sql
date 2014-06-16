create or replace function generate_grants(s text) returns setof text language sql as
$_$
  select concat('grant usage on schema "',$1,'" to PUBLIC;') as "cmd"
union
  select concat('grant select on "',schemaname,'"."',tablename,'" to PUBLIC;')
  from pg_tables
  where schemaname=$1
union
  select concat('grant select on "',schemaname,'"."',viewname,'" to PUBLIC;')
  from pg_views
  where schemaname=$1
union
  select concat('grant execute on function ',P.oid::regprocedure,' to PUBLIC;')
  from pg_proc P
  join pg_namespace NS on P.pronamespace=NS.oid
  where nspname=$1;
$_$;


CREATE OR REPLACE FUNCTION grant_readonly_to_public(schema TEXT) RETURNS void
AS $_$
DECLARE
  r RECORD;
  n_rows int;
BEGIN
  FOR r IN SELECT generate_grants::text as cmd FROM generate_grants(schema) LOOP
	RAISE NOTICE '%...',r.cmd;
    EXECUTE r.cmd;
  END LOOP;
END;
$_$
LANGUAGE plpgsql;

