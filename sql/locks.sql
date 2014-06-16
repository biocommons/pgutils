CREATE or replace VIEW pgutils.locks AS SELECT l.pid, d.datname as "database", n.nspname as "schema", c.relname as "relation", l.locktype,
    l."mode", CASE l."granted" WHEN true THEN 'RUN'::text ELSE
    'WAIT'::text END AS state, a.usename, a.current_query, to_char((now()
    - a.query_start), 'HH24:MI:SS'::text) AS duration FROM (((pg_locks l
    JOIN pg_database d ON ((l."database" = d.oid))) JOIN pg_class c ON
    ((l.relation = c.oid))) JOIN pg_namespace n on c.relnamespace=n.oid JOIN pg_stat_activity a ON ((l.pid =
    a.procpid))) ORDER BY l.pid, d.datname, n.nspname, c.relname, l."granted";


COMMENT ON VIEW pgutils.locks IS 'granted and pending locks on all relations';

