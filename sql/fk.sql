set search_path = pgutils;

drop view foreign_keys cascade;

CREATE VIEW foreign_keys AS
    SELECT fkn.nspname AS fk_namespace, fkr.relname AS fk_relation,
    fka.attname AS fk_column, fka.attnotnull as
    fk_notnull, (EXISTS (SELECT pg_index.indexrelid,
    pg_index.indrelid, pg_index.indkey, pg_index.indclass,
    pg_index.indnatts, pg_index.indisunique, pg_index.indisprimary,
    pg_index.indisclustered, pg_index.indexprs, pg_index.indpred FROM
    pg_index WHERE ((pg_index.indrelid = fkr.oid) AND (pg_index.indkey[0]
    = fka.attnum)))) AS fk_indexed, pkn.nspname AS pk_namespace,
    pkr.relname AS pk_relation, pka.attname AS pk_column, (EXISTS (SELECT
    pg_index.indexrelid, pg_index.indrelid, pg_index.indkey,
    pg_index.indclass, pg_index.indnatts, pg_index.indisunique,
    pg_index.indisprimary, pg_index.indisclustered, pg_index.indexprs,
    pg_index.indpred FROM pg_index WHERE ((pg_index.indrelid = pkr.oid)
    AND (pg_index.indkey[0] = pka.attnum)))) AS pk_indexed,
    ((c.confupdtype)::text || (c.confdeltype)::text) AS ud, cn.nspname AS
    c_namespace, c.conname AS c_name FROM (((((((pg_constraint c JOIN
    pg_namespace cn ON ((cn.oid = c.connamespace))) JOIN pg_class fkr ON
    ((fkr.oid = c.conrelid))) JOIN pg_namespace fkn ON ((fkn.oid =
    fkr.relnamespace))) JOIN pg_attribute fka ON (((fka.attrelid =
    c.conrelid) AND (fka.attnum = ANY (c.conkey))))) JOIN pg_class pkr ON
    ((pkr.oid = c.confrelid))) JOIN pg_namespace pkn ON ((pkn.oid =
    pkr.relnamespace))) JOIN pg_attribute pka ON (((pka.attrelid =
    c.confrelid) AND (pka.attnum = ANY (c.confkey))))) WHERE (c.contype =
    'f'::"char");


CREATE VIEW foreign_keys_missing_indexes AS
    SELECT * FROM foreign_keys WHERE
    ((foreign_keys.ud ~ '[^a]'::text) AND (NOT foreign_keys.fk_indexed))
    ORDER BY foreign_keys.pk_relation, foreign_keys.pk_column,
    foreign_keys.fk_relation, foreign_keys.fk_column;

CREATE VIEW foreign_keys_pp AS SELECT 
    ((((((foreign_keys.fk_namespace)::text || '.'::text) ||
    (foreign_keys.fk_relation)::text) || '('::text) ||
    (foreign_keys.fk_column)::text) || ')'::text) AS fk,

    ((((((foreign_keys.pk_namespace)::text || '.'::text) ||
    (foreign_keys.pk_relation)::text) || '('::text) ||
    (foreign_keys.pk_column)::text) || ')'::text) AS pk,

    ((((((foreign_keys.c_namespace)::text || '.'::text) ||
    (foreign_keys.c_name)::text) || '('::text) || foreign_keys.ud) ||
    ')'::text) AS "constraint", 

	foreign_keys.fk_indexed,
	foreign_keys.fk_notnull,
	foreign_keys.pk_indexed

 FROM foreign_keys
ORDER by 1;








COMMENT ON VIEW foreign_keys IS 'PK-FK constraints, including indexes and cascade traits';
COMMENT ON VIEW foreign_keys_missing_indexes IS 'foreign keys with cascading constrains that do not have indexes';
COMMENT ON VIEW foreign_keys_pp IS 'PK-FK constraints; see also foreign_keys';
