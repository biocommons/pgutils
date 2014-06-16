drop view pgtools.schema_sizes;
drop view pgtools.table_sizes;
drop view pgtools.database_sizes;



CREATE OR REPLACE VIEW pgtools.database_sizes AS
SELECT x.size_mb, x.datname
FROM ( 
	SELECT 1 AS _order, round(   (pg_database_size(datname) / 1000000.0),2) AS size_mb, datname
	  FROM pg_database
  UNION
	SELECT 2 AS _order, round(sum(pg_database_size(datname) / 1000000.0),2) AS size_mb, 'TOTAL' as datname
	  FROM pg_database
) x
  ORDER BY x._order, x.datname;


CREATE OR REPLACE VIEW pgtools.table_sizes AS
  SELECT round((pg_relation_size((s.nspname || '.') || c.relname) / 1000000.0 ), 2) AS size_mb, s.nspowner, 
	     so.usename AS nspowner_name, s.nspname, c.relowner, co.usename AS relowner_name, c.relname
   FROM pg_namespace s
   JOIN pg_class c ON s.oid = c.relnamespace
   JOIN pg_user so ON s.nspowner = so.usesysid
   JOIN pg_user co ON c.relowner = co.usesysid
  WHERE relkind = 'r'
  ORDER BY s.nspname, relkind, c.relname;

CREATE OR REPLACE view pgtools.schema_sizes AS
 SELECT table_sizes.nspname, table_sizes.nspowner_name, sum(table_sizes.size_mb) AS size_mb
   FROM pgtools.table_sizes
  GROUP BY table_sizes.nspname, table_sizes.nspowner_name
  ORDER BY table_sizes.nspname;

COMMENT ON VIEW pgtools.database_sizes IS 'all databases and sizes [in SI MB (10^6 bytes)]';
COMMENT ON VIEW pgtools.table_sizes IS 'all tables and sizes [in SI MB (10^6 bytes)]';
COMMENT ON VIEW pgtools.schema_sizes IS 'all schemas and sizes [in SI MB (10^6 bytes)]';

grant select on pgtools.database_sizes,pgtools.table_sizes,pgtools.schema_sizes to public;
